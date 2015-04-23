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
      return callback?() unless result.accounts?
      _.async.each [0...result.accounts], (accountIndex, done, hasNext) =>
        try
          account = new ledger.wallet.HDWallet.Account(@, accountIndex, @_store)
          account.initialize () =>
            @_accounts.push account
            done?()
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

  initializeXpub: (callback) ->
    ledger.app.wallet.getExtendedPublicKey @getRootDerivationPath(), (xpub) =>
      @_xpub = xpub
      callback?()

  initialize: (callback) ->
    @_store.get [@_storeId], (result) =>
      @_account = result[@_storeId]
      @_initialize()
      @initializeXpub callback

  release: () ->
    @wallet = null
    @_store = null
    @_storeId = null
    @index = null

  getRootDerivationPath: () ->
    "#{@wallet.getRootDerivationPath()}/#{@index}'"

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

  getCurrentChangeAddress: () -> @wallet.cache?.get(@getCurrentChangeAddressPath())
  getCurrentPublicAddress: () -> @wallet.cache?.get(@getCurrentPublicAddressPath())

  notifyPathsAsUsed: (paths) ->
    paths = [paths] unless _.isArray(paths)
    for path in paths
      path = path.replace("#{@wallet.getRootDerivationPath()}/0'/", '').split('/')
      switch path[0]
        when '0' then @_notifyPublicAddressIndexAsUsed parseInt(path[1])
        when '1' then @_notifyChangeAddressIndexAsUsed parseInt(path[1])
    return

  _notifyPublicAddressIndexAsUsed: (index) ->
    l 'Notify public change', index, 'current is', @_account.currentPublicIndex
    if index < @_account.currentPublicIndex
      l 'Index is less than current'
      derivationPath = "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index}"
      @_account.excludedPublicPaths = _.without @_account.excludedPublicPaths, derivationPath
    else if index > @_account.currentPublicIndex
      l 'Index is more than current'
      difference =  index - (@_account.currentPublicIndex + 1)
      @_account.excludedPublicPaths ?= []
      for i in [0...difference]
        derivationPath = "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index - i - 1}"
        @_account.excludedPublicPaths.push derivationPath unless _.contains(@_account.excludedPublicPaths, derivationPath)
      @_account.currentPublicIndex = parseInt(index) + 1
    else if index == @_account.currentPublicIndex
        l 'Index is equal to current'
        @shiftCurrentPublicAddressPath()
    @save()

  _notifyChangeAddressIndexAsUsed: (index) ->
    if index < @_account.currentChangeIndex
      derivationPath = "#{@wallet.getRootDerivationPath()}/#{@index}'/1/#{index}"
      @_account.excludedChangePaths = _.without @_account.excludedChangePaths, derivationPath
    else if index > @_account.currentChangeIndex
      difference =  index - (@_account.currentChangeIndex + 1)
      @_account.excludedChangePaths ?= []
      for i in [0...difference]
        derivationPath = "#{@wallet.getRootDerivationPath()}/#{@index}'/1/#{index - i - 1}"
        @_account.excludedChangePaths.push derivationPath unless _.contains(@_account.excludedChangePaths, derivationPath)
      @_account.currentChangeIndex = parseInt(index) + 1
    else if index == @_account.currentChangeIndex
      @shiftCurrentChangeAddressPath()
    @save()

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
      if not pubKey?.bitcoinAddress? or not bitIdAddress?
        ledger.app.emit 'wallet:initialization:fatal_error'
        return
      ledger.storage.openStores bitIdAddress, pubKey.bitcoinAddress.value
      done?()

openHdWallet = (wallet, done) ->
  hdWallet = new ledger.wallet.HDWallet()
  hdWallet.initialize ledger.storage.wallet, () =>
    ledger.wallet.HDWallet.instance = hdWallet
    ledger.tasks.AddressDerivationTask.instance.start()
    _.defer =>
      for accountIndex in [0...hdWallet.getAccountsCount()]
        ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath "#{hdWallet.getRootDerivationPath()}/#{accountIndex}'", _.noop
      done?()

openAddressCache = (wallet, done) ->
  cache = new ledger.wallet.HDWallet.Cache(ledger.wallet.HDWallet.instance)
  cache.initialize =>
    ledger.wallet.HDWallet.instance.cache = cache
    done?()

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
  done?()

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