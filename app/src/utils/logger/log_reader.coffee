
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.LogReader extends @ledger.utils.Log

  constructor: (daysMax = 2, fsmode = PERSISTENT) ->
    super @_daysMax, fsmode



  ###
    Read a file
    @param [String] filename The name of the file
    @return [Text] A text file at a time
  ###
  read: (callback) ->
    res = []
    last = ->
      callback? _.flatten res
    dirReader = @_fs.root.createReader()
    dirReader.readEntries (results) =>
      done = _.after results.length, last
      for entry, i in results
        do (entry) =>
          if @_isFileOfMine(entry.name)
            entry.file (file) ->
              reader = new FileReader()
              reader.onloadend = (e) ->
                res.push(_.compact reader.result.split('\n'))
                done()
              reader.readAsText(file)
          else
            done()
    , (e) =>
      @_errorHandler(e)
      callback?()


  _isFileOfMine: (name) ->
    regex = "non_secure_[\\d]{4}_[\\d]{2}_[\\d]{2}\\.log"
    name.match new RegExp(regex)



  ###
  Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
      @_filename = "non_secure_#{ moment().format('YYYY_MM_DD') }.log"