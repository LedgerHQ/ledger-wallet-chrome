
_.async =
  each: (array, callback) ->
    index = 0
    length = array.length
    done = ->
      return if index >= length
      index += 1
      hasNext = (index) < length
      callback(array[index - 1], (if hasNext then done else _.noop), hasNext, index - 1, length)
    done()