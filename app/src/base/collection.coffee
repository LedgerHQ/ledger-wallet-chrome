
@ledger.collections ?= {}
@ledger.collections.createCollection = (collectionName) ->
  ledger.collections[collectionName] = class Collection extends ledger.collections.Collection

class ledger.collections.Collection extends EventEmitter

  insert: (object) ->

  remove: (object) ->
