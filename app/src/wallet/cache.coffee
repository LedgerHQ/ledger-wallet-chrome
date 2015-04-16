
class ledger.wallet.HDWallet.Cache

  constructor: (hdwallet) ->
    @hdwallet = hdwallet

  initialize: (callback) ->
    cacheLimitSize = 1 << 31 >>> 0
    @hdwallet._store.get ['cache'], (result) =>
      if result.cache?
        @_cache = LRUCache.fromJson(result.cache, cacheLimitSize)
      else
        @_cache = new LRUCache(cacheLimitSize)
      callback?()

  get: (path) -> @_cache.get(path)

  hasPublicKey: (publicKey) -> if @getDerivationPath()? then yes else no

  getDerivationPath: (publicKey) -> _(@_cache.toJSON()).where({value: publicKey})[0]?.key

  # @param [Array] tuples An array array of tuple [path, address] to cache
  set: (tuples, callback = _.noop) ->
    for tuple in tuples
      [key, value] = tuple
      @_cache.set key, value
    @hdwallet._store.set {cache: @_cache.toJSON()}, callback