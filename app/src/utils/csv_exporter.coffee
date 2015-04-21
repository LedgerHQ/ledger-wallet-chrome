
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
    completion = new CompletionClosure(callback)
    @_performSave(completion)
    completion

    completion.readonly()

  _performSave: (completion) ->
    chrome.fileSystem.chooseEntry
      type: 'saveFile'
      suggestedName: "#{@_defaultFileName}.csv"
      accepts: [{mimeTypes: ['text/csv']}]
    , (entry) =>
      if !entry? or entry.length is 0
        chrome.runtime.lastError
        completion.failure(new ledger.StandardError(ledger.errors.OperationCanceledError))
      else
        entry.createWriter (writer) =>
          try
            writer.onerror = =>
              chrome.runtime.lastError
              completion.failure(new ledger.StandardError(ledger.errors.WriteError))
            writer.onwriteend = -> completion.success(this)
            fileContent = (if @_headerLine? then [@_headerLine].concat(@_lines) else @_lines).join("\n")
            writer.write new Blob([fileContent], type: "text/csv")
          catch er
            chrome.runtime.lastError
            completion.failure(new ledger.StandardError(ledger.errors.WriteError))
        , =>
          chrome.runtime.lastError
          completion.failure(new ledger.StandardError(ledger.errors.WriteError))

  url: ->
    fileContent = (if @_headerLine? then [@_headerLine].concat(@_lines) else @_lines).join("\n")
    blob = new Blob([fileContent], type: 'text/csv;charset=utf8;')
    URL.createObjectURL(blob)