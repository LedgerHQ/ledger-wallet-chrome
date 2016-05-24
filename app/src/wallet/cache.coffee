
class ledger.wallet.Wallet.Cache

  constructor: (name, hdwallet) ->
    @hdwallet = hdwallet
    @_name = name
    @save = _.debounce(@save.bind(this), 200)

  initialize: (callback) ->
    cacheLimitSize = 1 << 31 >>> 0
    ledger.storage.wallet.get [@_name], (result) =>
      if result[@_name]?
        @_cache = LRUCache.fromJson(result[@_name], cacheLimitSize)
      else
        @_cache = new LRUCache(cacheLimitSize)
      callback?()

  get: (path) -> @_cache.get(path)

  hasPublicKey: (publicKey) -> if @getDerivationPath()? then yes else no

  getDerivationPath: (publicKey) ->
    _(@_cache.toJSON()).where({value: publicKey})[0]?.key

  # @param [Array] tuples An array array of tuple [path, address] to cache
  set: (tuples, callback = _.noop) ->
    for tuple in tuples
      [key, value] = tuple
      @_cache.set key, value
    _.defer -> callback?()
    @save()

  save: (callback = undefined) ->
    data = {}
    data[@_name] = @_cache.toJSON()
    ledger.storage.wallet.set data, callback