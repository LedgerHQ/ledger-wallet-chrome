
LRUCache.fromJson = (jsonArray, limit = 20) ->
  cache = new LRUCache(limit)
  cache.set(item.key, item.value) for item in jsonArray
  cache