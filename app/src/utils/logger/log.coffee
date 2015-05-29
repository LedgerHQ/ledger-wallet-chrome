
@ledger ?= {}
@ledger.utils ?= {}

deferedGetFs = {}
globalFs = {}

getFs = (fsmode) ->
  return ledger.defer().resolve(globalFs[fsmode]).promise if globalFs[fsmode]?
  return deferedGetFs[fsmode].promise if deferedGetFs[fsmode]?
  deferedGetFs[fsmode] = ledger.defer()
  window.webkitRequestFileSystem fsmode, 5*1024*1024,
    (fs) ->
      globalFs[fsmode] = fs
      deferedGetFs[fsmode].resolve fs
  , (e) -> deferedGetFs[fsmode].reject(e)
  deferedGetFs[fsmode].promise


releaseFs = ->
  deferedGetFs = {}
  globalFs = {}


class @ledger.utils.Log

  ###
    Constructor
    @param [Number] _daysMax The maximum number of days the logs are preserved
  ###
  constructor: (daysMax = 2, fsmode = PERSISTENT) ->
    throw new Error 'Abstract class' if @constructor is ledger.utils.Log
    @_fsmode = fsmode
    @_daysMax = daysMax
    @_daysMax = parseInt(@_daysMax)
    unlockWriter = _.lock @, ['_getFileWriter', 'write', 'read']
    if isNaN @_daysMax
      throw 'The first parameter must be a number'
    getFs(fsmode)
    .then (fs) =>
      @_fs = fs
      @checkDate(fsmode) # Delete old log files
      .then -> unlockWriter()
      .done()
    .fail (e) =>
      @_errorHandler(e)
    .done()


  checkDate: (fsmode) ->
    d = ledger.defer()
    @constructor.listDirFiles fsmode, (files) =>
      loopFiles = (index, files, defer) =>
        file = (files || [])[index]
        return defer.resolve() unless file?
        filedate = file.name.substr(-14, 10)
        ms = moment(moment().format('YYYY-MM-DD')).diff moment(_.str.dasherize(filedate))
        days   = moment.duration(ms).days()
        months = moment.duration(ms).months()
        years = moment.duration(ms).years()
        #l 'days: ', days, 'months: ', months, 'years: ', years
        if days > @_daysMax or months > 0 or years > 0
          @constructor.delete fsmode, file.name, ->
            loopFiles index + 1, files, defer
        else
          loopFiles index + 1, files, defer
      loopFiles 0, files, d
    d.promise


  ###
    Delete a file
    @param [String] filename The name of the file
  ###
  @delete: (fsmode, filename, callback=undefined) ->
    l 'delete'
    getFs(fsmode).then (fs) =>
      fs.root.getFile filename, {create: false}, (fileEntry) =>
        fileEntry.remove ->
          callback?()
      , (e) =>
        l "FileSystem Error. name: #{e.name} // message: #{e.message}"
        l new Error().stack
        callback?()


  ###
    Delete all files in the root directory
  ###
  @deleteAll: (fsmode=PERSISTENT, callback=undefined) ->
    getFs(fsmode).then (fs) =>
      dirReader = fs.root.createReader()
      dirReader.readEntries (results) =>
        return callback?() if results.length is 0
        _.async.each results, (entry, next, hasNext) =>
          return unless entry?.name?
          @delete fsmode, entry.name, =>
            unless hasNext
              callback?()
              return
            do next
      , (e) =>
        l "FileSystem Error. name: #{e.name} // message: #{e.message}"
        l new Error().stack
        callback?()



  ###
    List files in the root directory
    @param [function] callback Callback function to handle an array of file entries
  ###
  @listDirFiles: (fsmode, callback) ->
    getFs(fsmode).then (fs) =>
      dirReader = fs.root.createReader()
      entries = []
      dirReader.readEntries (results) ->
        for entry in results
          entries.push entry
        entries = entries.sort()
        #l 'entries', entries
        callback? entries
      , (e) =>
        @_errorHandler(e)
        callback?()


  @getFs: getFs

  @releaseFs: releaseFs


  _errorHandler: (e) ->
    l "FileSystem Error. name: #{e.name} // message: #{e.message}"
    l new Error().stack