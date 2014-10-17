class @Model extends @EventEmitter

  @fromJsonArray: (jsonArray) ->
    array = []
    for json in jsonArray
      object = new @(json)
      array.push object
    array

  constructor: (json) ->
    for key, value of json
      @[key] = value

  set: (key, value) ->
    previous = @[key]
    @[key] = value
    @emit "change:#{key}", {oldValue: previous, newValue: value}
    @

  get: (key) ->
    @[key]