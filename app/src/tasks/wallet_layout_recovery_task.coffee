class ledger.tasks.WalletLayoutRecoveryTask extends ledger.tasks.Task

  BatchSize: 20

  constructor: -> super 'recovery-global-instance'

  @instance: new @()

  onStart: () ->
    @_performRecovery().then () =>
      l "Recovery completed"
      @emit 'done'
    .fail (er) =>
      e "Serious error during synchro", er
      @emit 'fatal_error'
    .fin =>
      # Delete sync token and stop
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
      iterate = (index) =>
        @_recoverAccount(index, savedState, syncToken).then (isEmpty) =>
          unless isEmpty
            iterate(index + 1)
      iterate(0)
    .fail (er) ->
      # Handle reorgs
      e "Failure during synchro", er
      if er?.getStatusCode?() is 404
        @_handlerReorgs(savedState, er.block).then () =>
          @_performRecovery()
      else
        throw er

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
    d = ledger.defer()
    wallet = ledger.wallet.Wallet.instance
    account = wallet.getOrCreateAccount(accountIndex)
    blockHash = batch['blockHash']
    from = batch.index * @BatchSize
    to = from + @BatchSize
    hasNext = no
    @_recoverAddresses(account.getRootDerivationPath(), from, to, blockHash, syncToken).then (result) =>
      hasNext = result["truncated"]
      block = @_findHighestBlock(result.txs)
      ledger.tasks.TransactionConsumerTask.instance.pushTransactions(result['txs'])
      ledger.tasks.TransactionConsumerTask.instance.pushCallback =>
        d.resolve({hasNext, block})
    .fail (er) ->
      er.block = block
      throw er
    d.promise

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
    d.promise

  _saveSynchronizationData: (data) ->
    d = ledger.defer()
    l "Saving state", data
    save = {}
    save['ledger.tasks.WalletLayoutRecoveryTask'] = data
    ledger.storage.local.set save, =>
      d.resolve()
    d.promise

  _handlerReorgs: (state, failedBlock) ->
    # Iterate through the state and delete any block heigher or equal to block.height
    # Remove from the database all orphan transaction and blocks
    # Save the new state

  ###
  onStart: () ->
    @once 'bip44:done', =>
      @emit 'done'
      @stopIfNeccessary()
    @once 'bip44:fatal chronocoin:fatal', =>
      @emit 'fatal_error'
      @stopIfNeccessary()
    if ledger.wallet.Wallet.instance.getAccountsCount() == 0
      @once 'chronocoin:done', => @_restoreBip44Layout()
      @_restoreChronocoinLayout()
    else
      @_restoreBip44Layout()


  onStop: () ->

  _restoreChronocoinLayout: () ->
    dongle = ledger.app.dongle
    dongle.getPublicAddress "0'/0/0", (publicAddress) =>
      dongle.getPublicAddress "0'/1/0", (changeAddress) =>
        ledger.api.TransactionsRestClient.instance.getTransactions [publicAddress.bitcoinAddress.value, changeAddress.bitcoinAddress.value], (transactions, error) =>
          if transactions?.length > 0
            account = ledger.wallet.Wallet.instance.getOrCreateAccount(0)
            account.importChangeAddressPath("0'/1/0")
            account.importPublicAddressPath("0'/0/0")
            account.save()
          else if error?
            @emit 'chronocoin:fatal'
          else
            ledger.wallet.Wallet.instance.createAccount()
          @emit 'chronocoin:done'

  _restoreBip44Layout: ->
    wallet = ledger.wallet.Wallet.instance
    numberOfEmptyAccount = 0
    accountGap = ledger.preferences.instance?.getAccountDiscoveryGap() or ledger.config.defaultAccountDiscoveryGap
    restoreAccount = (index) =>
      @_restoreBip44LayoutAccount(wallet.getOrCreateAccount(index)).then (isEmpty) =>
        @emit 'bip44:account:done'
        numberOfEmptyAccount += 1 if isEmpty
        if numberOfEmptyAccount >= accountGap
          l 'Restore done at', index
          @emit 'bip44:done'
        else
          l 'Continue restoring ', index + 1
          restoreAccount(index + 1)
        return
      .fail (err) =>
        @emit 'bip44:fatal', err
    restoreAccount(0)

  _restoreBip44LayoutAccount: (account) ->
    # Request until there is no tx
    @_requestUntilReturnsEmpty("#{account.getRootDerivationPath()}/0", account.getCurrentPublicAddressIndex()).then (isEmpty) =>
      if isEmpty
        yes
      else
        @_requestUntilReturnsEmpty("#{account.getRootDerivationPath()}/1", account.getCurrentChangeAddressIndex()).then =>
          no

  _requestUntilReturnsEmpty: (root, index) ->
    d = ledger.defer()
    gap = ledger.preferences.instance?.getDiscoveryGap() or ledger.config.defaultAddressDiscoveryGap
    paths = ("#{root}/#{i}" for i in [index...index + gap])
    ledger.wallet.pathsToAddresses paths, (addresses) =>
      addresses = _.values(addresses)
      ledger.api.TransactionsRestClient.instance.getTransactions addresses, (transactions) =>
        l "Received tx", transactions
        if transactions.length is 0
          d.resolve(index is 0)
        else
          ledger.tasks.TransactionConsumerTask.instance.pushTransactions(transactions)
          d.resolve(@_requestUntilReturnsEmpty(root, index + gap))
      return
    d.promise
  ###

  @reset: () ->
    @instance = new @
