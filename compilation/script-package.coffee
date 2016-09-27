
archiver = require 'archiver'
zip = archiver 'zip'
fs = require 'fs'
{ensureDistDir, ensureSignatureDir} = require './utils'
ChromeExtension = require 'crx'
rsa             = require 'node-rsa'
path            = require 'path'
join            = path.join
resolve         = path.resolve
Q = require 'q'

keygen = (dir) ->
  dir = resolve dir
  keyPath = join dir, "key.pem"
  unless fs.existsSync keyPath
    key = new rsa b: 1024
    fs.writeFileSync keyPath, key.exportKey('pkcs1-private-pem')
  keyPath

module.exports = (configuration) ->
  defer = Q.defer()
  ensureDistDir()
  ensureSignatureDir()
  crx = new ChromeExtension(rootDirectory: configuration.buildDir)
  keypath = keygen('signature/')
  fs.readFile keypath, (err, data) ->
    crx.privateKey = data
    crx.load()
    .then ->
      crx.loadContents()
    .then (archiveBuffer) ->
      crx.pack archiveBuffer
    .then (crxBuffer) ->
      manifest = require "../#{configuration.buildDir}/manifest.json"
      fs.writeFileSync("dist/ledger-wallet-#{manifest.version}.crx", crxBuffer)
      defer.resolve()
      crx.destroy()
      return
  defer.promise
