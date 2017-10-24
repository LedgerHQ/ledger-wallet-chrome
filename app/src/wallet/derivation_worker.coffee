try
  importScripts(
      '../utils/logger.js'
      '../../libs/btchip/lib/q.js'
      '../../libs/bitcoinjs-min.js'
      '../../libs/btchip/lib/bitcoinjs-min.js'
      'extended_public_key.js'
      '../../libs/btchip/lib/inheritance.js'
      '../../libs/btchip/lib/BitcoinExternal.js'
      '../../libs/btchip/btchip-js-api/ByteString.js'
      '../../libs/btchip/btchip-js-api/Convert.js'
      '../../libs/btchip/btchip-js-api/GlobalConstants.js'
      '../../libs/btchip/ucrypt/JSUCrypt.js'
      '../../libs/btchip/ucrypt/helpers.js'
      '../../libs/btchip/ucrypt/hash.js'
      '../../libs/btchip/ucrypt/sha256.js'
      '../../libs/btchip/ucrypt/ripemd160.js'
      '../../libs/underscore-min.js'
      '../../libs/underscore.string.min.js'
      '../utils/object.js'
      '../utils/amount.js'
      '../bitcoin/networks.js'
      '../build.js'
      '../configuration.js'
  )
catch er
  console.error er
  return

LastQueryId = 0x8000000
QueryHandlers = []
ExtendedPublicKeys = {}

Queue = []
LockQueue = no
CurrentCommand = null

ledger.app ?= {}
ledger.wallet ?= {}
ledger.wallet.Wallet ?= {}
ledger.wallet.Wallet.instance ?= {}

enqueue = (command, parameters, queryId) ->
  Queue.push command: command, parameters: parameters, queryId: queryId

postResult = (result) ->
  postMessage command: CurrentCommand.command, result: result, queryId: CurrentCommand.queryId
  CurrentCommand = null
  LockQueue = no
  dequeue()

postError = (error) ->
  postMessage command: CurrentCommand.command, error: error, queryId: CurrentCommand.queryId
  CurrentCommand = null
  LockQueue = no
  dequeue()

sendCommand = (command, parameters, callback) ->
  queryId = LastQueryId++
  QueryHandlers.push id: queryId, callback: callback
  postMessage command: command, parameters: parameters, queryId: queryId

class WorkerWallet

  ledger.app.dongle = new @

  getPublicAddress: (path, callback) ->
    sendCommand 'private:getPublicAddress', [path], (result, error) =>
      if result?
        result.publicKey = new ByteString(result.publicKey, HEX)
        result.bitcoinAddress = new ByteString(result.bitcoinAddress, HEX)
        result.chainCode = new ByteString(result.chainCode, HEX)
      callback?(result, error)


class WorkerCache

  ledger.wallet.Wallet.instance.cache = new @

  get: () -> null

  set: (entries, callback = _.noop) ->
    sendCommand 'private:setCacheEntries', [entries], (result, error) =>
      callback?(result, error)

setNetwork = (networkName) ->
  ledger.config.network = _(ledger.bitcoin.Networks).find((item) => item.name is networkName)
  postResult yes

registerExtendedPublicKeyForPath = (path) ->
  if ExtendedPublicKeys[path]?
    postResult 'Already registered'
    return
  sendCommand 'private:getXpubFromCache', [path], (xpu58, error) =>
    ExtendedPublicKeys[path] = new ledger.wallet.ExtendedPublicKey(ledger.app.dongle, path)
    # xpu58 = {
    #   "49'/0'/0'": "xpub6C5Wnmut8VuqtkzDUVNiHYK7mb4Y4c8Z3PyqpTFoYRYtcDhF8N9DepXoP2dtSsohSAW9oAU4fmmctnq4jxB6j3nF7cdUguEFgPzQoTwsX3T"
    # }[path]
    if xpu58?
      ExtendedPublicKeys[path].initializeWithBase58(xpu58)
      postResult 'registered'
    else
      ExtendedPublicKeys[path].initialize (xpub) =>
        entry = [path, ExtendedPublicKeys[path].toString()]
        sendCommand 'private:setXpubCacheEntries', [[entry]], _.noop
        if xpub? then postResult 'registered' else postError 'Xpub creation error'

getPublicAddress = (path) ->
  address = null
  # Try to use a xpub
  for parentDerivationPath, xpub of ExtendedPublicKeys
    derivationPath = path
    if _.str.startsWith(derivationPath, "#{parentDerivationPath}/")
      derivationPath = derivationPath.replace("#{parentDerivationPath}/", '')
      address =  xpub.getPublicAddress(derivationPath)
      postResult address
      return

  # No result from cache perform the derivation on the chip
  unless address?
    console.warn "Trying to derive with dongle ", path
    ledger.app.dongle.getPublicAddress path, (publicKey) ->
      @_derivationPath
      if publicKey?
       address = publicKey?.bitcoinAddress?.value
      if address?
        postResult address
      else
        postError "Unable to derive path '#{path}'"

@onmessage = (event) =>
  {command, parameters, queryId} = event.data
  if queryId?
    for index in [0...QueryHandlers.length]
      queryHandler = QueryHandlers[index]
      if queryHandler.id is queryId
        QueryHandlers.splice(index, 1)
        queryHandler.callback.apply(command, [event.data['result'], event.data['error']])
        return

  if command is 'private:unlockQueue'
    LockQueue = no
    postError('Unknown Error') if CurrentCommand?
    dequeue()
    return
  enqueue(command, parameters, queryId)
  dequeue()

dequeue = () ->
  return if LockQueue or Queue.length is 0
  LockQueue = yes
  CurrentCommand = Queue.splice(0, 1)[0]
  {command, parameters} = CurrentCommand
  switch command
    when 'public:registerExtendedPublicKeyForPath' then registerExtendedPublicKeyForPath.apply(command, parameters)
    when 'public:setNetwork' then setNetwork.apply(command, parameters)
    when 'public:getPublicAddress' then getPublicAddress.apply(command, parameters)
    else LockQueue = no
