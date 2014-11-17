@ledger.wallet ?= {}

class ledger.wallet.HDWallet

  getAccount: (walletIndex) -> @_accounts[walletIndex]

  createAccount: () ->

  initialize: (store, callback) ->
    @_store = store
    @_store.get ['accounts'], (result) =>
      @_accounts = []
      return callback()? unless result.accouts?
      _.async.each [0..result.accounts - 1], (accountIndex, done, hasNext) =>
        account = new Account(@, accountIndex, @_store)
        account.initialize () =>
          @_accounts.push account
          do done
          callback?() unless hasNext

  release: () ->
    account.release() for account in @_accounts
    @_accounts = null
    @cache = null

  isEmpty: () -> @_accounts?.length == 0

  isInitialized: no

  getRootDerivationPath: () -> "44'/0'"

  getAccountsCount: () -> @_accounts.length

  @instance: undefined

class ledger.wallet.HDWallet.Account

  constructor: (wallet, index, store) ->
    @wallet = wallet
    @index = index
    @_store = store
    @_storeId = "account_#{@index}"

  initialize: (callback) ->
    @_store.get [@_storeId], (result) =>
      accountJsonString = result[@_storeId]
      @_account = JSON.parse(accountJsonString) if accountJsonString?
      @_account = {} unless @_account
      callback?()

  release: () ->
    @wallet = null
    @_store = null
    @_storeId = null
    @index = null

  getAllChangeAddressesPaths: () ->
    paths = []
    paths = paths.concat(@_account.importedChangePaths)
    if @_account.currentChangeIndex?
      for index in [0..@_account.currentChangeIndex]
        paths.push "#{@wallet.getRootDerivationPath()}/#{@index}'/1/#{index}"
    paths = _.difference(@_account.excludedChangePaths)
    paths

  getAllPublicAddressesPaths: () ->
    paths = []
    paths = paths.concat(@_account.importedPublicPaths)
    if @_account.currentChangeIndex?
      for index in [0..@_account.currentPublicIndex]
        paths.push "#{@wallet.getRootDerivationPath()}/#{@index}'/0/#{index}"
    paths = _.difference(@_account.excludedPublicPaths)
    paths

  getCurrentPublicAddressPath: () ->

  getCurrentChandeAddressPath: () ->

  save: (callback = _.noop) ->
    saveHash = {}
    saveHash[@_storeId] = JSON.stringify(@_account)
    @_store.set saveHash, callback

openStores = (wallet, done) ->
  wallet.getBitIdAddress (bitIdAddress) =>
    wallet.getPublicAddress "44'/0xDEAD/0xFACE/0xCAFE", (pubKey) =>
      ledger.storage.openStores bitIdAddress, pubKey, done

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
    l 'Restore Wallet'
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