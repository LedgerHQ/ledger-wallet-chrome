@ledger.wallet ?= {}

logger = -> ledger.utils.Logger.getLoggerByTag("WalletLayout")

class ledger.wallet.Wallet

  getAccount: (accountIndex) -> @_accounts[accountIndex]

  getAccountFromDerivationPath: (derivationPath) -> @_getAccountFromDerivationPath(derivationPath, @getAccount)

  getOrCreateAccountFromDerivationPath: (derivationPath) -> @_getAccountFromDerivationPath(derivationPath, @getOrCreateAccount)

  _getAccountFromDerivationPath: (derivationPath, getter) ->
    return null unless derivationPath?
    account = null
    # Easy way
    if match = derivationPath.match("#{@getRootDerivationPath()}/(\\d+)'/(0|1)/(\\d+)")
      [__, accountIndex] = match
      account = getter.call(this, +accountIndex)
    return account if account?
    # Crappy way
    for account in @_accounts
      return account if _.contains(account.getAllChangeAddressesPaths(), derivationPath)
      return account if _.contains(account.getAllPublicAddressesPaths(), derivationPath)

  getAccountFromAddress: (address) -> @getAccountFromDerivationPath(@cache?.getDerivationPath(address))

  createAccount: (id = undefined) ->
    account = new ledger.wallet.Wallet.Account(@, id or @getNextAccountIndex(), @_store)
    @_accounts.push account
    do @save
    ledger.tasks.AddressDerivationTask.instance.registerExtendedPublicKeyForPath(account.getRootDerivationPath(), _.noop)
    account

  getOrCreateAccount: (id) ->
    return @getAccount(id) if @getAccount(id)
    @createAccount(id)

  getNextAccountIndex: -> @getNextAccountIndexes(1)[0]

  getNextAccountIndexes: (numberOfIndex) -> index for index in [0...@_accounts.length + numberOfIndex] when @_accounts[index]? is false or @_accounts[index].isEmpty()

  getAllObservedAddressesPaths: ->
    paths = []
    for account in @_accounts
     paths = paths.concat(account.getAllObservedAddressesPaths())
    paths

  initialize: (store, callback) ->
    @_store = store
    @_store.get ['accounts'], (result) =>
      @_accounts = []
      return callback?() unless result.accounts?
      _.async.each [0...result.accounts], (accountIndex, done, hasNext) =>
        try
          account = new ledger.wallet.Wallet.Account(@, accountIndex, @_store)
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

  isEmpty: -> @_accounts?.length == 0

  isInitialized: no

  getRootDerivationPath: () -> "44'/#{ledger.config.network.bip44_coin_type}'"

  getAccountsCount: () ->
    count = 0
    for account in @_accounts when account?
      count += 1
    count

  getNonEmptyAccountsCount: ->
    count = 0
    count += 1 for account in @_accounts when !account?.isEmpty()
    count

  save: (callback = _.noop) ->
    @_store.set {'accounts': @getAccountsCount()}, callback

  serialize: ->
    obj = {accounts: @getAccountsCount()}
    for account in @_accounts
      obj[account._storeId] = account.serialize()
    obj

  remove: (callback = _.noop) ->
    _.async.each @_accounts, (account, done, hasNext) =>
      account.remove =>
        unless hasNext
          @_store.remove(["accounts"],  callback)
        do done

  _removeAccount: (account, callback) ->
    if _(@_accounts).contains(account)
      @_accounts = _(@_accounts).without(account)
      @save()
      callback?()

  @instance: undefined

class ledger.wallet.Wallet.Account

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
    ledger.app.dongle.getExtendedPublicKey @getRootDerivationPath(), (xpub) =>
      @_xpub = xpub
      callback?()

  initialize: (callback) ->
    @_store.get [@_storeId], (result) =>
      @_account = result[@_storeId]
      @_initialize()
      callback?()

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

  getObservedPublicAddressesPaths: (gap = ledger.preferences.instance?.getDiscoveryGap() or ledger.config.defaultAddressDiscoveryGap) ->
    paths = ("#{@getRootDerivationPath()}/0/#{index}" for index in [0...@getCurrentPublicAddressIndex() + gap + 1])
    _(paths).compact()

  getObservedChangeAddressesPaths: (gap = ledger.preferences.instance?.getDiscoveryGap() or ledger.config.defaultAddressDiscoveryGap) ->
    paths = ("#{@getRootDerivationPath()}/1/#{index}" for index in [0...@getCurrentChangeAddressIndex() + gap + 1])
    _(paths).compact()

  getObservedAddressesPaths: (type) ->
    switch type
      when 'change' then @getObservedChangeAddressesPaths()
      when 'public' then @getObservedPublicAddressesPaths()
  getAllObservedAddressesPaths: -> @getObservedChangeAddressesPaths().concat(@getObservedPublicAddressesPaths())

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
    allPaths = @getAllAddressesPaths()
    hasDiscoveredNewPaths = no
    wasEmpty = @isEmpty()
    for path in paths
      continue if _(allPaths).contains(path) and path isnt @getCurrentPublicAddressPath() and path isnt @getCurrentChangeAddressPath()
      path = path.replace("#{@getRootDerivationPath()}/", '').split('/')
      switch path[0]
        when '0' then @_notifyPublicAddressIndexAsUsed(parseInt(path[1]))
        when '1' then @_notifyChangeAddressIndexAsUsed(parseInt(path[1]))
      hasDiscoveredNewPaths = yes
    if wasEmpty is true and @isEmpty() is false
      @wallet.createAccount()
    hasDiscoveredNewPaths

  _notifyPublicAddressIndexAsUsed: (index) ->
    #logger().info 'Notify public change', index, 'current is', @_account.currentPublicIndex
    if index < @_account.currentPublicIndex
      logger().info 'Index is less than current'
      derivationPath = "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index}"
      @_account.excludedPublicPaths = _.without @_account.excludedPublicPaths, derivationPath
    else if index > @_account.currentPublicIndex
      logger().info 'Index is more than current'
      difference =  index - (@_account.currentPublicIndex + 1)
      @_account.excludedPublicPaths ?= []
      for i in [0...difference]
        derivationPath = "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index - i - 1}"
        @_account.excludedPublicPaths.push derivationPath unless _.contains(@_account.excludedPublicPaths, derivationPath)
      @_account.currentPublicIndex = parseInt(index) + 1
    else if index == @_account.currentPublicIndex
      logger().info 'Index is equal to current'
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
    logger().info 'shift public'
    index = @_account.currentPublicIndex
    index = 0 unless index?
    index = parseInt(index) if _.isString(index)
    @_account.currentPublicIndex = index + 1
    @save()
    ledger.wallet.pathsToAddresses [@getCurrentPublicAddressPath()], callback

  shiftCurrentChangeAddressPath: (callback) ->
    logger().info 'shift change'
    index = @_account.currentChangeIndex
    index = 0 unless index?
    index = parseInt(index) if _.isString(index)
    @_account.currentChangeIndex = index + 1
    @save()
    ledger.wallet.pathsToAddresses [@getCurrentChangeAddressPath()], callback

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

  serialize: -> _.clone(@_account)

  remove: (callback = _.noop) ->
    @wallet._removeAccount this
    @_store.remove([@_storeId], callback)

  isEmpty: -> @getCurrentChangeAddressIndex() is 0 and @getCurrentPublicAddressIndex() is 0

_.extend ledger.wallet,

  initialize: (dongle, callback=undefined) ->
    previousLayout = new ledger.wallet.Wallet()
    hdWallet = new ledger.wallet.Wallet()
    previousLayout.initialize ledger.storage.wallet, =>
      unless previousLayout.isEmpty()
        ledger.storage.sync.wallet.set previousLayout.serialize(), =>
          previousLayout.release()
          ledger.storage.wallet.remove ["accounts", "account_0"], =>
            @_endInitialize(hdWallet, callback)
      else
        @_endInitialize(hdWallet, callback)

  _endInitialize: (hdWallet, callback) ->
    hdWallet.initialize ledger.storage.sync.wallet, () =>
      ledger.wallet.Wallet.instance = hdWallet
      callback?()

  release: (dongle, callback) ->
    ledger.wallet.Wallet.instance?.release()
    ledger.wallet.Wallet.instance = null
    callback?()