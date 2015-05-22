
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.LogWriter extends @ledger.utils.Log

  constructor: (@_daysMax = 2) ->
    super @_daysMax


  ###
    Write a log file per day
    @param [String] msg The log message to write
  ###
  write: (msg) ->
    @_getFileWriter (fileWriter) ->
      fileWriter.onwriteend = (e) ->
        l "Write completed"
      fileWriter.onerror = (e) ->
        l "Write failed"
      blob = new Blob(['\n' + msg], {type:'text/plain'})
      fileWriter.seek(fileWriter.length)
      fileWriter.write(blob)



  ###
    Get the fileWriter, create a new one if it doesn't exist yet
    @param [function] callback Callback function to get the fileWriter
  ###
  _getFileWriter: (callback) ->
    unless @_writer?.date is moment().format('YYYY-MM-DD')
      l 'Create new fileWriter'
      @_fs.root.getFile @_filename, {create: true}, (fileEntry) =>
        # Create a FileWriter object for our FileEntry
        fileEntry.createWriter (fileWriter) =>
          @_writer = {date: moment().format('YYYY-MM-DD'), writer: fileWriter}
          callback? @_writer.writer
        , @_errorHandler
      , @_errorHandler
    else
      callback? @_writer.writer


  ###
   Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
    ledger.bitcoin.bitid.getAddress (address) =>
      bitIdAddress = address.bitcoinAddress.toString(ASCII)
      @_filename = "#{bitIdAddress}_#{ moment().format('YYYY_MM_DD') }.log"