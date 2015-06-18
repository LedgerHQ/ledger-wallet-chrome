
glob = require 'glob'
_ = require 'underscore'
_.str = require 'underscore.string'
fs = require 'fs'
Q = require 'q'
Yaml = require 'js-yaml'
Eco = require 'eco'

createFupManifest = () ->
  getVersionFromDotNotation =  (dotNotation) -> dotNotation.replace(/\./g, '')
  varify = (name, src) -> name + "_" + (/[a-z-]+-([0-9]+)/).exec(src)[1]
  getVersionFromVarName = (name) -> (/[A-Za-z_]+([0-9]+)/).exec(name)[1]
  normalizeVersion = (src) -> src.substring(0, 3) + _.str.lpad(src.substring(3), 3, '0')
  expressionFromNormalizedVersion = (src) ->
    parts = [src.substr(0, 1), src.substr(1, 1), src.substr(2, 1), parseInt(src.substring(3))]
    first = if parts[0] is '1' then '0x20' else '0x00'
    "[#{first}, (#{parts[1]} << 16) + (#{parts[2]} << 8) + (#{parts[3]})]"
  expressionFromDotNotation = (src) ->
    parts = []
    loop
      index = src.indexOf('.')
      parts.push src.substring(0, index)
      src = src.substring(index + 1)
      break if src.indexOf('.') is -1
    parts.push src
    first = if parts[0] is '1' then '0x20' else '0x00'
    "[#{first}, (#{parts[1]} << 16) + (#{parts[2]} << 8) + (#{parts[3]})]"

  l = console.log.bind(console)
  deferred = Q.defer()
  glob 'app/firmwares/*.js', {}, (er, files) ->
    template = fs.readFileSync 'compilation/fup_manifest.coffee.template', "utf-8"
    imports = []
    names = []
    for file in files
      localFile = file.substring(4).replace('.js', '')
      imports.push "'../#{localFile}'"
      names.push localFile.replace("firmwares/btchipfirmware-", '')
    names = _.groupBy names, (name) -> (/([a-z-]+)-[0-9]+/).exec(name)[1]

    reloader_from_bl = (varify('BL_RELOADER', e) for e in names['reloader-from-loader'])
    reloader_from_bl = _.sortBy reloader_from_bl, (varName) -> normalizeVersion(getVersionFromVarName(varName))

    bl_loader = (varify('BL_LOADER', e) for e in names['loader-from-loader'])
    bl_loader = _.sortBy bl_loader, (varName) -> normalizeVersion(getVersionFromVarName(varName))

    os_loader = (varify('LOADER', e) for e in names['loader'])
    os_loader = _.sortBy os_loader, (varName) -> normalizeVersion(getVersionFromVarName(varName))

    bl_reloader = []
    for e in names['reloader']
      varName = varify('RELOADER', e)
      bl_reloader.push [expressionFromNormalizedVersion(normalizeVersion(getVersionFromVarName(varName))), varName]
    bl_reloader = _.sortBy bl_reloader, (entry) -> normalizeVersion(getVersionFromVarName(entry[1]))

    os_init = []
    for e in names['init']
      varName = varify((if getVersionFromVarName(varify('VOID', e))[0] is '0' then 'INIT' else 'INIT_LW'), e)
      os_init.push [expressionFromNormalizedVersion(normalizeVersion(getVersionFromVarName(varName))), varName]
    os_init = _.sortBy os_init, (entry) -> normalizeVersion(getVersionFromVarName(entry[1]))

    manifest = Yaml.safeLoad(fs.readFileSync('app/firmwares/manifest.yml', 'utf8'))

    manifest['current_version']['bootloader'] = expressionFromDotNotation(manifest['current_version']['bootloader'])
    manifest['current_version']['os'] = expressionFromDotNotation(manifest['current_version']['os'])
    manifest['current_version']['reloader'] = expressionFromDotNotation(manifest['current_version']['reloader'])

    file = Eco.render template, imports: imports, reloader_from_bl: reloader_from_bl, bl_loader: bl_loader, os_loader: os_loader, bl_reloader: bl_reloader, os_init: os_init, manifest: manifest
    fs.writeFile 'app/src/fup/firmwares_manifest.coffee', file, -> deferred.resolve()
    return
  deferred.promise

module.exports = (configuration) ->
  Q.all [
    createFupManifest()
  ]