importScripts '../utils/log.js', '../../libs/bitcoinjs-min.js', 'extended_public_key.js', '../../libs/lw-api-js/lib/inheritance.js', '../../libs/lw-api-js/btchip-js-api/ByteString.js',  '../../libs/lw-api-js/btchip-js-api/Convert.js', '../../libs/underscore-min.js'

LastQueryId = 0
QueryHandlers = []
ExtendedPublicKeys = {}

Queue = []
LockQueue = no
CurrentCommand = null

enqueue = (command, parameters, queryId) ->
  Queue.push command: command, parameters: parameters, queryId: queryId

dequeue = () ->

postResult = (result) ->
  postMessage command: CurrentCommand.command, result: result, queryId: CurrentCommand.queryId
  CurrentCommand = null
  dequeue()

postError = (error) ->
  postMessage command: CurrentCommand.command, error: error, queryId: CurrentCommand.queryId
  CurrentCommand = null
  dequeue()

sendCommand = (command, parameters, callback) ->
  queryId = LastQueryId++
  QueryHandlers.push id: queryId, callback: callback
  postMessage command: command, parameters: parameters, queryId: queryId

class WorkerWallet

  getPublicAddress: (path, callback) ->
    sendCommand 'private:getPublicAddress', [path], (result, error) ->
      result.publicKey = new ByteString(result.publicKey, HEX)
      result.bitcoinAddress = new ByteString(result.bitcoinAddress, HEX)
      result.chainCode = new ByteString(result.chainCodem HEX)
      callback?(result, error)

registerExtendedPublicKeyForPath = (path) ->
  return if ExtendedPublicKeys[path]?
  l 'Register XPUB'
  postResult 'Hello from worker'

getPublicAddress = (path) ->


@onmessage = (event) =>
  {command, parameters, queryId} = event.data

  if queryId?
    for index in [0...QueryHandlers.length]
      queryHandler = QueryHandlers[index]
      if queryHandler.id is queryId
        QueryHandlers.splice(index, 1)
        queryHandler.callback.apply(command, parameters)
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