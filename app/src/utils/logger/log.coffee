
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.Log

  ###
    Constructor
    @param [Number] _daysMax The maximum number of days the logs are preserved
  ###
  constructor: (daysMax = 2) ->
    @_daysMax = daysMax
    @_daysMax = parseInt(@_daysMax)
    unlockWriter = _.lock @, ['_getFileWriter', 'write', 'read']
    if isNaN @_daysMax
      throw 'The first parameter must be a number'
    _init = (fs) =>
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
    window.webkitRequestFileSystem window.PERSISTENT, 5*1024*1024, _init, @_errorHandler



  ###
    Delete a file
    @param [String] filename The name of the file
  ###
  delete: (filename) ->
    @_fs.root.getFile filename, {create: true}, (fileEntry) =>
      fileEntry.remove (v) -> l v, @_errorHandler



  ###
    Delete all files in the root directory
  ###
  deleteAll: ->
    dirReader = @_fs.root.createReader()
    dirReader.readEntries (results) =>
      for entry in results
        @delete entry.name
    , @_errorHandler



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
    , @_errorHandler



  _errorHandler: (e) ->
    l "FileSystem Error. name: #{e.name} // message: #{e.message}"