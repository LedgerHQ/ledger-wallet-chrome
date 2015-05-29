
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.LogReader extends @ledger.utils.Log

  constructor: (daysMax = 2, fsmode = PERSISTENT) ->
    @_setFileName()
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
    @checkDate(@_fsmode).then =>
      dirReader = @_fs.root.createReader()
      dirReader.readEntries (files) =>
        loopFiles = (index, files) =>
          file = (files || [])[index]
          return last() unless file?
          if @_isFileOfMine(file.name)
            file.file (file) ->
              reader = new FileReader()
              reader.onloadend = (e) ->
                res.push(_.compact reader.result.split('\n'))
                loopFiles index + 1, files
              reader.readAsText(file)
          else
            loopFiles index + 1, files
        loopFiles 0, files
    .done()


  _isFileOfMine: (name) ->
    regex = "non_secure_[\\d]{4}_[\\d]{2}_[\\d]{2}\\.log"
    name.match new RegExp(regex)



  ###
  Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
      @_filename = "non_secure_#{ moment().format('YYYY_MM_DD') }.log"