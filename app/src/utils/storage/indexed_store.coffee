# A special type of store with an index table. This store is able to deal with special types (objects, arrays) and
# allow to create real data structure (basic stores are only able to deal with key/value entry).
# This store takes another store and manages it
class @ledger.storage.IndexedStore

  # @param [ledger.storage.Store] store The store that will be managed by the indexed store
  constructor: (@store) ->

  # Perform an operation once the store is correctly loaded
  # @private
  perform: (callback) ->
    callback()

