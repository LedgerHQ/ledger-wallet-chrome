class @Model extends @EventEmitter

  constructor: (context, base) ->
    throw 'Model can not be build without a context' unless context?
    @_context = context
    @_collection = context.getCollection(@getCollectionName())
    @_object = base
    @_needsUpdate = if @isInserted() then no else yes
    @_deleted = no

  get: (key) ->
    @_object?[key]

  set: (key, value) ->
    @_object ?= {}
    @_object[key] = value

  save: () ->
    if @isInserted() and @hasChange()
      @_collection.update @_object
    else
      @_object = {}
      @_collection.insert()

  delete: () ->
    unless @_deleted
      @_deleted = true
      @_collection.remove @_object

  isInserted: () -> if @_object?.meta? then yes else no

  isDeleted: () -> @_deleted

  hasChange: () -> @_needsUpdate

  @create: (base, context = ledger.db.contexts.main) ->
    new @ context, base

  @findById: (id, context = ledger.db.contexts.main) ->
    context.get id

  @findOrCreate: (id, base, context = ledger.db.contexts.main) ->
    object = @findById id
    object = @create base unless object?
    object

  @find: (query, context = ledger.db.contexts.main) ->
    chain = ledger.db.contexts.main.getCollection(@getCollectionName()).chain()
    chain.find(query) if query?
    chain

  @has: (relationship) ->

  @getCollectionName: () -> _.pluralize @name

  getCollectionName: () -> @constructor.getCollectionName()
