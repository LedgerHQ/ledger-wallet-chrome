@ledger.storage ?= {}

# Base class for every store. This class should not be used (abstract class).
# Descendant classes should namespace their keys before setting them, in order to allow multiple
# store to work on a unique chrome.storage instance
#
class @ledger.storage.Store extends EventEmitter

  # @param [String] name The store name (for key mangling)
  constructor: (name) ->
    @_name = name
    @_nameRegex = new RegExp("^#{@_name}\\.")

  # Gets one or more items from storage.
  # If keys is empty, retrieve all values in this namespace.
  #
  # @param [Array|String] key A single key to get or a list of keys to get.
  # @param [Function] cb Callback with storage items. Should look like (item) ->
  get: (keys, cb) ->
    this._raw_get this._preprocessKeys(keys), (raw_items) => cb(@_deprocessItems(raw_items))

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->
    this._raw_set(this._preprocessItems(items), cb)

  # Retrieve saved keys.
  #
  # @param [Function] cb A callback invoked with keys.
  keys: (cb) ->
    this._raw_keys (raw_keys) => cb(@_from_ns_keys(raw_keys))

  # Removes one or more items from storage.
  #
  # @param [Array|String] key A single key to get, list of keys to get.
  # @param [Function] cb A callback with removed items.
  remove: (keys, cb) ->
    this._raw_remove this._preprocessKeys(keys), (raw_items) => cb?(@_deprocessItems(raw_items))

  # Removes all items from storage.
  #
  # @param [Function] cb A callback invoked once the store is cleared.
  clear: (cb) ->
    this._raw_keys (raw_keys) =>
      this._raw_remove raw_keys, (raw_items) => cb?(@_deprocessItems(raw_items))

  # Raw get, without processing.
  # @see ledger.storage.Store#get
  _raw_get: (raw_keys, cb) -> throw "Abstract method"

  # Raw set, without processing.
  # @see ledger.storage.Store#set
  _raw_set: (raw_items, cb) -> throw "Abstract method"

  # Raw keys, without processing.
  # @see ledger.storage.Store#keys
  _raw_keys: (cb) -> throw "Abstract method"

  # Raw remove, without processing.
  # @see ledger.storage.Store#remove
  _raw_remove: (raw_keys, cb) -> throw "Abstract method"

  ## Preprocessing ##

  _preprocessKey: (key) -> @_to_ns_key(key)
  _preprocessKeys: (keys) -> _.flatten([keys]).map((key) => @_preprocessKey(key))
  _preprocessValue: (value) -> if value.toJson? then value.toJson() else JSON.stringify(value)
  _preprocessItems: (items) ->
    hash = {}
    for key, value of @_hashize(items)
      hash[@_preprocessKey(key)] = @_preprocessValue(value)
    hash
  # Remove falsy keys and functions
  _hashize: (items) ->
    hash = {}
    for key, value of items
      continue if ! key || key == "null" || key == "undefined" || _.isFunction(value)
      hash[key] = value
    hash

  ## Deprocessing ##

  _deprocessKey: (raw_key) -> @_from_ns_key(raw_key)
  _deprocessKeys: (raw_keys) ->
    _.chain([raw_keys]).flatten().map((raw_key) =>
      try @_deprocessKey(raw_key) catch e
        undefined
    ).compact().value()
  _deprocessValue: (raw_value) -> JSON.parse(raw_value)
  _deprocessItems: (raw_items) ->
    hash = {}
    for raw_key, raw_value of raw_items
      key = @_deprocessKey(raw_key)
      hash[key] = @_deprocessValue(raw_value) if key?
    hash

  ## Namespaces methods ##

  _to_ns_key: (key) -> @_name + "." + key
  _to_ns_keys: (keys) -> (@_to_ns_key(key) for key in keys)
  _from_ns_key: (ns_key) -> ns_key.replace(@_nameRegex, '')
  _from_ns_keys: (ns_keys) -> (@_from_ns_key(ns_key) for ns_key in ns_keys when ns_key.match(@_nameRegex))