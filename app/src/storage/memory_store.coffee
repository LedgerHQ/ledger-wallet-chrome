class ledger.storage.MemoryStore extends ledger.storage.Store

  constructor: ->
    super
    @_data = {}

  # @see ledger.storage.Store#_raw_get
  _raw_get: (keys, cb) -> _.defer => cb?(_(@_data).pick(keys))

  # @see ledger.storage.Store#_raw_set
  _raw_set: (items, cb=->) ->
    _.defer =>
      _.extend(@_data, items)
      cb?()

  # @see ledger.storage.Store#_raw_keys
  _raw_keys: (cb) -> _.defer => cb?(_(@_data).keys())

  # @see ledger.storage.Store#_raw_remove
  _raw_remove: (keys, cb=->) ->
    _.defer =>
      @_data = _(@_data).omit(keys)
      cb?()