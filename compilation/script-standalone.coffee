NwBuilder = require 'nw-builder'
fs = require 'fs'
Q = require 'q'
ncp = require 'ncp'
rimraf = require 'rimraf'

manifest = require '../build/manifest.json'

setup = (arch, configuration) ->
  d = Q.defer()
  fs.mkdirSync("standalone_build")
  ncp 'build', "./standalone_build/build", (err) ->
    d.reject err if err?

    package_json = {
      "name": "ledger-wallet",
      "version": manifest.version,
      "main": "./build/views/layout.html",
      "window": {
        "title": "Ledger Wallet",
        "toolbar": configuration.mode is 'debug',
        "width": 1000,
        "height": 640,
        "min_width": 1000,
        "min_height": 640
      }
    }
    fs.writeFile "./standalone_build/package.json", JSON.stringify(package_json), (err) ->
      d.reject err if err?

      ncp "compilation/prebuild/#{arch}", "./standalone_build/node_modules", (err) ->
        d.reject err if err?
        d.resolve()
  d.promise


buildApp = (arch, configuration) ->
  nw = new NwBuilder
    files: ["./standalone_build/**/**"]
    platforms: [arch]
    buildDir: './dist/'
    buildType: 'versioned'
  nw.build()

clean = (arch, configuration) ->
  d = Q.defer()
  rimraf 'standalone_build', -> d.resolve()
  d.promise

buildForArchs = (configuration, archs = ['win32', 'win64', 'linux32', 'linux64', 'osx64'], index = 0) ->
  return if index >= archs.length
  console.log 'Building packaged application for', archs[index]
  arch = archs[index]
  clean(arch, configuration)
  .then -> setup(arch, configuration)
  .then -> buildApp(arch, configuration)
  .finally ->
    clean(arch, configuration).finally -> buildForArchs(configuration, archs, index + 1)

module.exports = (configuration) ->
  buildForArchs(configuration)

