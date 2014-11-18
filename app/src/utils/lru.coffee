
LRUCache.fromJson = (jsonArray, limit = 20) ->
  cache = new LRUCache(limit)
  l jsonArray
  for item in jsonArray
    cache.put(item.key, item.value)
  cache