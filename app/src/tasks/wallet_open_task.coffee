
###
  Procedures declaration
###

openStores = (dongle, raise, done) ->
  ledger.bitcoin.bitid.getAddress (address) =>
    bitIdAddress = address.bitcoinAddress.toString(ASCII)
    dongle.getPublicAddress "0x50DA'/0xBED'/0xC0FFEE'", (pubKey) =>
      if not (pubKey?.bitcoinAddress?) or not (bitIdAddress?)
        logger().error("Fatal error during openStores, missing bitIdAddress and/or pubKey.bitcoinAddress")
        raise(ledger.errors.new(ledger.errors.UnableToRetrieveBitidAddress))
        ledger.app.emit 'wallet:initialization:fatal_error'
        return
      ledger.storage.openStores bitIdAddress, pubKey.bitcoinAddress.value
      done?()
      return
    return

openHdWallet = (dongle, raise, done) -> ledger.wallet.initialize(dongle, done)

startDerivationTask = (dongle, raise, done) ->
  hdWallet = ledger.wallet.Wallet.instance
  ledger.tasks.AddressDerivationTask.instance.start()
  _.defer =>
    for accountIndex in [0...hdWallet.getAccountsCount()]
      ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath "#{hdWallet.getRootDerivationPath()}/#{accountIndex}'", _.noop
    done?()

openAddressCache = (dongle, raise, done) ->
  cache = new ledger.wallet.Wallet.Cache(ledger.wallet.Wallet.instance)
  cache.initialize =>
    ledger.wallet.Wallet.instance.cache = cache
    done?()

restoreStructure = (dongle, raise, done) ->
  if ledger.wallet.Wallet.instance.isEmpty()
    ledger.app.emit 'wallet:initialization:creation'
    ledger.tasks.WalletLayoutRecoveryTask.instance.on 'done', () =>
      done?()
    ledger.tasks.WalletLayoutRecoveryTask.instance.on 'fatal_error', () =>
      ledger.storage.local.clear()
      ledger.app.emit 'wallet:initialization:failed'
      raise ledger.errors.new(ledger.errors.FatalErrorDuringLayoutWalletRecovery)
    ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
  else
    ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
    done?()

completeLayoutInitialization = (dongle, raise, done) ->
  ledger.wallet.Wallet.instance.isInitialized = yes
  done?()

openDatabase = (dongle, raise, done) ->
  ledger.database.init =>
    ledger.database.contexts.open()
    done()

initializeWalletModel = (dongle, raise, done) -> Wallet.initializeWallet done

initializePreferences = (dongle, raise, done) -> ledger.preferences.init done

ProceduresOrder = [
  openStores
  openHdWallet
  startDerivationTask
  openAddressCache
  restoreStructure
  completeLayoutInitialization
  openDatabase
  initializeWalletModel
  initializePreferences
]

###
  End of procedures declaration
###

class ledger.tasks.WalletOpenTask extends ledger.tasks.Task

  steps: ProceduresOrder

  @instance: new @
  @reset: -> @instance = new @

  constructor: ->
    super 'wallet_open_task'
    @_completion = new ledger.utils.CompletionClosure()

  onStart: ->
    super
    raise = (error) =>
      @_completion.failure(error)
      raise.next = _.noop
      @stopIfNeccessary()

    _.async.each @steps, (step, next, hasNext) =>
      return unless @isRunning()
      raise.next = next
      step ledger.app.dongle, raise, =>
        do raise.next
        @_completion.success(this) unless hasNext

  onStop: ->
    @_completion.failure(ledger.errors.new(ledger.errors.InterruptedTask)) unless @_completion.isCompleted()
    @_completion = new ledger.utils.CompletionClosure()

  onComplete: (callback) -> @_completion.onComplete callback

logger = -> ledger.utils.Logger.getLoggerByTag("WalletOpening")