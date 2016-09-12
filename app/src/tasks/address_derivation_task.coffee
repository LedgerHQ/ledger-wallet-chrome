class ledger.tasks.AddressDerivationTask extends ledger.tasks.Task

  constructor: () ->
    super 'global_address_derivation'
    @_readyPromise = ledger.defer()

  @instance: new @()

  onStart: () ->
    @_worker = new Worker('../src/wallet/derivation_worker.js')
    @_vents = new EventEmitter()

    @_worker.onmessage = (event) =>
      {queryId, command, result, parameters, error} = event.data
      @_vents.emit "#{command}::#{queryId}", {result: result, error: error, parameters: parameters}
      @_vents.emit "#{command}", {result: result, error: error, queryId, parameters: parameters}

    @_worker.onerror = (event) =>
      e event
      @_worker.postMessage command: 'private:unlockQueue'
      event.preventDefault()

    @_vents.on 'private:getPublicAddress', (ev, data) =>
      ledger.app.dongle.getPublicAddress data['parameters'][0], (result, error) =>
        {command, queryId} = data
        if result?
          result.publicKey = result.publicKey.toString(HEX)
          result.bitcoinAddress = result.bitcoinAddress.toString(HEX)
          result.chainCode = result.chainCode.toString(HEX)
        @_worker.postMessage command: command, queryId: queryId, result: result, error: error?.message

    @_vents.on 'private:setCacheEntries', (ev, data) =>
      {command, queryId, parameters} = data
      ledger.wallet.Wallet.instance?.cache?.set parameters[0]
      @_worker.postMessage command: command, queryId: queryId, result: 'success', error: undefined

    @_vents.on 'private:getXpubFromCache', (ev, data) =>
      {command, queryId, parameters} = data
      xpub = ledger.wallet.Wallet.instance?.xpubCache.get parameters[0]
      @_worker.postMessage command: command, queryId: queryId, result: xpub, error: undefined

    @_vents.on 'private:setXpubCacheEntries', (ev, data) =>
      {command, queryId, parameters} = data
      ledger.wallet.Wallet.instance?.xpubCache.set parameters[0]
      @_worker.postMessage command: command, queryId: queryId, result: 'success', error: undefined

    @_readyPromise.resolve()

  onStop: () ->
    @_worker.terminate()

  registerExtendedPublicKeyForPath: (path, callback) ->
    @_postCommand 'public:registerExtendedPublicKeyForPath', [path], (data) =>
      callback?(data.result, data.error)

  getPublicAddress: (path, callback) ->
    @_postCommand 'public:getPublicAddress', [path], (data) =>
      callback?(data.result, data.error)

  setNetwork: (networkName) ->
    @_postCommand 'public:setNetwork', [networkName], (data) =>
      callback?(data.result, data.error)

  _postCommand: (command, parameters, callback) ->
    queryId = _.uniqueId()
    @_ready().then =>
      @_vents.once "#{command}::#{queryId}", (ev, data) =>
        callback? data
      @_worker.postMessage {command: command, parameters: parameters, queryId: queryId}
    queryId

  _ready: () -> @_readyPromise.promise

  @reset: () -> @instance = new @()