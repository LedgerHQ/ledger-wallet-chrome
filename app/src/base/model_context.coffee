
ledger.db ?= {}
ledger.db.contexts ?= {}

class Collection

  constructor: (collection) ->
    @_collection = collection

  insert: (model) ->

  remove: (model) ->

  update: (model) ->

  get: (id) ->

  chain: () ->


class ledger.db.contexts.Context

  contructor: (db) ->
    @_db = db

  getCollection: (name) ->
    for collection in @_db.listCollections()
      return @_db.getCollection(collection.name) if collection.name is name
    @_db.addCollection name



_.extend ledger.db.contexts,

  open: (callback) ->