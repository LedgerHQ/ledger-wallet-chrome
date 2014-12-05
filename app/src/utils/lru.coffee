
LRUCache.fromJson = (jsonArray, limit = 200000) ->
  cache = new LRUCache(limit)
  for item in jsonArray
    cache.put(item.key, item.value)
  cache