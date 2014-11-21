
LRUCache.fromJson = (jsonArray, limit = 20) ->
  cache = new LRUCache(limit)
  for item in jsonArray
    cache.put(item.key, item.value)
  cache