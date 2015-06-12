WorkerProxies = []

onWorkerMessage = (event) ->
  for proxy in WorkerProxies
    return if proxy.handleWorkerMessage(event.data)
  ledger.utils.Logger.getLoggerByTag('Html5FSWorkerProxy').warn('unhandled message', event.data)


onWorkerError = (e) ->
  ledger.utils.Logger.getLoggerByTag('Html5FSWorkerProxy').error(e.message+'\nLine: '+e.lineno+'\nFilename: '+e.filename)
  e.preventDefault()
  delete getWorker._worker


getWorker = (fsmode) ->
  unless getWorker._worker?
    getWorker._workers ||= new Worker('../src/utils/logger/html5FS_worker.js')
    getWorker.postMessage command: 'setFsMode', fsmode: fsmode
    getWorker._workers[fsmode].onmessage = onWorkerMessage
    getWorker._workers[fsmode].onerror = onWorkerError
  getWorker._workers[fsmode]


ledger.utils ?= {}
ledger.utils.logger ?= {}


class FileProxy

  length: undefined

  constructor: (@proxy, @fileId) ->


  sendMessage: ->


  seek: ->

  close: ->



class ledger.utils.logger.Html5FSWorkerProxy

  constructor: (fsmode) ->
    @fsmode = fsmode
    WorkerProxies.push(@)
    l WorkerProxies
    @_id = _.uniqueId()
    @_deferedRequests = {}


  ###
    resolve message if it is its own
  ###
  handleWorkerMessage: (req) ->
    if (defer = @_deferedRequests[req.id])?
      if req.result?
       defer.resolve(req.result)
      else
        defer.reject(req.error)
      yes
    else
      no



  openFile: -> @_sendMessage 'openFile'

  readDir: (dirPath) -> @_sendMessage 'readDir', dirPath

  removeFile: -> @_sendMessage 'removeFile'

  removeDir: (dirPath) -> @_sendMessage 'removeDir', dirPath

  releaseProxy: -> WorkerProxies[@] = {}



  ###
    Format message and save defer
  ###
  _sendMessage: (command, parameters...) ->
    d = ledger.defer()
    message = id: _.uniqueId(), command: command, parameters: parameters
    @_deferedRequests[message.id] = d
    getWorker().postMessage(message)
    d.promise





