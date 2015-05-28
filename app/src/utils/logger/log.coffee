
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
    @_daysMax = daysMax
    @_daysMax = parseInt(@_daysMax)
    unlockWriter = _.lock @, ['_getFileWriter', 'write', 'read', 'deleteAll', 'delete']
    if isNaN @_daysMax
      throw 'The first parameter must be a number'
    getFs(fsmode)
    .then (fs) =>
      @_fs = fs
      @_setFileName()
      # Delete old log files
      @listDirFiles (files) =>
        unless _(files).isEmpty()
          for file in files
            filedate = file.name.substr(-14, 10)
            ms = moment(moment().format('YYYY-MM-DD')).diff moment(_.str.dasherize(filedate))
            days   = moment.duration(ms).days()
            months = moment.duration(ms).months()
            years = moment.duration(ms).years()
            # l 'days: ', days, 'months: ', months, 'years: ', years
            if days > @_daysMax or months > 0 or years > 0
              @delete file.name
            # l 'days: ', days, 'months: ', months, 'years: ', years
        unlockWriter()
    .fail (e) =>
      @_errorHandler(e)
    .done()


  ###
    Delete a file
    @param [String] filename The name of the file
  ###
  delete: (filename, callback=undefined) ->
    l 'before DELETE'
    @_fs.root.getFile filename, {create: false}, (fileEntry) =>
      l 'DURING DELETE'
      fileEntry.remove ->
        l 'AFTER DELETE'
        callback?()
    , (e) =>
      l 'AFTER DELETE'
      @_errorHandler(e)
      callback?()


  ###
    Delete all files in the root directory
  ###
  deleteAll: (callback=undefined) ->
    dirReader = @_fs.root.createReader()
    dirReader.readEntries (results) =>
      return callback?() if results.length is 0
      _.async.each results, (entry, next, hasNext) =>
        return unless entry?.name?
        @delete entry.name, =>
          unless hasNext
            callback?()
            return
          do next
    , (e) =>
      @_errorHandler(e)
      callback?()



  ###
    List files in the root directory
    @param [function] callback Callback function to handle an array of file entries
  ###
  listDirFiles: (callback) ->
    dirReader = @_fs.root.createReader()
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


  getFs: getFs

  releaseFs: releaseFs


  _errorHandler: (e) ->
    l "FileSystem Error. name: #{e.name} // message: #{e.message}"
    l new Error().stack