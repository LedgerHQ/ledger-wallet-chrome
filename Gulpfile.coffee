# Load all required libraries.
Q               = require 'q'
gulp            = require 'gulp'
less            = require 'gulp-less'
coffee          = require 'gulp-coffee'
yaml            = require 'gulp-yaml'
Yaml            = require 'js-yaml'
Eco             = require 'eco'
eco             = require 'gulp-eco'
del             = require 'del'
sourcemaps      = require 'gulp-sourcemaps'
uglify          = require 'gulp-uglify'
minifyCss       = require 'gulp-minify-css'
changed         = require 'gulp-changed'
plumber         = require 'gulp-plumber'
rename          = require 'gulp-rename'
through2        = require 'through2'
glob            = require 'glob'
fs              = require 'fs'
archiver        = require 'archiver'
zip             = archiver 'zip'
ChromeExtension = require 'crx'
path            = require 'path'
join            = path.join
resolve         = path.resolve
rsa             = require 'node-rsa'
_               = require 'underscore'
_.str           = require 'underscore.string'

class BuildMode
  constructor: (Name, BuildDir, MangleVersion) ->
    @Name = Name
    @BuildDir = BuildDir
    @MangleVersion = MangleVersion

DEBUG_MODE = new BuildMode('debug', 'build', yes)
RELEASE_MODE = new BuildMode('release', 'release', no)

COMPILATION_MODE = DEBUG_MODE

i18n = () ->
  through2.obj (file, encoding, callback) ->
    i18nContent = {}
    json = JSON.parse(file.contents.toString(encoding))
    json.application.name = "#{json.application.name} (#{COMPILATION_MODE.Name})" if COMPILATION_MODE.MangleVersion is true and json.application?.name?
    flatify = (json, path = '') ->
      for key, value of json
        if typeof value is "object"
          flatify(value, "#{path}#{key}_")
        else
          i18nContent[path + key] = {message: value, description: "Description for #{path + key} = #{value}"}

    flatify json
    file.contents = new Buffer(JSON.stringify(i18nContent), encoding)
    @push file
    callback()

releaseManifest = () ->
  through2.obj (file, encoding, callback) ->
    manifest = JSON.parse(file.contents.toString(encoding))
    if manifest.commands? and COMPILATION_MODE is RELEASE_MODE
      commands = {}
      for name, command of manifest.commands
        unless command.debug? is true
          commands[name] = command
      manifest.commands = commands
    file.contents = new Buffer(JSON.stringify(manifest), encoding)
    @push file
    callback()

ensureDirectoryExists = (dirname) ->
  unless fs.existsSync(join(__dirname, dirname))
    fs.mkdirSync join(__dirname, dirname), 0o766

ensureDistDir = () -> ensureDirectoryExists 'dist'

ensureSignatureDir = () -> ensureDirectoryExists('signature')

tasks =

  less: () ->
    gulp.src 'app/assets/css/**/*.less'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/assets/css"
    .pipe less()
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/assets/css"

  css: () ->
    gulp.src 'app/assets/css/**/*.css'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/assets/css"
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/assets/css"

  images: () ->
    gulp.src 'app/assets/images/**/*'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/assets/images"
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/assets/images"

  fonts: () ->
    gulp.src 'app/assets/fonts/**/*'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/assets/fonts"
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/assets/fonts"

  html: () ->
    gulp.src 'app/views/**/*.html'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/views"
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/views"

  eco: () ->
    gulp.src 'app/views/**/*.eco'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/views"
    .pipe eco({basePath: 'app/views/'})
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/views"

  manifest: () ->
    gulp.src 'app/manifest.yml'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/"
    .pipe yaml if COMPILATION_MODE is DEBUG_MODE then space: 1 else null
    .pipe releaseManifest()
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/"

  translate: () ->
    gulp.src 'app/locales/**/!(es)/*.yml'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/_locales"
    .pipe yaml()
    .pipe i18n()
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/_locales"

  js: () ->
    gulp.src 'app/**/*.js'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/"
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/"

  public: () ->
    gulp.src 'app/public/**/*'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/public"
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/public"

  coffee: () ->
    stream = gulp.src 'app/**/*.coffee'
    .pipe plumber()
    .pipe changed "#{COMPILATION_MODE.BuildDir}/"
    stream  = stream.pipe sourcemaps.init() if COMPILATION_MODE is DEBUG_MODE
    stream = stream.pipe coffee()
    stream = stream.pipe sourcemaps.write '/' if COMPILATION_MODE is DEBUG_MODE
    stream.pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/"

  finalize: () ->
    pattern = "#{COMPILATION_MODE.BuildDir}/**/*.#{COMPILATION_MODE.Name}.*"
    antiMode = if COMPILATION_MODE is DEBUG_MODE then RELEASE_MODE else DEBUG_MODE
    antipattern = "#{COMPILATION_MODE.BuildDir}/**/*.#{antiMode.Name}.*"
    del.sync [antipattern]
    gulp.src [pattern, "!#{COMPILATION_MODE.BuildDir}/**/*.map"]
    .pipe rename (path) ->
      {basename} = path
      basename = basename.slice(0, basename.lastIndexOf(".#{COMPILATION_MODE.Name}"))
      path.basename = basename
      path
    .pipe gulp.dest "#{COMPILATION_MODE.BuildDir}/"

  minify: () ->
    gulp.src "#{COMPILATION_MODE.BuildDir}/**/*.css"
    .pipe minifyCss()
    .pipe gulp.dest("#{COMPILATION_MODE.BuildDir}/")

  uglify: () ->
    gulp.src "#{COMPILATION_MODE.BuildDir}/**/*.js"
    .pipe uglify mangle: false
    .pipe gulp.dest("#{COMPILATION_MODE.BuildDir}/")

  promisify: (stream) ->
    promise = Q.defer()
    stream.on 'finish', promise.resolve
    promise.promise

  compile: () ->
    promise = Q.defer()
    run = [
      tasks.js
      tasks.coffee
      tasks.public
      tasks.translate
      tasks.manifest
      tasks.eco
      tasks.images
      tasks.fonts
      tasks.html
      tasks.less
    ]
    run = (tasks.promisify(task()) for task in run)
    Q.all(run).then ->
      tasks.promisify(tasks.finalize()).then ->
        if COMPILATION_MODE is DEBUG_MODE then promise.resolve()
        else
          Q.all([tasks.promisify(tasks.minify())]).then(promise.resolve)

  createFupManifest: () ->
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

gulp.task 'doc', (cb) ->
  {exec} = require 'child_process'
  child = exec './node_modules/.bin/codo -v app/src/', {}, () ->
    do cb
  child.stdin.pipe process.stdin
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr

gulp.task 'clean', (cb) ->
  del ['build/', 'release/'], cb

gulp.task 'watch', ['debug'], ->
  COMPILATION_MODE = DEBUG_MODE
  gulp.watch('app/**/*', ['compile'])

# Default task call every tasks created so far.

gulp.task 'compile', ->
  tasks.compile()

gulp.task 'default', ['debug']

gulp.task 'debug:clean', (cb) ->
  del.sync ['build/']
  do cb

gulp.task 'release:clean', (cb) ->
  del.sync ['release/']
  do cb

gulp.task 'clean', ['debug:clean', 'release:clean']

gulp.task 'debug', ['debug:clean'], ->
  COMPILATION_MODE = DEBUG_MODE
  tasks.compile()

gulp.task 'release', ['release:clean'], ->
  COMPILATION_MODE = RELEASE_MODE
  tasks.compile()

gulp.task 'fup:manifest', ->
  tasks.createFupManifest()

gulp.task 'zip', ['release'], ->
  ensureDistDir()
  manifest = require './release/manifest.json'
  output = fs.createWriteStream "dist/SNAPSHOT-#{manifest.version}.zip"
  zip.pipe output
  zip.bulk [expand: true, cwd: 'release', src: ['**']]
  zip.finalize()

keygen = (dir) ->
  dir = resolve __dirname, dir
  keyPath = join dir, "key.pem"
  unless fs.existsSync keyPath
    key = new rsa b: 1024
    fs.writeFileSync keyPath, key.exportKey('pkcs1-private-pem')
  keyPath

gulp.task 'package', ['release'], ->
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
      manifest = require './release/manifest.json'
      fs.writeFileSync("dist/ledger-wallet-#{manifest.version}.crx", crxBuffer)
      crx.destroy()
