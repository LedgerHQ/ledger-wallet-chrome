
class ledger.wallet.HDWallet.Cache

  constructor: (hdwallet) ->
    @hdwallet = hdwallet

  initialize: (callback) ->
    cacheLimitSize = @hdwallet.getAccountsCount() * 100
    @hdwallet._store.get ['cache'], (result) =>
      if result.cache?
        @_cache = LRUCache.fromJson(JSON.parse(result.cache), cacheLimitSize)
      else
        @_cache = new LRUCache(cacheLimitSize)
      callback?()

  get: (path) -> @_cache.get(path)

  # @param [Array] tuples An array array of tuple [path, address] to cache
  set: (tuples, callback = _.noop) ->
    for tuple in tuples
      [key, value] = tuple
      @_cache.set key, value
    @hdwallet._store.set {cache: JSON.stringify(@_cache.toJSON()), callback}
