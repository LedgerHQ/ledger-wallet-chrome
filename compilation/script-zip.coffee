
build = require './script-build'
archiver = require 'archiver'
zip = archiver 'zip'

module.exports = (configuration) ->
  build(configuration).then ->
    ensureDistDir()
    manifest = require './release/manifest.json'
    output = fs.createWriteStream "dist/SNAPSHOT-#{manifest.version}.zip"
    zip.pipe output
    zip.bulk [expand: true, cwd: 'release', src: ['**']]
    zip.finalize()