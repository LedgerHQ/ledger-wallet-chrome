class ledger.tasks.WalletLayoutRecoveryTask extends ledger.tasks.Task

  BatchSize: 20

  constructor: -> super 'recovery-global-instance'

  @instance: new @()

  getLastSynchronizationStatus: () -> @_loadSynchronizationData().then (state) -> state['lastSyncStatus']

  onStart: () ->
    @_performRecovery().then () =>
      l "Recovery completed"
      @emit 'done'
    .fail (er) =>
      e "Serious error during synchro", er
      ledger.app.emit "wallet:operations:sync:failed"
      @emit 'fatal_error'
    .fin =>
      # Delete sync token and stop
      ledger.api.BlockRestClient.instance.refreshLastBlock()
      @_deleteSynchronizationToken(syncToken) if syncToken?
      @stopIfNeccessary()

  _performRecovery: () ->
    syncToken = null
    savedState = {}
    @_loadSynchronizationData().then (data) =>
      savedState = data
      @_requestSynchronizationToken()
    .then (token) =>
      syncToken = token
      hdWallet = ledger.wallet.Wallet.instance
      iterate = (index) =>
        d = ledger.defer()
        ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath "#{hdWallet.getRootDerivationPath()}/#{index}'", ->
          d.resolve()
        d.promise.then =>
          @_recoverAccount(index, savedState, syncToken)
        .then (isEmpty) =>
          unless isEmpty
            iterate(index + 1)
      iterate(0)
    .fail (er) =>
      # Handle reorgs
      e "Failure during synchro", er
      if er?.getStatusCode?() is 404
        @_handlerReorgs(savedState, er.block).then () =>
          @_performRecovery()
      else
        # Mark failure and save
        savedState['lastSyncStatus'] = 'failure'
        @_saveSynchronizationData(savedState)
        throw er
    .then =>
      savedState['lastSyncStatus'] = 'success'
      @_saveSynchronizationData(savedState)

  _recoverAccount: (accountIndex, savedState, syncToken) ->
    savedAccountState = savedState["account_#{accountIndex}"] or {}
    batches = savedAccountState["batches"] or []
    l "Recover account #{accountIndex}"
    iterate = (index) =>
      batch = batches[index]
      unless batch?
        batch =
          index: index
          blockHash: null
        batches.push batch
      l "Recover batch #{index}"
      @_recoverBatch(batch, accountIndex, syncToken).then ({hasNext, block}) ->
        if block? and (!batch['blockHeight']? or block.height > batch['blockHeight'])
          batch['blockHash'] = block.hash
          batch['blockHeight'] = block.height
        if !block? and !batch['blockHash']?
          batches.splice(-1, 1)
        if hasNext
          iterate(index)
        else if !hasNext and block?
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
          d.resolve(batches.length == 0)
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
      ledger.tasks.TransactionConsumerTask.instance.pushTransactions(result['txs'])
      ledger.tasks.TransactionConsumerTask.instance.pushCallback =>
        d.resolve({hasNext, block})
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

  _handlerReorgs: (state, failedBlock) ->
    # Iterate through the state and delete any block higher or equal to block.height
    # Remove from the database all orphan transaction and blocks
    # Save the new state

  @reset: () ->
    @instance = new @
