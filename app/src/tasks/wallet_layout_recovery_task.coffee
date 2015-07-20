class ledger.tasks.WalletLayoutRecoveryTask extends ledger.tasks.Task

  constructor: -> super 'recovery-global-instance'
  @instance: new @()

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

  @reset: () ->
    @instance = new @
