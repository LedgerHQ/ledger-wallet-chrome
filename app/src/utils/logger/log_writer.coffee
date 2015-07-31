
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.LogWriter extends @ledger.utils.Log

  constructor: (daysMax = 2, fsmode = PERSISTENT) ->
    @_blobArr = []
    @_flush = ledger.utils.promise.throttle @_flush.bind(@), 2000
    super @_daysMax, fsmode

  ###
    Write a log file per day
    @param [String] msg The log message to write
  ###
  write: (msg) ->
    @_blobArr.push('\n' + msg)
    #@_flushPromise = @_flush()
    return

  ###
  ###
  getFlushPromise: ->
    @_flushPromise

  ###
  ###
  _flush: ->
    d = ledger.defer()
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
    return d.promise


  ###
    Get the fileWriter, create a new one if it doesn't exist yet
    @param [function] callback Callback function to get the fileWriter
  ###
  _getFileWriter: (callback) ->
    unless @_writer?.date is moment().format('YYYY-MM-DD')
      #l 'Create new fileWriter'
      @_fs.root.getFile @_getFileName(), {create: true}, (fileEntry) =>
        # Create a FileWriter object for our FileEntry
        fileEntry.createWriter (fileWriter) =>
          fileWriter.seek(fileWriter.length)
          @_writer = {date: moment().format('YYYY-MM-DD'), writer: fileWriter}
          callback? @_writer.writer
        , (e) =>
          @_errorHandler(e)
          callback?()
      , (e) =>
        @_errorHandler(e)
        callback?()
    else
      callback? @_writer.writer



  ###
    Set file name with bitIdAdress and date of the day
  ###
  _getFileName: ->
    "non_secure_#{ moment().format('YYYY_MM_DD') }.log"