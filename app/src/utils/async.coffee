
_.async =
  each: (array, callback) ->
    index = 0
    length = array.length
    return callback?(no, "Empty array") if ! length
    done = ->
      return if index >= length
      index += 1
      hasNext = (index) < length
      callback(array[index - 1], (if hasNext then done else _.noop), hasNext, index - 1, length)
    done()

  eachBatch: (array, batchSize, iteratee) ->
    batch = []
    batchCount = Math.floor(array.length / batchSize) + (if array.length % batchSize > 0 then 1 else 0)
    batchIndex = 0
    length = array.length
    done = ->
      return if batchIndex >= batchCount
      batchIndex += 1
      hasNext = batchIndex < batchCount
      firstIndex = (batchIndex - 1) * batchSize
      lastIndex = Math.min(batchIndex * batchSize - 1, length - 1)
      batch = (array[index] for index in [firstIndex..lastIndex])
      iteratee(batch, (if hasNext then done else _.noop), hasNext, batchIndex, batchCount)
    done()
