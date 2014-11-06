
@ledger.collections ?= {}
@ledger.collections.createCollection = (collectionName) ->
  className = _.str.classify(collectionName)
  ledger.collections[className] = class Collection extends ledger.collections.Collection
  ledger.collections[className].name =
  ledger.collections[collectionName] = ledger.collections[className].global()

class ledger.collections.Collection extends EventEmitter

  insert: (object) ->

  remove: (object) ->

  perform: (callback) ->

  @global: () ->
    globalCollection = new @
   # globalCollection.__uid =  ledger.storage.local.createUniqueObjectIdentifier("global_#{_.str.underscored(@name)}", 42)
    globalCollection.isGlobal = () -> yes
    globalCollection

  @relation: (arrayUid) ->
    collection = new @
    collection.__uid = arrayUid
    globalCollection.isGlobal = () -> no
    collection
