
build = require './script-build'
archiver = require 'archiver'
zip = archiver 'zip'
fs = require 'fs'
{ensureDistDir, ensureSignatureDir} = require './utils'
ChromeExtension = require 'crx'
rsa             = require 'node-rsa'
path            = require 'path'
join            = path.join
resolve         = path.resolve
Q = require 'Q'

keygen = (dir) ->
  dir = resolve __dirname, dir
  keyPath = join dir, "key.pem"
  unless fs.existsSync keyPath
    key = new rsa b: 1024
    fs.writeFileSync keyPath, key.exportKey('pkcs1-private-pem')
  keyPath

buildAndPackage = (configuration) ->
  build(configuration).then ->
    buildAndPackage.package(configuration)

buildAndPackage.package = (configuration) ->
  defer = Q.defer()
  ensureDistDir()
  ensureSignatureDir()
  crx = new ChromeExtension(rootDirectory: 'release')
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
      crx.destroy()
      defer.resolve()
  defer.promise

module.exports = buildAndPackage