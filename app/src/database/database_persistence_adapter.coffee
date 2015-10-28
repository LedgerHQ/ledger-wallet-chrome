
ledger.database ||= {}

class ledger.database.DatabasePersistenceAdapter

  constructor: (dbName) ->
    @_dbName = dbName
    @_pendingCommands = {}
    @_worker = new Worker('../src/database/database_persistence_worker.js')
    @_worker.onmessage = (message) =>
      {queryId, result, error} = message.data
      deferred = @_pendingCommands[queryId]
      @_pendingCommands = _(@_pendingCommands).omit(queryId)
      if error?
        deferred.reject(error)
      else
        deferred.resolve(result)

    @_worker.onerror = (error) =>
      e error
      error.preventDefault()

    @_ready = no
    @_prepare()

  declare: (collection) -> @_postCommand(command: 'declare', collection: collection)

  delete: () -> @_postCommand(command: 'delete')

  saveChanges: (changes) -> @_postCommand(command: 'changes', changes: changes)

  serialize: () -> @_postCommand(command: 'serialize')

  _postCommand: (command) ->
    @_prepare().then => @_postCommandToWorker(command)

  _postCommandToWorker: (command) ->
    queryId = _.uniqueId()
    defer = ledger.defer()
    @_pendingCommands[queryId] = defer
    @_worker.postMessage {command: command, parameters: parameters, queryId: queryId}
    defer.promise

  _prepare: () ->
    unless @_deferredPreparation?
      @_deferredPreparation = ledger.defer()
      @_deferredPreparation.resolve(@_postCommandToWorker(command: 'prepare', dbName: @_dbName))
    @_deferredPreparation.promise