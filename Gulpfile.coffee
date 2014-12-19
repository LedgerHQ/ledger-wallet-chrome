# Load all required libraries.
Q           = require 'q'
gulp        = require 'gulp'
less        = require 'gulp-less'
coffee      = require 'gulp-coffee'
yaml        = require 'gulp-yaml'
eco         = require 'gulp-eco'
del         = require 'del'
sourcemaps  = require 'gulp-sourcemaps'
uglify      = require 'gulp-uglify'
minifyCss   = require 'gulp-minify-css'
changed     = require 'gulp-changed'
plumber     = require 'gulp-plumber'
through2    = require 'through2'
glob        = require 'glob'
fs          = require 'fs'
archiver    = require 'archiver'
zip         = archiver 'zip'

i18n = () ->
  through2.obj (file, encoding, callback) ->
    i18nContent = {}
    json = JSON.parse(file.contents.toString(encoding))
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

completeBuildTask = (mode) ->
  anti_mode = if mode is DEBUG_MODE then RELEASE_MODE else DEBUG_MODE
  glob "#{mode.BuildDir}/**/*.#{anti_mode.Name}.js", (er, files) ->
    for file in files
      del file
  glob "#{mode.BuildDir}/**/*.#{mode.Name}.js", (er, files) ->
    for file in files
      path = file.split '/'
      [newFilename] = path.splice -1, 1
      newFilename = path.join('/') + "/" + newFilename.slice(0, newFilename.lastIndexOf(".#{mode.Name}.js")) + ".js"
      fs.renameSync file, newFilename

class BuildMode
  constructor: (@Name, @BuildDir) ->

DEBUG_MODE = new BuildMode('debug', 'build')
RELEASE_MODE = new BuildMode('release', 'release')

COMPILATION_MODE = DEBUG_MODE

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
    .pipe changed 'build/assets/css'
    .pipe gulp.dest 'build/assets/css'

  images: () ->
    gulp.src 'app/assets/images/**/*'
    .pipe plumber()
    .pipe changed 'build/assets/images/'
    .pipe gulp.dest 'build/assets/images/'

  fonts: () ->
    gulp.src 'app/assets/fonts/**/*'
    .pipe plumber()
    .pipe changed 'build/assets/fonts/'
    .pipe gulp.dest 'build/assets/fonts/'

  html: () ->
    gulp.src 'app/views/**/*.html'
    .pipe plumber()
    .pipe changed 'build/views'
    .pipe gulp.dest 'build/views'

  eco: () ->
    gulp.src 'app/views/**/*.eco'
    .pipe plumber()
    .pipe changed 'build/views'
    .pipe eco({basePath: 'app/views/'})
    .pipe gulp.dest 'build/views'

  yml: () ->
    gulp.src 'app/manifest.yml'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe yaml()
    .pipe releaseManifest()
    .pipe gulp.dest 'build/'

  translate: () ->
    gulp.src 'app/locales/**/*.yml'
    .pipe plumber()
    .pipe changed 'build/_locales/'
    .pipe yaml()
    .pipe i18n()
    .pipe gulp.dest 'build/_locales/'

  js: () ->
    gulp.src 'app/**/*.js'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe gulp.dest 'build/'

  public: () ->
    gulp.src 'app/public/**/*'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe gulp.dest 'build/public'

  coffee: () ->
    gulp.src 'app/**/*.coffee'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe sourcemaps.write '/'
    .pipe gulp.dest 'build/'

  compile: () ->
    promise = Q.defer()
    run = [
      tasks.js()
      tasks.coffee()
      tasks.public()
      tasks.translate()
      tasks.yml()
      tasks.eco()
      tasks.images()
      tasks.fonts()
      tasks.html()
      tasks.less()
    ]
    Q.all.apply(Q, run).then promise.resolve
    promise.promise


gulp.task 'doc', (cb) ->
  {exec} = require 'child_process'
  child = exec './node_modules/.bin/codo -v app/src/', {}, () ->
    do cb
  child.stdin.pipe process.stdin
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr

gulp.task 'clean', (cb) ->
  del ['build/', 'release/'], cb

gulp.task 'watch', ['compile'], ->
  gulp.watch('app/**/*', ['watch-debug'])


# Default task call every tasks created so far.

gulp.task 'compile', ->
  tasks.compile()

gulp.task 'default', ['compile']

gulp.task 'clean', ['compile:clean', 'release:clean']

gulp.task 'debug', ['clean'], ->
  COMPILATION_MODE = DEBUG_MODE
  tasks.compile()

gulp.task 'release',  ->
  COMPILATION_MODE = RELEASE_MODE
  tasks.compile()

gulp.task 'package', ['release'], ->
  setTimeout ->
    manifest = require './release/manifest.json'
    output = fs.createWriteStream "SNAPSHOT-#{manifest.version}.zip"
    zip.pipe output
    zip.bulk [expand: true, cwd: 'release', src: ['**']]
    zip.finalize()
  , 1000


