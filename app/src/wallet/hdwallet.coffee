@ledger.wallet ?= {}

class ledger.wallet.HDWallet

  getAccount: (accountIndex) -> @_accounts[accountIndex]

  getAccountFromDerivationPath: (derivationPath) ->
    return null unless derivationPath?
    account = null
    # Easy way
    if _.str.startsWith(derivationPath, "44'")
      parts = derivationPath.split(',')
      accountIndex = parts[2]
      if accountIndex?
        accountIndex = parseInt(accountIndex.substr(0, accountIndex.length - 1))
        account = @getAccount(accountIndex)

    return account if account?
    # Crappy way
    for account in @_accounts
      return account if _.contains(account.getAllChangeAddressesPaths(), derivationPath)
      return account if _.contains(account.getAllPublicAddressesPaths(), derivationPath)

  getAccountFromAddress: (address) -> @getAccountFromDerivationPath(@cache?.getDerivationPath(address))

  createAccount: () ->
    account = new ledger.wallet.HDWallet.Account(@, @getAccountsCount(), @_store)
    @_accounts.push account
    do @save
    account

  getOrCreateAccount: (id) ->
    return @getAccount(id) if @getAccount(id)
    do @createAccount

  initialize: (store, callback) ->
    @_store = store
    @_store.get ['accounts'], (result) =>
      @_accounts = []
      result.accounts = parseInt(result.accounts) if result.accounts?
      return callback()? unless result.accounts?
      _.async.each [0..result.accounts - 1], (accountIndex, done, hasNext) =>
        try
          account = new ledger.wallet.HDWallet.Account(@, accountIndex, @_store)
          account.initialize () =>
            @_accounts.push account
            do done
            callback?() unless hasNext
        catch er
          e er

  release: () ->
    account.release() for account in @_accounts
    @_accounts = null
    @cache = null

  isEmpty: () -> @_accounts?.length == 0

  isInitialized: no

  getRootDerivationPath: () -> "44'/0'"

  getAccountsCount: () -> @_accounts.length

  save: (callback = _.noop) ->
    @_store.set {'accounts': @getAccountsCount()}, callback

  @instance: undefined

class ledger.wallet.HDWallet.Account

  constructor: (wallet, index, store) ->
    @wallet = wallet
    @index = index
    @_store = store
    @_storeId = "account_#{@index}"
    @_initialize()

  _initialize: () ->
    @_account ?= {}
    @_account.currentChangeIndex ?= 0
    @_account.currentPublicIndex ?= 0

  initialize: (callback) ->
    @_store.get [@_storeId], (result) =>
      accountJsonString = result[@_storeId]
      @_account = JSON.parse(accountJsonString) if accountJsonString?
      @_initialize()
      ledger.app.wallet.getExtendedPublicKey "#{@wallet.getRootDerivationPath()}/#{@index}'", (xpub) =>
        @_xpub = xpub
        callback?()

  release: () ->
    @wallet = null
    @_store = null
    @_storeId = null
    @index = null

  getAllChangeAddressesPaths: () ->
    paths = []
    paths = paths.concat(@_account.importedChangePaths)
    for index in [0..@_account.currentChangeIndex]
      paths.push "#{@wallet.getRootDerivationPath()}/#{@index}'/1/#{index}"
    paths = _.difference(paths, @_account.excludedChangePaths)
    paths
    _(paths).without(undefined)

  getAllPublicAddressesPaths: () ->
    paths = []
    paths = paths.concat(@_account.importedPublicPaths)
    for index in [0..@_account.currentPublicIndex]
      paths.push "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index}"
    paths = _.difference(paths, @_account.excludedPublicPaths)
    _(paths).without(undefined)

  getAllAddressesPaths: () -> @getAllPublicAddressesPaths().concat(@getAllChangeAddressesPaths())

  getCurrentPublicAddressIndex: () -> @_account.currentPublicIndex or 0
  getCurrentChangeAddressIndex: () -> @_account.currentChangeIndex or 0
  getCurrentAddressIndex: (type) ->
    switch type
      when 'change' then @getChangeAddressPath(index)
      when 'public' then @getPublicAddressPath(index)

  getCurrentPublicAddressPath: () -> @getPublicAddressPath(@getCurrentPublicAddressIndex())
  getCurrentChangeAddressPath: () -> @getChangeAddressPath(@getCurrentChangeAddressIndex())
  getCurrentAddressPath: (type) ->
    switch type
      when 'change' then @getCurrentChangeAddressPath(index)
      when 'public' then @getCurrentPublicAddressPath(index)


  getPublicAddressPath: (index) -> "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index}"
  getChangeAddressPath: (index) -> "#{@wallet.getRootDerivationPath()}/#{@index}'/1/#{index}"
  getAddressPath: (index, type) ->
    switch type
      when 'change' then @getChangeAddressPath(index)
      when 'public' then @getPublicAddressPath(index)

  getCurrentChangeAddress: () -> ledger.wallet.HDWallet.instance.cache?.get(@getCurrentChangeAddressPath())
  getCurrentPublicAddress: () -> ledger.wallet.HDWallet.instance.cache?.get(@getCurrentPublicAddressPath())

  shiftCurrentPublicAddressPath: (callback) ->
    l 'shift public'
    index = @_account.currentPublicIndex
    index = 0 unless index?
    index = parseInt(index) if _.isString(index)
    @_account.currentPublicIndex = index + 1
    @save()
    ledger.app.wallet?.getPublicAddress @getCurrentPublicAddressPath(), => callback?()

  shiftCurrentChangeAddressPath: (callback) ->
    l 'shift change'
    index = @_account.currentChangeIndex
    index = 0 unless index?
    index = parseInt(index) if _.isString(index)
    @_account.currentChangeIndex = index + 1
    @save()
    ledger.app.wallet?.getPublicAddress @getCurrentChangeAddressPath(), => callback?()

  importPublicAddressPath: (addressPath) ->
    @_account.importedPublicPaths ?= []
    @_account.importedPublicPaths.push addressPath

  importChangeAddressPath: (addressPath) ->
    @_account.importedChangePaths ?= []
    @_account.importedChangePaths.push addressPath

  save: (callback = _.noop) ->
    saveHash = {}
    saveHash[@_storeId] = @_account
    @_store.set saveHash, callback

openStores = (wallet, done) ->
  wallet.getBitIdAddress (bitIdAddress) =>
    wallet.getPublicAddress "0x50DA'/0xBED'/0xC0FFEE'", (pubKey) =>
      l pubKey
      if not pubKey?.bitcoinAddress? or not bitIdAddress?
        ledger.app.emit 'wallet:initialization:fatal_error'
        return
      ledger.storage.openStores bitIdAddress, pubKey.bitcoinAddress.value, done

openHdWallet = (wallet, done) ->
  ledger.wallet.HDWallet.instance = new ledger.wallet.HDWallet()
  ledger.wallet.HDWallet.instance.initialize(ledger.storage.wallet, done)

openAddressCache = (wallet, done) ->
  try
    ledger.wallet.HDWallet.instance.cache = new ledger.wallet.HDWallet.Cache(ledger.wallet.HDWallet.instance)
    ledger.wallet.HDWallet.instance.cache.initialize done
  catch er
    e er

restoreStructure = (wallet, done) ->
  if ledger.wallet.HDWallet.instance.isEmpty()
    ledger.app.emit 'wallet:initialization:creation'
    ledger.tasks.WalletLayoutRecoveryTask.instance.on 'done', () => done?()
    ledger.tasks.WalletLayoutRecoveryTask.instance.on 'fatal_error', () =>
      ledger.storage.local.clear()
      ledger.app.emit 'wallet:initialization:failed'
    ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
  else
    ledger.tasks.WalletLayoutRecoveryTask.instance.startIfNeccessary()
    done?()

completeInitialization = (wallet, done) ->
  ledger.wallet.HDWallet.instance.isInitialized = yes
  do done

_.extend ledger.wallet,

  initialize:  (wallet, callback) ->
    intializationMethods = [openStores, openHdWallet, openAddressCache, restoreStructure, completeInitialization]
    _.async.each intializationMethods, (method , done, hasNext) =>
      method wallet, done
      callback?() unless hasNext

  release: (wallet, callback) ->
    ledger.storage.closeStores()
    ledger.wallet.HDWallet.instance?.release()
    ledger.wallet.HDWallet.instance = null