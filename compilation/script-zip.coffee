
archiver = require 'archiver'
zip = archiver 'zip'
fs = require 'fs'
{ensureDistDir} = require './utils'

module.exports = (configuration) ->
  ensureDistDir()
  manifest = require "../#{configuration.buildDir}/manifest.json"
  output = fs.createWriteStream "dist/SNAPSHOT-#{manifest.version}.zip"
  zip.pipe output
  zip.bulk [expand: true, cwd: configuration.buildDir, src: ['**']]
  zip.finalize()