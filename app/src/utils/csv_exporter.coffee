
ledger.utils ?= {}

###
  Utility class for creating and exporting CSV files.

  Note: Only the save call will persist the data on disk. Any other methods will only update a content buffer
###
class ledger.utils.CsvExporter

  ###
    @param [String] The default filename without the extension.
  ###
  constructor: (defaultFileName) ->
    @_defaultFileName = defaultFileName
    @_content = []

  ###
    Sets file content. The content is represented as an array of objects. The keys of the first are used as the header line.

    @param [Array<Object>] content An array of object used as content.
  ###
  setContent: (content) ->
    for line, index  in content
      @setHeaderLine(_.keys(line)) if index is 0
      @pushLine(_.values(line))

  ###
    Pushes a line in the file content

    @param [Array[Any]] line A line
  ###
  pushLine: (line) -> (@_lines ||= []).push line.join ','

  ###
    Sets the header line of the file content
  ###
  setHeaderLine: (line) -> @_headerLine = line.join ','

  save: (callback = undefined) ->
    deferred = ledger.defer(callback)
    @_performSave(deferred)
    deferred.promise

  _performSave: (deferred) ->
    chrome.fileSystem.chooseEntry
      type: 'saveFile'
      suggestedName: "#{@_defaultFileName}.csv"
      accepts: [{mimeTypes: ['text/csv']}]
    , (entry) =>
      if !entry? or entry.length is 0
        chrome.runtime.lastError
        deferred.rejectWithError(ledger.errors.OperationCanceledError)
      else
        entry.createWriter (writer) =>
          try
            writer.onerror = =>
              chrome.runtime.lastError
              deferred.rejectWithError(ledger.errors.WriteError)
            writer.onwriteend = -> deferred.resolve(this)
            fileContent = (if @_headerLine? then [@_headerLine].concat(@_lines) else @_lines).join("\n")
            writer.write new Blob([fileContent], type: "text/csv")
          catch er
            chrome.runtime.lastError
            deferred.rejectWithError(ledger.errors.WriteError)
        , =>
          chrome.runtime.lastError
          deferred.rejectWithError(ledger.errors.WriteError)

  url: -> URL.createObjectURL(@blob())

  blob: ->
    fileContent = (if @_headerLine? then [@_headerLine].concat(@_lines) else @_lines).join("\n")
    new Blob([fileContent], type: 'text/csv;charset=utf8;')

  zip: (callback) ->
    suggestedName = "#{@_defaultFileName}.csv"
    # use a zip.BlobWriter object to write zipped data into a Blob object
    zip.createWriter new zip.BlobWriter("application/zip"), (zipWriter) =>
      # use a BlobReader object to read the data stored into blob variable
      zipWriter.add suggestedName, new zip.BlobReader(@blob()), =>
        # close the writer and calls callback function
        zipWriter.close(callback)
    , (e) =>
      callback?(null)