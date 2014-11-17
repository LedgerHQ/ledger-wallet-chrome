@ledger.wallet ?= {}

class ledger.wallet.HDWallet

  getAccount: (walletIndex) ->

  createAccount: () ->

  initialize: (store, callback) ->
    @_store = store
    @_store.get ['accounts'], (result) =>
      @_accounts = []
      return unless result.accouts?
      _.async.each [0..result.accounts - 1], (accountIndex, done) =>
        account = new Account(@, accountIndex, @_store)
        account.initialize () =>
          @_accounts.push account
          do done

  isEmpty: () -> @_accounts?.length > 0

  getRootDerivationPath: () -> "44'/0'"

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

restoreStructure = (wallet, done) ->
  if ledger.wallet.HDWallet.instance.isEmpty()
    l 'Restore Wallet'

_.extend ledger.wallet,

  initialize:  (wallet, callback) ->
    intializationMethods = [openStores, openHdWallet, restoreStructure]
    notifyMethodDone = _.after intializationMethods.length, () => callback?()
    _.async.each intializationMethods, (method , next) =>
      done = ->
        do notifyMethodDone
        do next
      method wallet, done

  release: (wallet, callback) ->
    callback?()
