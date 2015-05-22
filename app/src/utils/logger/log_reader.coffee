
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.LogReader extends @ledger.utils.Log

  constructor: (@_daysMax = 2) ->
    super @_daysMax



  ###
    Read a file
    @param [String] filename The name of the file
    @return [Text] A text file at a time
  ###
  read: (callback) ->
    dirReader = @_fs.root.createReader()
    dirReader.readEntries (results) =>
      for entry in results
        if @_isFileOfMine(entry.name)
          entry.file (file) ->
            reader = new FileReader()
            reader.onloadend = (e) ->
              #l 'Result: ', @result
              callback? @result
            reader.readAsText(file)
    , @_errorHandler



  _isFileOfMine: (name) ->
    regex = /^[0-9a-zA-Z]{33}_[\d]{4}_[\d]{2}_[\d]{2}\.log$/
    if name.match(regex)? then true else false


  ###
  Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
    ledger.bitcoin.bitid.getAddress (address) =>
      bitIdAddress = address.bitcoinAddress.toString(ASCII)
      @_filename = "#{bitIdAddress}_#{ moment().format('YYYY_MM_DD') }.log"