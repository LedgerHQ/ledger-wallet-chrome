
resolveRelationship = (object, relationship) ->
  Class = window[relationship.Class]
  switch relationship.type
    when 'many_one'
      object._collection.getRelationshipView(object, relationship).data()
    when 'one_many'
      Class.get "#{relationship.name}_id"
    when 'one_one'
      Class.get "#{relationship.name}_id"
    when 'many_many'
      object._collection.getRelationshipView(object, relationship).data()


class @Model extends @EventEmitter

  constructor: (context, base) ->
    throw 'Model can not be build without a context' unless context?
    @_context = context
    @_collection = context.getCollection(@getCollectionName())
    @_object = base
    @_needsUpdate = if @isInserted() then no else yes
    @_deleted = no

  get: (key) ->
    if @getRelationships()?[key]?
      return e "Not inserted object should not be able to get relationship, please fix this" unless @isInserted()
      relationship = @getRelationships()[key]
      resolveRelationship(@, relationship)
    else
      @_object?[key]

  getId: () -> @_object?['id']

  set: (key, value) ->
    @_object ?= {}
    if @getRelationships()?[key]?
      return e "Not inserted object should not be able to set up relationship, please fix this" unless @isInserted()
      relationship = @getRelationships()[key]

    else
      @_object[key] = value
    @_needsUpdate = yes

  remove: (key, value) ->

  add: (key, value) ->

  save: () ->
    if @isInserted() and @hasChange()
      @_collection.update @_object
    else
      @_object ?= {}
      @_collection.insert()
      @_needsUpdate = no

  delete: () ->
    unless @_deleted
      @_deleted = true
      @_collection.remove @_object

  isInserted: () -> if @_object?.meta? then yes else no

  isDeleted: () -> @_deleted

  hasChange: () -> @_needsUpdate

  getRelationships: () -> @constructor._relationships

  @create: (base, context = ledger.db.contexts.main) -> new @ context, base

  @findById: (id, context = ledger.db.contexts.main) -> context.getCollection(@getCollectionName()).get(id)

  @findOrCreate: (id, base, context = ledger.db.contexts.main) ->
    object = @findById id, context
    object = @create base, context unless object?
    object

  @find: (query, context = ledger.db.contexts.main) ->
    chain = context.getCollection(@getCollectionName()).query()
    chain.find(query) if query?
    chain

  # Relationship creator
  @has: (relationshipDeclaration) ->
    if relationshipDeclaration['many']?
      @_createRelationship(relationshipDeclaration, 'many')
    else if relationshipDeclaration['one']
      @_createRelationship(relationshipDeclaration, 'one')

  @_createRelationship: (relationshipDeclaration, myType) ->
    r = if _.isArray(relationshipDeclaration['many']) then relationshipDeclaration['many'] else [relationshipDeclaration['many'], _.str.capitalize(_.singularize(relationshipDeclaration['many']))]
    if relationshipDeclaration['forOne']?
      i = [relationshipDeclaration['forOne'], 'one']
    else if relationshipDeclaration['forMany']?
      i =  [relationshipDeclaration['forMany'], 'many']
    else
      i = [@name.toLocaleLowerCase(), 'one']
    sort = null
    if relationshipDeclaration['sortBy']?
      sort = relationshipDeclaration['sortBy']
      sort = [sort, false] unless _.isArray(sort)
    onDelete = 'nullify' unless relationshipDeclaration['onDelete']?
    relationship = name: r[0], type: "#{myType}_#{i[1]}", inverse: i[0], Class: r[1], inverseType: "#{i[1]}_#{myType}", sort: sort, onDelete: onDelete
    @_relationships ?= {}
    @_relationships[relationship.name] = relationship

  @commitRelationship: () ->
    throw 'This methods should only be called once by Model' unless @ is Model
    # Ensure all relationships are bound and consistent between models (each relationship are sets in both directions)
    for ClassName, Class of @AllModelClasses()
      for relationshipName, relationship of Class._relationships
        InverseClass = window[relationship.Class]
        if InverseClass._relationships? and InverseClass._relationships[relationship.inverse]?.inverse is relationship.name and InverseClass._relationships[relationship.inverse]?.type is relationship.inverseType and InverseClass._relationships[relationship.inverse]?.Class is ClassName
          continue
        else if not InverseClass._relationships?[relationship.inverse]
          InverseClass._relationships ?= {}
          InverseClass._relationships[relationship.inverse] = name: relationship.inverse, type: relationship.inverseType, inverse:relationship.name, Class: ClassName, inverseType: relationship.type
        else
          e "Bad relationship #{relationship.name} <-> #{relationship.inverse}. You must absolutely check for errors for classes #{ClassName} and #{relationship.Class}"

  @index: (field) ->
    @_indexes ?= []
    @_indexes.push field

  @init: () ->
    Model._allModelClasses ?= {}
    Model._allModelClasses[@name] = @

  @getCollectionName: () -> @name

  getCollectionName: () -> @constructor.getCollectionName()

  @AllModelClasses: () -> @_allModelClasses