# Load all required libraries.
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
    if manifest.commands?
      commands = {}
      for name, command of manifest.commands
        unless command.debug? is true
          commands[name] = command
      manifest.commands = commands
    file.contents = new Buffer(JSON.stringify(manifest), encoding)
    @push file
    callback()

completeBuildTask = (dir, mode) ->
  anti_mode = if mode is DEBUG_MODE then RELEASE_MODE else DEBUG_MODE
  glob "#{dir}/**/*.#{anti_mode}.js", (er, files) ->
    for file in files
      del file
  glob "#{dir}/**/*.#{mode}.js", (er, files) ->
    for file in files
      path = file.split '/'
      [newFilename] = path.splice -1, 1
      newFilename = path.join('/') + "/" + newFilename.slice(0, newFilename.lastIndexOf(".#{mode}.js")) + ".js"
      fs.renameSync file, newFilename

DEBUG_MODE = 'debug'
RELEASE_MODE = 'release'

COMPILATION_MODE = DEBUG_MODE

gulp.task 'less', ['compile:clean'], ->
  gulp.src 'app/assets/css/**/*.less'
    .pipe plumber()
    .pipe changed 'build/assets/css'
    .pipe less()
    .pipe gulp.dest 'build/assets/css'

gulp.task 'css', ['compile:clean'], ->
  gulp.src 'app/assets/css/**/*.css'
    .pipe plumber()
    .pipe changed 'build/assets/css'
    .pipe gulp.dest 'build/assets/css'

gulp.task 'images', ['compile:clean'], ->
  gulp.src 'app/assets/images/**/*'
    .pipe plumber()
    .pipe changed 'build/assets/images/'
    .pipe gulp.dest 'build/assets/images/'

gulp.task 'fonts', ['compile:clean'], ->
  gulp.src 'app/assets/fonts/**/*'
  .pipe plumber()
  .pipe changed 'build/assets/fonts/'
  .pipe gulp.dest 'build/assets/fonts/'

gulp.task 'html', ['compile:clean'], ->
  gulp.src 'app/views/**/*.html'
    .pipe plumber()
    .pipe changed 'build/views'
    .pipe gulp.dest 'build/views'

gulp.task 'eco', ['compile:clean'], ->
  gulp.src 'app/views/**/*.eco'
    .pipe plumber()
    .pipe changed 'build/views'
    .pipe eco({basePath: 'app/views/'})
    .pipe gulp.dest 'build/views'

gulp.task 'yml', ['compile:clean'], ->
  gulp.src 'app/manifest.yml'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe yaml()
    .pipe gulp.dest 'build/'

gulp.task 'translate', ['compile:clean'], ->
  gulp.src 'app/locales/**/*.yml'
    .pipe plumber()
    .pipe changed 'build/_locales/'
    .pipe yaml()
    .pipe i18n()
    .pipe gulp.dest 'build/_locales/'

gulp.task 'js', ['compile:clean'], ->
  gulp.src 'app/**/*.js'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe gulp.dest 'build/'

gulp.task 'public', ['compile:clean'], ->
  gulp.src 'app/public/**/*'
  .pipe plumber()
    .pipe changed 'build/'
      .pipe gulp.dest 'build/public'

gulp.task 'coffee-script', ['compile:clean'], ->
  gulp.src 'app/**/*.coffee'
    .pipe plumber()
    .pipe changed 'build/'
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe sourcemaps.write '/'
    .pipe gulp.dest 'build/'

gulp.task 'doc', (cb) ->
  {exec} = require 'child_process'
  child = exec './node_modules/.bin/codo -v app/src/', {}, () ->
    do cb
  child.stdin.pipe process.stdin
  child.stdout.pipe process.stdout
  child.stderr.pipe process.stderr

gulp.task 'compile:clean', (cb) ->
  del ['build/'], cb

gulp.task 'release:clean', (cb) ->
  del ['release/'], cb

gulp.task 'release:uglify', ['compile:sources', 'release:clean'],  ->
  gulp.src 'build/src/**/*.js'
    .pipe gulp.dest 'release/src/'

gulp.task 'release:minify', ['compile:assets', 'release:clean'],  ->
  gulp.src 'build/**/*.css'
    .pipe minifyCss()
    .pipe gulp.dest 'release/'

gulp.task 'release:images', ['compile:assets', 'release:clean'], ->
  gulp.src 'build/assets/images/**/*'
    .pipe gulp.dest 'release/assets/images'

gulp.task 'release:fonts', ['compile:assets', 'release:clean'], ->
  gulp.src 'build/assets/fonts/**/*'
  .pipe gulp.dest 'release/assets/fonts'

gulp.task 'release:json', ['compile:assets', 'release:clean'], ->
  gulp.src 'build/**/*.json'
    .pipe gulp.dest 'release/'

gulp.task 'release:libs', ['compile:sources', 'release:clean'], ->
  gulp.src 'build/libs/**/*.js'
    .pipe gulp.dest 'release/libs/'

gulp.task 'release:views', ['compile:assets', 'release:clean'], ->
  gulp.src 'build/views/**/*'
    .pipe gulp.dest 'release/views/'

gulp.task 'release:public', ['public', 'release:clean'], ->
  gulp.src 'build/public/**/*'
  .pipe plumber()
    .pipe changed 'release/'
      .pipe gulp.dest 'release/public'

gulp.task 'release:manifest', ['compile:assets', 'release:clean', 'release:json'], ->
  gulp.src 'app/manifest.yml'
  .pipe yaml()
  .pipe releaseManifest()
  .pipe gulp.dest 'release/'

gulp.task 'watch', ['compile'], ->
  gulp.watch('app/**/*', ['watch-debug'])


# Default task call every tasks created so far.
gulp.task 'compile:assets', ['less', 'css', 'eco', 'html', 'yml', 'images', 'fonts', 'translate', 'public']
gulp.task 'compile:sources', ['js', 'coffee-script']
gulp.task 'compile', ['compile:clean', 'compile:assets', 'compile:sources']
gulp.task 'default', ['debug']

gulp.task 'clean', ['compile:clean', 'release:clean']

gulp.task 'debug', ['compile'], ->
  completeBuildTask 'build', DEBUG_MODE

gulp.task 'debug', ['compile:assets', 'compile:sources'], ->
  completeBuildTask 'build', DEBUG_MODE

gulp.task 'release', ['release:clean', 'release:uglify', 'release:minify', 'release:json', 'release:libs', 'release:images', 'release:views', 'release:public', 'release:manifest', 'release:fonts', 'compile'],  ->
  completeBuildTask 'release', RELEASE_MODE

gulp.task 'package', ['release'], ->
  setTimeout ->
    manifest = require './release/manifest.json'
    output = fs.createWriteStream "SNAPSHOT-#{manifest.version}.zip"
    zip.pipe output
    zip.bulk [expand: true, cwd: 'release', src: ['**']]
    zip.finalize()
  , 1000


