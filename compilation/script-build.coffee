gulp  = require 'gulp'

# Load all required libraries.
Q               = require 'q'

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
path            = require 'path'
join            = path.join
resolve         = path.resolve
rsa             = require 'node-rsa'
concat          = require 'gulp-concat'
tap             = require 'gulp-tap'
_               = require 'underscore'
_.str           = require 'underscore.string'
ext_replace     = require 'gulp-ext-replace'
flavors         = require './gulp-flavors'

module.exports = (configuration) ->

  console.log(configuration)

  tasks =

    less: () ->
      gulp.src 'app/assets/css/**/*.less'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/assets/css"
      .pipe less()
      .pipe gulp.dest "#{configuration.buildDir}/assets/css"

    css: () ->
      gulp.src 'app/assets/css/**/*.css'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/assets/css"
      .pipe gulp.dest "#{configuration.buildDir}/assets/css"

    images: () ->
      gulp.src 'app/assets/images/**/*'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/assets/images"
      .pipe gulp.dest "#{configuration.buildDir}/assets/images"

    fonts: () ->
      gulp.src 'app/assets/fonts/**/*'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/assets/fonts"
      .pipe gulp.dest "#{configuration.buildDir}/assets/fonts"

    html: () ->
      gulp.src 'app/views/**/*.html'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/views"
      .pipe gulp.dest "#{configuration.buildDir}/views"

    eco: () ->
      gulp.src 'app/views/**/*.eco'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/views"
      .pipe eco({basePath: 'app/views/'})
      .pipe gulp.dest "#{configuration.buildDir}/views"

    manifest: () ->
      gulp.src 'app/manifest.yml'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/"
      .pipe yaml if configuration.mode is 'debug' then space: 1 else null
      .pipe releaseManifest()
      .pipe gulp.dest "#{configuration.buildDir}/"

    translate: () ->
      gulp.src 'app/locales/**/!(es)/*.properties'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/_locales"
      .pipe i18n()
      .pipe ext_replace('.json')
      .pipe gulp.dest "#{configuration.buildDir}/_locales"

    buildLangFile: () ->
      gulp.src 'app/locales/**/!(es)/*.properties'
      .pipe plumber()
      .pipe buildLangFilePlugin()
      .pipe tap (file, t) ->
        file.contents = new Buffer file.contents.toString().replace(/^"|"$/g, '')
      .pipe concat 'i18n_languages.js'
      .pipe gulp.dest "#{configuration.buildDir}/src/i18n"

    regions: () ->
      gulp.src 'app/src/i18n/regions.yml'
      .pipe yaml()
      .pipe gulp.dest "#{configuration.buildDir}/src/i18n"

    js: () ->
      gulp.src 'app/**/*.js'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/"
      .pipe gulp.dest "#{configuration.buildDir}/"

    public: () ->
      gulp.src 'app/public/**/*'
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/public"
      .pipe gulp.dest "#{configuration.buildDir}/public"

    coffee: () ->
      console.log("Flavors", configuration.flavors)
      stream = gulp.src 'app/**/*.coffee'
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe changed "#{configuration.buildDir}/"
      stream  = stream.pipe sourcemaps.init() if configuration.mode is 'debug'
      stream = stream.pipe coffee()
      stream = stream.pipe sourcemaps.write '/' if configuration.mode is 'debug'
      stream.pipe gulp.dest "#{configuration.buildDir}/"

    mergeJsons: ->

    mergeCoffescript: ->

    mergeCss: ->

    mergeImages: ->

    createBuildFile: ->

    finalize: () ->
      pattern = "#{configuration.buildDir}/**/*.#{COMPILATION_MODE.Name}.*"
      antiMode = if configuration.mode is 'debug' then 'release' else 'debug'
      antipattern = "#{configuration.buildDir}/**/*.#{antimode}.*"
      del.sync [antipattern]
      gulp.src [pattern, "!#{configuration.buildDir}/**/*.map"]
      .pipe rename (path) ->
        {basename} = path
        basename = basename.slice(0, basename.lastIndexOf(".#{COMPILATION_MODE.Name}"))
        path.basename = basename
        path
      .pipe gulp.dest "#{configuration.buildDir}/"

    minify: () ->
      gulp.src "#{configuration.buildDir}/**/*.css"
      .pipe minifyCss()
      .pipe gulp.dest("#{configuration.buildDir}/")

    uglify: () ->
      gulp.src "#{configuration.buildDir}/**/*(!.min).js"
      .pipe uglify mangle: false
      .pipe gulp.dest("#{configuration.buildDir}/")

    promisify: (stream) ->
      promise = Q.defer()
      stream.on 'finish', promise.resolve
      promise.promise

    compile: () ->
      promise = Q.defer()
      run = [
        tasks.js
        tasks.coffee
        #tasks.public
        #tasks.translate
        #tasks.manifest
        #tasks.eco
        #tasks.images
        #tasks.fonts
        #tasks.html
        #tasks.less
        #tasks.buildLangFile
        #tasks.regions
      ]
      run = (tasks.promisify(task()) for task in run)
      Q.all(run).then ->
        ##tasks.promisify(tasks.finalize()).then ->
          #promise.resolve()
          #if COMPILATION_MODE is DEBUG_MODE then promise.resolve()
          #else
          #  Q.all([tasks.promisify(tasks.minify())]).then(promise.resolve)

  tasks.compile()
