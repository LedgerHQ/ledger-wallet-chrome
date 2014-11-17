
LRUCache.fromJson = (jsonArray, limit = 20) ->
  cache = new LRUCache(limit)
  for item in jsonArray
    cache.set(item.key, item.value)
  cache