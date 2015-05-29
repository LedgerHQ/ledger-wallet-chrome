
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.LogWriter extends @ledger.utils.Log

  constructor: (daysMax = 2, fsmode = PERSISTENT) ->
    super @_daysMax, fsmode


  write: (msg) ->
    if @_deferedWrite? and @_deferedWrite.isPending()
      @_deferedWrite = @_deferedWrite.then =>
        @_write msg
    else
      @_deferedWrite = @_write(msg)
    return @_deferedWrite


  ###
    Write a log file per day
    @param [String] msg The log message to write
  ###
  _write: (msg) ->
    d = ledger.defer()
    @_getFileWriter (fileWriter) ->
      fileWriter.onwriteend = (e) ->
        #l "Write completed"
        fileWriter.seek(fileWriter.length)
        d.resolve()
      fileWriter.onerror = (e) ->
        e "Write failed"
        e arguments
        d.resolve()
      blob = new Blob(['\n' + msg], {type:'text/plain'})
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