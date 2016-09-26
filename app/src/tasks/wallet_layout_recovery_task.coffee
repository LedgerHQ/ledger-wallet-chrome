$log = -> ledger.utils.Logger.getLoggerByTag("WalletLayoutRecoveryTask")
$info = (args...) -> $log().info args...
$error = (args...) -> $log().error args...

class ledger.tasks.WalletLayoutRecoveryTask extends ledger.tasks.Task

  BatchSize: 50
  NumberOfRetry: 1

  constructor: -> super 'recovery-global-instance'

  @instance: new @()

  getLastSynchronizationStatus: () -> @_loadSynchronizationData().then (state) -> state['lastSyncStatus']
  getLastSynchronizationDate: () -> @_loadSynchronizationData().then (state) -> new Date(state['lastSyncTime'])

  onStart: () ->
    unconfirmedTxs = @_findUnconfirmedTransaction()
    startDate = new Date()
    $info "Start synchronization", startDate.toString()
    $info "Looking for mempool tx", _(unconfirmedTxs).map((tx) -> tx.get('hash'))
    @_performRecovery(unconfirmedTxs)
    .then (transactionsNotFound) =>
      $info "Recovery completed"
      $info "Unable to find these transactions", _(transactionsNotFound).map((tx) -> tx.get('hash'))
      @_discardTransactions(transactionsNotFound)
      ledger.app.emit 'wallet:operations:sync:done'
      @emit 'done'
    .fail (er) =>
      $error "Synchronization failed", er
      ledger.app.emit "wallet:operations:sync:failed"
      @emit 'fatal_error'
    .fin =>
      # Delete sync token and stop
      @_deleteSynchronizationToken(@_syncToken) if @_syncToken?
      @_syncToken = null
      duration = moment.duration(new Date().getTime() - startDate.getTime())
      $info "Stop synchronization. Synchronization took #{duration.get("minutes")}:#{duration.get("seconds")}:#{duration.get("milliseconds")}"
      @stopIfNeccessary()

  _performRecovery: (unconfirmedTransactions, retryCount = 0) ->
    savedState = {}
    persistState = no
    lastBlock = undefined
    @_loadSynchronizationData().then (data) =>
      savedState = @_migrateSavedState(data)
      persistState = yes
      ledger.api.BlockRestClient.instance.refreshLastBlock()
    .then (block) =>
      lastBlock = block
      @_requestSynchronizationToken()
    .then (token) =>
      @_syncToken = token
      @_recoverAccounts(unconfirmedTransactions, savedState, token)
    .fail (er) =>
      # Handle reorgs
      e "Failure during synchro", er
      if er?.getStatusCode?() is 404
        @_handleReorgs(savedState, er.block).then () =>
          @_performRecovery(unconfirmedTransactions)
      else if retryCount < @NumberOfRetry
        d = ledger.defer()
        _.delay((=> d.resolve(@_performRecovery(unconfirmedTransactions, retryCount + 1))), 1000)
        d.promise
      else
        # Mark failure and save
        savedState['lastSyncStatus'] = 'failure'
        d = ledger.defer()
        if persistState
          @_saveSynchronizationData(savedState).then -> d.reject(er)
        else
          d.reject(er)
        d.promise
    .then (unconfirmed) =>
      unconfirmedTransactions = unconfirmed
      savedState['lastSyncStatus'] = 'success'
      savedState['lastSyncTime'] = new Date().getTime()
      @_saveSynchronizationData(savedState) if persistState
    .then =>
      unconfirmedTransactions

  _numberOfAccountInState: (savedState) ->
    accountIndex = 0
    while savedState["account_#{accountIndex}"]?
      accountIndex += 1
    accountIndex

  _recoverAccounts: (unconfirmedTransactions, savedState, syncToken) ->
    hdWallet = ledger.wallet.Wallet.instance
    accountsCount = @_numberOfAccountInState(savedState)
    recover = (fromIndex, toIndex = 0) =>
      promises = []
      accountIndex = fromIndex
      while savedState["account_#{accountIndex}"]? or accountIndex <= toIndex
        account = hdWallet.getOrCreateAccount(accountIndex)
        do (account) =>
          d = ledger.defer()
          ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath account.getRootDerivationPath(), =>
            d.resolve(@_recoverAccount(account, savedState, syncToken))
          promises.push d.promise
        accountIndex += 1
      Q.all(promises)

    recoverUntilEmpty = (fromIndex = 0, toIndex = 0) =>
      recover(fromIndex, toIndex).then (results) =>
        containsEmpty = no
        for [isEmpty, txs] in results
          containsEmpty ||= isEmpty
          unconfirmedTransactions = _(unconfirmedTransactions).filter (tx) ->
            !_(txs).some((hash) -> tx.get('hash') is hash)
        unless containsEmpty
          accountsCount = @_numberOfAccountInState(savedState)
          recoverUntilEmpty(accountsCount, accountsCount)
        else
          unconfirmedTransactions
      .fail (er) =>
        throw er

    recoverUntilEmpty()

  _recoverAccount: (account, savedState, syncToken) ->
    $info "Recover account #{account.index}"
    savedAccountState = savedState["account_#{account.index}"] or {}
    savedState["account_#{account.index}"] = savedAccountState
    batches = savedAccountState["batches"] or []
    savedAccountState["batches"] = batches
    fetchTxs = []

    recover = (fromIndex, toIndex) =>
      promises = []
      for index in [fromIndex..toIndex]
        do (index) =>
          batch = batches[index]
          unless batch?
            batch =
              index: index
              blockHash: null
            batches.push batch
          $info "Recover batch #{batch.index} for account #{account.index}"
          recoverUntilEnd = () =>
            @_recoverBatch(batch, account.index, syncToken).then ({hasNext, block, transactions}) =>
              fetchTxs = fetchTxs.concat(transactions)
              if block? and (!batch['blockHeight']? or block.height > batch['blockHeight'])
                batch['blockHash'] = block.hash
                batch['blockHeight'] = block.height
              d = ledger.defer()
              l "Batch #{batch.index} for account #{account.index} has next", hasNext
              if hasNext
                ledger.tasks.TransactionConsumerTask.instance.pushCallback =>
                  d.resolve(recoverUntilEnd())
              else
                d.resolve()
              d.promise
          promises.push recoverUntilEnd()
      Q.all(promises)


    recoverUntilEmpty = (fromIndex = 0, toIndex = Math.max(batches.length - 1, 0)) =>
      recover(fromIndex, toIndex).then () =>
        if _(batches).last().blockHash?
          recoverUntilEmpty(batches.length, batches.length)
        else
          $info "Download txs ", fetchTxs
          [batches.length <= 1, fetchTxs]
      .fail (er) =>
        throw er
    recoverUntilEmpty()

  _recoverBatch: (batch, accountIndex, syncToken) ->
    wallet = ledger.wallet.Wallet.instance
    account = wallet.getOrCreateAccount(accountIndex)
    blockHash = batch['blockHash']
    from = batch.index * @BatchSize
    to = from + @BatchSize
    hasNext = no
    @_recoverAddresses(account.getRootDerivationPath(), from, to, blockHash, syncToken).then (result) =>
      d = ledger.defer()
      hasNext = result["truncated"]
      block = @_findHighestBlock(result.txs)
      transactions = _(result['txs']).map((tx) -> tx.hash)
      ledger.tasks.TransactionConsumerTask.instance.pushTransactions(result['txs'])
      ledger.tasks.TransactionConsumerTask.instance.pushCallback =>
        d.resolve({hasNext, block, transactions})
      d.promise
    .fail (er) ->
      er.block = batch
      throw er

  _recoverAddresses: (root, from, to, blockHash, syncToken) ->
    paths = _.map [from...to], (i) -> "#{root}/#{0}/#{i}"
    paths = paths.concat(_.map [from...to], (i) -> "#{root}/#{1}/#{i}")
    d = ledger.defer()
    l "Recovering ", paths
    callback = (response, error) =>
      return d.reject(error) if error?
      d.resolve(response)
    ledger.wallet.pathsToAddresses paths, (addresses) =>
      ledger.api.TransactionsRestClient.instance.getPaginatedTransactions(_.values(addresses), blockHash, syncToken, callback)
    d.promise

  _findHighestBlock: (txs) ->
    bestBlock = null
    for tx in txs
      if !bestBlock? or (tx.block?.height > bestBlock.height)
        bestBlock = tx.block
    bestBlock

  _requestSynchronizationToken: () ->
    d = ledger.defer()
    ledger.api.TransactionsRestClient.instance.getSyncToken (token, error) ->
      if (error?)
        d.reject(error)
      else
        d.resolve(token)
    d.promise

  _deleteSynchronizationToken: (token) ->
    d = ledger.defer()
    ledger.api.TransactionsRestClient.instance.deleteSyncToken token, ->
      d.resolve()
    d.promise

  _loadSynchronizationData: ->
    d = ledger.defer()
    ledger.storage.local.get 'ledger.tasks.WalletLayoutRecoveryTask', (data) =>
      l "Synchronization saved state ", data
      unless data['ledger.tasks.WalletLayoutRecoveryTask']?
        d.resolve({})
      else
        d.resolve(data['ledger.tasks.WalletLayoutRecoveryTask'])
    d.promise.then (data) =>
      data

  _saveSynchronizationData: (data) ->
    d = ledger.defer()
    l "Saving state", data
    save = {}
    save['ledger.tasks.WalletLayoutRecoveryTask'] = data
    ledger.storage.local.set save, =>
      d.resolve()
    d.promise

  _removeOldTransactions: ->
    $info "Removing old transactions"
    d = ledger.defer()
    op.delete() for op in Operation.all() when !op.get('block')?
    d.resolve()
    d.promise

  _findUnconfirmedTransaction: ->
    Transaction.find({block_id: undefined}).data()

  _discardTransactions: (transactions) ->
    for transaction in transactions when !transaction.get('block')?
      transaction.delete()

  _handleReorgs: (savedState, failedBlock) ->
    # Iterate through the state and delete any block higher or equal to failedBlock.height
    # Remove from the database all orphan transaction and blocks
    # Save the new state
    $info("Handle reorg for block #{failedBlock.blockHash} at #{failedBlock.blockHeight}")
    previousBlock = Block.find({height: {$lt: failedBlock.blockHeight}}).simpleSort("height", true).limit(1).data()[0]
    $info("Revert to block #{previousBlock.get('hash')} at #{previousBlock.get('height')}")
    idx = 0
    while savedState["account_#{idx}"]?
      for batch in savedState["account_#{idx}"]["batches"]
        if batch.blockHeight > previousBlock.get('height')
          batch.blockHeight = previousBlock.get('height')
          batch.blockHash = previousBlock.get('hash')
      idx += 1
    for block in Block.find({height: {$gte: failedBlock.blockHeight}}).data()
      block.delete()
    @_saveSynchronizationData(savedState)

  _migrateSavedState: (state = {}) ->
    oldBatchSize = state["batch_size"] or 20
    if (oldBatchSize != @BatchSize)
      idx = 0
      while state["account_#{idx}"]?
        oldBatches = state["account_#{idx}"]["batches"]
        batches = []
        total  = oldBatches.length * oldBatchSize
        state["account_#{idx}"] = batches: batches
        idx += 1
    state["batch_size"] = @BatchSize
    state

  @reset: () ->
    @instance = new @
