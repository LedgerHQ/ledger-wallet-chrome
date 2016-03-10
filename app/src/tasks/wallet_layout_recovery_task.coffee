$log = -> ledger.utils.Logger.getLoggerByTag("WalletLayoutRecoveryTask")
$info = (args...) -> $log().info args...
$error = (args...) -> $log().error args...

class ledger.tasks.WalletLayoutRecoveryTask extends ledger.tasks.Task

  BatchSize: 20

  constructor: -> super 'recovery-global-instance'

  @instance: new @()

  getLastSynchronizationStatus: () -> @_loadSynchronizationData().then (state) -> state['lastSyncStatus']
  getLastSynchronizationDate: () -> @_loadSynchronizationData().then (state) -> new Date(state['lastSyncTime'])

  onStart: () ->
    unconfirmedTxs = @_findUnconfirmedTransaction()
    @_performRecovery(unconfirmedTxs).then (transactionsNotFound) =>
      l "Recovery completed"
      @_discardTransactions(transactionsNotFound)
      @emit 'done'
    .fail (er) =>
      e "Serious error during synchro", er
      ledger.app.emit "wallet:operations:sync:failed"
      @emit 'fatal_error'
    .fin =>
      # Delete sync token and stop
      ledger.api.BlockRestClient.instance.refreshLastBlock()
      @_deleteSynchronizationToken(@_syncToken) if @_syncToken?
      @_syncToken = null
      @stopIfNeccessary()

  _performRecovery: (unconfirmedTransactions) ->
    syncToken = null
    savedState = {}
    @_loadSynchronizationData().then (data) =>
      savedState = data
      @_requestSynchronizationToken()
    .then (token) =>
      @_syncToken = token
      syncToken = token
      hdWallet = ledger.wallet.Wallet.instance
      iterate = (index) =>
        d = ledger.defer()
        l "Register xpub ", "#{hdWallet.getRootDerivationPath()}/#{index}'"
        account = hdWallet.getOrCreateAccount(index)
        ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath account.getRootDerivationPath(), ->
          d.resolve()
        d.promise.then =>
          @_recoverAccount(index, savedState, syncToken)
        .then ([isEmpty, txs]) =>
          unconfirmedTransactions = _(unconfirmedTransactions).filter (tx) ->
            !_(txs).some((hash) -> tx.get('hash') is hash)
          unless isEmpty
            iterate(index + 1)
      iterate(0)
    .fail (er) =>
      # Handle reorgs
      e "Failure during synchro", er
      if er?.getStatusCode?() is 404
        @_handleReorgs(savedState, er.block).then () =>
          @_performRecovery()
      else
        # Mark failure and save
        savedState['lastSyncStatus'] = 'failure'
        @_saveSynchronizationData(savedState)
        throw er
    .then =>
      savedState['lastSyncStatus'] = 'success'
      savedState['lastSyncTime'] = new Date().getTime()
      @_saveSynchronizationData(savedState)
    .then =>
      unconfirmedTransactions

  _recoverAccount: (accountIndex, savedState, syncToken) ->
    savedAccountState = savedState["account_#{accountIndex}"] or {}
    batches = savedAccountState["batches"] or []
    l "Recover account #{accountIndex}"
    fetchTxs = []
    iterate = (index) =>
      batch = batches[index]
      unless batch?
        batch =
          index: index
          blockHash: null
        batches.push batch
      l "Recover batch #{index}"
      @_recoverBatch(batch, accountIndex, syncToken).then ({hasNext, block, transactions}) ->
        fetchTxs = fetchTxs.concat(transactions)
        if block? and (!batch['blockHeight']? or block.height > batch['blockHeight'])
          batch['blockHash'] = block.hash
          batch['blockHeight'] = block.height
        if !block? and !batch['blockHash']?
          batches.splice(-1, 1)
        if hasNext
          iterate(index)
        else if !hasNext and batch['blockHash']?
          iterate(index + 1)

    iterate(0).then () =>
      d = ledger.defer()
      l "Account #{accountIndex} restored!"
      callback = =>
        l "Saving account #{accountIndex} state"
        savedAccountState["batches"] = batches
        savedState["account_#{accountIndex}"] = savedAccountState
        @_saveSynchronizationData(savedState).then =>
          l "Saved account #{accountIndex} state"
          d.resolve([batches.length == 0, fetchTxs])
      ledger.tasks.TransactionConsumerTask.instance.pushCallback(callback)
      d.promise

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
      if _.isEmpty(data)
        @_removeOldTransactions().then ->
          data
      else
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
    d = ledger.defer()
    op.delete() for op in Operation.all()
    d.resolve()
    d.promise

  _findUnconfirmedTransaction: ->
    Transaction.find({block_id: undefined}).data()

  _discardTransactions: (transactions) ->
    for transaction in transactions
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

  @reset: () ->
    @instance = new @
