try
  importScripts(
    '../../../libs/underscore-min.js'
    '../../../libs/underscore.string.min.js'
    '../../../libs/btchip/lib/q.js'
    '../../../src/utils/defer.js'
  )
catch er
  console.error er
  return


fsmode = null

getFs = ->
  getFs._fs ||= webkitRequestFileSystemSync fsmode, 5 * 1024 * 1024


###
checkDate: ->
  d = ledger.defer()
  @listDir.then (files) =>
    loopFiles = (index, files, defer) =>
      file = (files || [])[index]
      return defer.resolve() unless file?
      filedate = file.name.substr(-14, 10)
      ms = moment(moment().format('YYYY-MM-DD')).diff moment(_.str.dasherize(filedate))
      days = moment.duration(ms).days()
      months = moment.duration(ms).months()
      years = moment.duration(ms).years()
      #l 'days: ', days, 'months: ', months, 'years: ', years
      if days > @_daysMax or months > 0 or years > 0
        @delete file.name
        .then ->
          loopFiles index + 1, files, defer
      else
        loopFiles index + 1, files, defer
    loopFiles 0, files, d
  d.promise
###


Commands =

  write: (msg) ->
    @_getFileWriter (fileWriter) =>
      fileWriter.onwriteend = (e) ->
        #l "Write completed"
        fileWriter.seek(fileWriter.length)
        d.resolve()
      fileWriter.onerror = (e) ->
        e "Write failed"
        e arguments
        d.resolve()
      blob = new Blob(@_blobArr, {type:'text/plain'})
      @_blobArr = []
      fileWriter.write(blob)


  read: ->
    res = []
    @checkDate()
    dirReader = getFs().root.createReader()
    for file in dirReader.readEntries()
      if @_isFileOfMine(file.name)
        reader = new FileReader()
        reader.onloadend = -> res.push(_.compact reader.result.split('\n'))
        reader.readAsText(file.file)
    _.flatten res



  ###
    Get the fileWriter, create a new one if it doesn't exist yet
    @param [function] callback Callback function to get the fileWriter
  ###
  _getFileWriter: (callback) ->
    unless @_writer?.date is moment().format('YYYY-MM-DD')
      fileEntry = getFs().root.getFile @_getFileName(), {create: true}
      fileWriter = fileEntry.createWriter()
      fileWriter.seek(fileWriter.length)
      @_writer = {date: moment().format('YYYY-MM-DD'), writer: fileWriter}
      @_writer.writer



  releaseFs: ->

  readDir: (dirPath) ->
    dirReader = getFs().root.getDirectory(dirPath, {create: false})
    paths = []
    entries = dirReader.readEntries()
    for entry in entries
      paths.push entry.toURL()
    paths


  openFile: ->
    getFs().root.getFile @_getFileName(), {create: false}


  ###
    Set file name with bitIdAdress and date of the day
  ###
  _getFileName: ->
    "non_secure_#{ moment().format('YYYY_MM_DD') }.log"


  removeFile: (filename) ->
    fileEntry = getFs().root.getFile filename, {create: false}
    fileEntry.remove()
    yes


  removeDir: (dirPath) ->
    dirReader = getFs().root.getDirectory(dirPath, {create: false})
    dirReader.removeRecursively()
    yes

###
  Receive all messages and execute methods
###
@onmessage = (event) ->
  {command, id, parameters} = event.data
  if command is 'setFsMode'
    fsmode = event.data.fsmode
    return
  throw new Error 'Fsmode is not initialized' unless fsmode?
  if (commandHandler = Commands[command])?
    try
      postMessage id: id, command: command, result:  commandHandler(parameters...)
    catch error
      postMessage id: id, command: command, error: error