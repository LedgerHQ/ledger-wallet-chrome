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

    if ledger.wallet.HDWallet.instance.getAccountsCount() == 0
      @once 'chronocoin:done', => @_restoreBip44Layout()
      @_restoreChronocoinLayout()
    else
      @_restoreBip44Layout()

  onStop: () ->

  _restoreChronocoinLayout: () ->
    wallet = ledger.app.wallet
    wallet.getPublicAddress "0'/0/0", (publicAddress) =>
      wallet.getPublicAddress "0'/1/0", (changeAddress) =>
        ledger.api.TransactionsRestClient.instance.getTransactions [publicAddress.bitcoinAddress.value, changeAddress.bitcoinAddress.value], (transactions, error) =>
          if transactions?.length > 0
            account = ledger.wallet.HDWallet.instance.getOrCreateAccount(0)
            account.importChangeAddressPath("0'/1/0")
            account.importPublicAddressPath("0'/0/0")
            account.save()
          else if error?
            @emit 'chronocoin:fatal'
          else
            ledger.wallet.HDWallet.instance.createAccount()
          @emit 'chronocoin:done'

  _restoreBip44Layout: () ->
    accountIndex = 0
    recoverAccount = =>
      return @emit 'bip44:done' if accountIndex is 1 # App first version limitiation

      account = ledger.wallet.HDWallet.instance.getOrCreateAccount(accountIndex)

      done = =>
        @emit 'bip44:account:done'
        accountIndex += 1
        do recoverAccount
      ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath "#{ledger.wallet.HDWallet.instance.getRootDerivationPath()}/#{accountIndex}'", _.noop
      @_restoreBip44AccountChainsLayout account, => do done
    do recoverAccount

  _restoreBip44AccountChainsLayout: (account, done) ->
    isRestoringChangeChain = yes
    isRestoringPublicChain = yes
    testIndex = (publicIndex, changeIndex) =>
      publicIndex = parseInt publicIndex
      changeIndex = parseInt changeIndex
      paths = []
      if isRestoringPublicChain
        for i in [publicIndex...publicIndex + 20]
          paths.push account.getPublicAddressPath(i)
      if isRestoringChangeChain
        for i in [changeIndex...changeIndex + 20]
          paths.push account.getChangeAddressPath(i)
      ledger.wallet.pathsToAddresses paths, (addresses) =>
        addressesPaths = _.invert addresses
        ledger.api.TransactionsRestClient.instance.getTransactions _.values(addresses), (transactions, error) =>
          return @emit 'bip44:fatal' if error?
          usedAddresses = []
          select = (array) -> _.select array, ((i) -> if addressesPaths[i]? then yes else no)

          for transaction in transactions
            Operation.pendingRawTransactionStream().write(transaction)
            for input in transaction.inputs
              usedAddresses = usedAddresses.concat(select(input.addresses))
            for output in transaction.outputs
              usedAddresses = usedAddresses.concat(select(output.addresses))

          shiftChange = account.getCurrentChangeAddressIndex()
          shiftPublic = account.getCurrentPublicAddressIndex()

          usedPaths = _.unique((addressesPaths[usedAddress] for usedAddress in usedAddresses))
          account.notifyPathsAsUsed _.values(usedPaths)

          shiftChange = shiftChange isnt account.getCurrentChangeAddressIndex()
          shiftPublic = shiftPublic isnt account.getCurrentPublicAddressIndex()

          if shiftChange and shiftPublic
            testIndex account.getCurrentPublicAddressIndex(), account.getCurrentChangeAddressIndex()
          else if shiftChange
            isRestoringPublicChain = no
            testIndex account.getCurrentPublicAddressIndex(), account.getCurrentChangeAddressIndex()
          else if shiftPublic
            isRestoringChangeChain = no
            testIndex account.getCurrentPublicAddressIndex(), account.getCurrentChangeAddressIndex()
          else
            do done

    testIndex account.getCurrentPublicAddressIndex(), account.getCurrentChangeAddressIndex()


  @reset: () ->
    @instance = new @
