gulp  = require 'gulp'

# Load all required libraries.
Q               = require 'Q'
less            = require 'gulp-less'
coffee          = require 'gulp-coffee'
yaml            = require 'gulp-yaml'
eco             = require 'gulp-eco'
sourcemaps      = require 'gulp-sourcemaps'
uglify          = require 'gulp-uglify'
minifyCss       = require 'gulp-minify-css'
changed         = require 'gulp-changed'
plumber         = require 'gulp-plumber'
rename          = require 'gulp-rename'
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
{i18n, buildLangFilePlugin} = require './gulp-i18n'
createBuildFile = require './gulp-build-file'
cached          = require 'gulp-cached'
slash           = require 'gulp-slash'

module.exports = (configuration) ->

  tasks =

    less: () ->
      gulp.src 'app/assets/css/**/*.less'
      .pipe slash()
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe cached('less')
      .pipe changed "#{configuration.buildDir}/assets/css", extension: '.css', hasChanged: changed.compareSha1Digest
      .pipe less()
      .pipe gulp.dest "#{configuration.buildDir}/assets/css"

    css: () ->
      gulp.src 'app/assets/css/**/*.css'
      .pipe slash()
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/assets/css"
      .pipe gulp.dest "#{configuration.buildDir}/assets/css"

    images: () ->
      gulp.src 'app/assets/images/**/*'
      .pipe slash()
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: no)
      .pipe changed "#{configuration.buildDir}/assets/images"
      .pipe gulp.dest "#{configuration.buildDir}/assets/images"

    fonts: () ->
      gulp.src 'app/assets/fonts/**/*'
      .pipe slash()
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: no)
      .pipe changed "#{configuration.buildDir}/assets/fonts"
      .pipe gulp.dest "#{configuration.buildDir}/assets/fonts"

    html: () ->
      gulp.src 'app/views/**/*.html'
      .pipe slash()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/views"
      .pipe gulp.dest "#{configuration.buildDir}/views"

    eco: () ->
      gulp.src 'app/views/**/*.eco'
      .pipe slash()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe plumber()
      .pipe cached('eco')
      .pipe changed "#{configuration.buildDir}/views", extension: '.js', hasChanged: changed.compareSha1Digest
      .pipe eco({basePath: 'app/views/'})
      .pipe gulp.dest "#{configuration.buildDir}/views"

    manifest: () ->
      gulp.src 'app/manifest.yml'
      .pipe slash()
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe changed "#{configuration.buildDir}/", extension: '.json', hasChanged: changed.compareSha1Digest
      .pipe yaml if configuration.mode is 'debug' then space: 1 else null
      .pipe gulp.dest "#{configuration.buildDir}/"

    translate: () ->
      gulp.src 'app/locales/**/!(es)/*.properties'
      .pipe slash()
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe changed "#{configuration.buildDir}/_locales", extension: '.json', hasChanged: changed.compareSha1Digest
      .pipe i18n()
      .pipe ext_replace('.json')
      .pipe gulp.dest "#{configuration.buildDir}/_locales"

    buildLangFile: () ->
      gulp.src 'app/locales/**/!(es)/*.properties'
      .pipe slash()
      .pipe plumber()
      .pipe cached('lang-file')
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe buildLangFilePlugin()
      .pipe tap (file, t) ->
        file.contents = new Buffer file.contents.toString().replace(/^"|"$/g, '')
      .pipe concat 'i18n_languages.js'
      .pipe gulp.dest "#{configuration.buildDir}/src/i18n"

    regions: () ->
      gulp.src 'app/src/i18n/regions.yml'
      .pipe slash()
      .pipe yaml()
      .pipe gulp.dest "#{configuration.buildDir}/src/i18n"

    js: () ->
      gulp.src 'app/**/*.js'
      .pipe slash()
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/"
      .pipe gulp.dest "#{configuration.buildDir}/"

    public: () ->
      gulp.src 'app/public/**/*'
      .pipe slash()
      .pipe plumber()
      .pipe changed "#{configuration.buildDir}/public"
      .pipe gulp.dest "#{configuration.buildDir}/public"

    coffee: () ->
      stream = gulp.src 'app/**/*.coffee'
      .pipe slash()
      .pipe plumber()
      .pipe flavors(flavors: configuration.flavors, merge: yes)
      .pipe cached('coffee')
      .pipe changed "#{configuration.buildDir}/", extension: '.js'
      .pipe createBuildFile(configuration)
      stream  = stream.pipe sourcemaps.init() if configuration.mode is 'debug'
      stream = stream.pipe coffee()
      stream = stream.pipe sourcemaps.write '/' if configuration.mode is 'debug'
      stream.pipe gulp.dest "#{configuration.buildDir}/"

    minify: () ->
      gulp.src "#{configuration.buildDir}/**/*.css"
      .pipe slash()
      .pipe minifyCss()
      .pipe gulp.dest("#{configuration.buildDir}/")

    uglify: () ->
      gulp.src "#{configuration.buildDir}/**/*(!.min).js"
      .pipe slash()
      .pipe uglify mangle: false
      .pipe gulp.dest("#{configuration.buildDir}/")

    promisify: (stream) ->
      promise = Q.defer()
      stream.on 'finish', promise.resolve
      promise.promise

    compile: () ->
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
        tasks.buildLangFile
        tasks.regions
      ]
      run = (tasks.promisify(task()) for task in run)
      Q.all(run).then ->
        if configuration.mode is 'release'
          Q.all([tasks.promisify(tasks.minify()), tasks.promisify(tasks.uglify())])

  tasks.compile()
