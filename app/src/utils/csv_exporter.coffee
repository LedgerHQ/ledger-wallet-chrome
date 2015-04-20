
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

  ###
    Pushes a line in the file content

    @param [Array[Any]] line A line
  ###
  pushLine: (line) ->

  ###
    Sets the header line of the file content
  ###
  setHeaderLine: () ->

  save: (callback = undefined ) ->
    completion = new CompletionClosure(callback)
    chrome.fileSystem.chooseEntry
      type: 'saveFile'
      suggestedName: "#{@_defaultFileName}.csv"
      accepts: ['text/csv', '*.csv']
      acceptsAllTypes: no
      acceptsMultiple:no
    , (entry) -> entry.createWriter (writer) ->
        writer.onerror = -> completion.failure(new ledger.StandardError(ledger.errors.WriteError))
        writer.onwriteend = -> completion.success(this)
        writer.write # TODO: Blob
    completion.readonly()