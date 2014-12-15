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
        l account.getCurrentPublicAddressPath()
        @emit 'bip44:account:done'
        accountIndex += 1
        do recoverAccount
      account.initializeXpub =>
        @_restoreBip44AccountChainsLayout account, => do done
    do recoverAccount

  _restoreBip44AccountChainsLayout: (account, done) ->
    isRestoringChangeChain = yes
    isRestoringPublicChain = yes

    testIndex = (index) =>
      paths = []
      paths.push account.getCurrentPublicAddressPath() if isRestoringPublicChain
      paths.push account.getCurrentChangeAddressPath() if isRestoringChangeChain
      ledger.wallet.pathsToAddresses paths, (addresses) =>
        ledger.api.TransactionsRestClient.instance.getTransactions _.values(addresses), 1, (transactions, error) =>
          return @emit 'bip44:fatal' if error?

          shiftChange = no
          shiftPublic = no

          for transaction in transactions
            Operation.pendingRawTransactionStream().write(transaction)
            for input in transaction.inputs
              shiftPublic = yes if _.contains(input.addresses, account.getCurrentPublicAddress())
              shiftChange = yes if _.contains(input.addresses, account.getCurrentChangeAddress())
              break if shiftChange and shiftChange
            if not shiftChange or not shiftPublic
              for output in transaction.outputs
                shiftPublic = yes if _.contains(output.addresses, account.getCurrentPublicAddress())
                shiftChange = yes if _.contains(output.addresses, account.getCurrentChangeAddress())
                break if shiftChange and shiftChange
          if shiftChange and shiftPublic
            account.shiftCurrentChangeAddressPath =>
              account.shiftCurrentPublicAddressPath => testIndex(index + 1)
          else if shiftChange
            isRestoringPublicChain = no
            account.shiftCurrentChangeAddressPath => testIndex(index + 1)
          else if shiftPublic
            isRestoringChangeChain = no
            account.shiftCurrentPublicAddressPath => testIndex(index + 1)
          else
            do done

    testIndex(0)


  @reset: () ->
    @instance = new @
