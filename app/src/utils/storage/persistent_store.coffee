
@ledger.storage ?= {}

class @ledger.storage.PersistentStore extends @ledger.storage.Store

  constructor: (storeId) ->
    @_storeId = storeId

  _get: (keys, callback) ->


  initialize: (callback) ->
