
ledger.database ||= {}

class ledger.database.DatabasePersistenceAdapter

  constructor: (dbName, password) ->
    @_dbName = dbName
    @_password = password
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

  stop: -> @_worker.terminate()

  _postCommand: (command) ->
    @_prepare().then =>
      @_postCommandToWorker(command)
    .fail (er) =>
      e er

  _postCommandToWorker: (command) ->
    queryId = _.uniqueId()
    command['queryId'] = queryId
    defer = ledger.defer()
    @_pendingCommands[queryId] = defer
    @_worker.postMessage JSON.parse(JSON.stringify(command))
    defer.promise

  _prepare: () ->
    unless @_deferredPreparation?
      @_deferredPreparation = ledger.defer()
      @_deferredPreparation.resolve(@_postCommandToWorker(command: 'prepare', dbName: @_dbName, password: @_password))
    @_deferredPreparation.promise
