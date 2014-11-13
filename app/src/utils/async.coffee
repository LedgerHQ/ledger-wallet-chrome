
async =
  each: (array, callback) ->
    index = 0
    length = array.length
    done = ->
      hasNext = index + 1 < length
      callback(array[index], done, hasNext, index, length)
      index += 1
    done()

_.mixin {async}