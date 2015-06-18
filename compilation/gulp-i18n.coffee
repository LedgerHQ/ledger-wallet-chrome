
through2 = require 'through2'

parsePropertiesFile = (fileContent) ->
  out = {}
  lines = fileContent.split '\n'
  for line in lines
    if match = line.match '([a-zA-Z0-9\._-]+)[ ]?=[ ]?(.*)'
      [__, key, value] = match
      out[key] = value
  out

i18n = () ->
  through2.obj (file, encoding, callback) ->
    i18nContent = {}

    content = parsePropertiesFile(file.contents.toString(encoding))
    for key, value of content
      key = key.replace(/\./g, '_')
      i18nContent[key] = {message: value.replace(/\\:/g, ':'), description: "Description for #{key}"}

    # Insert the newly created content
    file.contents = new Buffer(JSON.stringify(i18nContent), encoding)
    @push file
    callback()

buildLangFilePlugin = () ->
  through2.obj (chunk, encoding, callback) ->
    languages = {}

    tag = chunk.relative.substring(0, chunk.relative.indexOf("/"))
    langFile = parsePropertiesFile(chunk.contents.toString(encoding))
    languages = "window.ledger.i18n.Languages['" + tag + "'] = " + "'" + langFile['language.name'] + "';"

    chunk.contents = new Buffer(JSON.stringify(languages), encoding)

    @push chunk
    callback()

module.exports = {i18n, buildLangFilePlugin}