try
  importScripts(
      '../../libs/bitcoinjs-min.js'
      '../../libs/lw-api-js/lib/bitcoinjs-min.js'
      'extended_public_key.js'
      '../../libs/lw-api-js/lib/inheritance.js'
      '../../libs/lw-api-js/lib/BitcoinExternal.js'
      '../../libs/lw-api-js/btchip-js-api/ByteString.js'
      '../../libs/lw-api-js/btchip-js-api/Convert.js'
      '../../libs/lw-api-js/btchip-js-api/GlobalConstants.js'
      '../../libs/lw-api-js/ucrypt/JSUCrypt.js'
      '../../libs/lw-api-js/ucrypt/helpers.js'
      '../../libs/lw-api-js/ucrypt/hash.js'
      '../../libs/lw-api-js/ucrypt/sha256.js'
      '../../libs/lw-api-js/ucrypt/ripemd160.js'
      '../../libs/underscore-min.js'
      '../../libs/underscore.string.min.js'
      '../utils/object.js'
      'value.js'
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
ledger.wallet.HDWallet ?= {}
ledger.wallet.HDWallet.instance ?= {}

enqueue = (command, parameters, queryId) ->
  Queue.push command: command, parameters: parameters, queryId: queryId

dequeue = () ->

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

  ledger.wallet.HDWallet.instance.cache = new @

  get: () -> null

  set: (entries, callback = _.noop) ->
    sendCommand 'private:setCacheEntries', [entries], (result, error) =>
      callback?(result, error)

registerExtendedPublicKeyForPath = (path) ->
  if ExtendedPublicKeys[path]?
    postResult 'Already registered'
    return
  ExtendedPublicKeys[path] = new ledger.wallet.ExtendedPublicKey(ledger.app.dongle, path)
  ExtendedPublicKeys[path].initialize (xpub) =>
    if xpub?
      postResult 'registered'
    else
      postError 'XPub creation error'

getPublicAddress = (path) ->
  address = null
  # Try to use a xpub
  for parentDerivationPath, xpub of ExtendedPublicKeys
    derivationPath = path
    if _.str.startsWith(derivationPath, "#{parentDerivationPath}/")
      derivationPath = derivationPath.replace("#{parentDerivationPath}/", '')
      address =  xpub.getPublicAddress(derivationPath)
      break

  # No result from cache perform the derivation on the chip
  unless address?
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
    when 'public:getPublicAddress' then getPublicAddress.apply(command, parameters)
    else LockQueue = no