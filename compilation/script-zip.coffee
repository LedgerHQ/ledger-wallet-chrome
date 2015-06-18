
build = require './script-build'
archiver = require 'archiver'
zip = archiver 'zip'
fs = require 'fs'
{ensureDistDir} = require './utils'

buildAndZip = (configuration) ->
  build(configuration).then ->
    buildAndZip.zip(configuration)

buildAndZip.zip = (configuration) ->
  ensureDistDir()
  manifest = require "../#{configuration.buildDir}/manifest.json"
  output = fs.createWriteStream "dist/SNAPSHOT-#{manifest.version}.zip"
  zip.pipe output
  zip.bulk [expand: true, cwd: 'release', src: ['**']]
  zip.finalize()

module.exports = buildAndZip