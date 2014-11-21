
_.mixin
  eachBatch: (array, batchSize, iteratee) ->
    batch = []
    for item in array
      batch.push item
      if batch.length >= batchSize
        iteratee(array, yes)
        batch = []
    iteratee(batch, no)