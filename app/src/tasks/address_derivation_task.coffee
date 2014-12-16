class ledger.tasks.AddressDerivationTask extends ledger.tasks.Task

  constructor: () -> super 'global_address_derivation'

  @instance: new @()

  onStart: () ->
    @_worker = new Worker('../src/wallet/derivation_worker.js')
    @_vents = new EventEmitter()

    @_worker.onmessage = (event) =>
      l 'Task', event
      {queryId, command, result, parameters, error} = event.data
      @_vents.emit "#{command}::#{queryId}", {result: result, error: error, parameters: parameters}
      @_vents.emit "#{command}", {result: result, error: error, queryId, parameters: parameters}

    @_worker.onerror = (event) =>
      e event
      {queryId, command, result, error} = event.data
      @_vents.emit "#{command}::#{queryId}", {result: result, error: error}
      @_worker.postMessage command: 'private:unlockQueue'
      event.preventDefault()

    @on 'private:getPublicAddress', (ev, data) =>
      l data

  onStop: () ->
    @_worker.terminate()

  registerExtendedPublicKeyForPath: (path, callback) ->
    @_postCommand 'public:registerExtendedPublicKeyForPath', [path], (data) =>
      callback?()

  getPublicAddress: (path, callback) ->
    @_postCommand 'public:registerExtendedPublicKeyForPath', [path], (data) =>
      callback?()

  _postCommand: (command, parameters, callback) ->
    queryId = _.uniqueId()
    @once "#{command}::#{queryId}", (ev, data) =>
      callback? data
    @_worker.postMessage {command: command, parameters: parameters, queryId: queryId}
    queryId

  @reset: () -> @instance = new @()