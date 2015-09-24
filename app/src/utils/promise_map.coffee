
@ledger ||= {}
@ledger.utils ||= {}

class ledger.utils.PromiseMap

  constructor: ->
    @_map = {}

  set: (key, value) ->
    (@_map[key] ||= ledger.defer()).resolve(value)

  get: (key) -> @_map[key] ||= ledger.defer().promise

  remove: (key) ->
    @_map[key]?.reject(new Error("removed"))
    @_map = _.without(@_map, key)
