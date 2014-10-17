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

gulp.task 'less', ['compile:clean'], ->
  gulp.src 'app/assets/css/**/*.less'
    .pipe changed 'build/assets/css'
    .pipe less()
    .pipe gulp.dest 'build/assets/css'

gulp.task 'css', ['compile:clean'], ->
  gulp.src 'app/assets/css/**/*.css'
    .pipe changed 'build/assets/css'
    .pipe gulp.dest 'build/assets/css'

gulp.task 'images', ['compile:clean'], ->
  gulp.src 'app/assets/images/**/*'
    .pipe changed 'build/assets/images/'
    .pipe gulp.dest 'build/assets/images/'

gulp.task 'html', ['compile:clean'], ->
  gulp.src 'app/assets/views/**/*.html'
    .pipe changed 'build/assets/views'
    .pipe gulp.dest 'build/assets/views'

gulp.task 'eco', ['compile:clean'], ->
  gulp.src 'app/assets/views/**/*.ect'
    .pipe changed 'build/assets/views'
    .pipe eco()
    .pipe gulp.dest 'build/assets/views'

gulp.task 'yml', ['compile:clean'], ->
  gulp.src 'app/manifest.yml'
    .pipe changed 'build/'
    .pipe yaml()
    .pipe gulp.dest 'build/'

gulp.task 'translate', ['compile:clean'], ->
  gulp.src 'app/locales/*.yml'
  .pipe changed 'build/'
    .pipe yaml()
      .pipe gulp.dest 'build/_locales'

gulp.task 'js', ['compile:clean'], ->
  gulp.src 'app/**/*.js'
    .pipe changed 'build/'
    .pipe gulp.dest 'build/'

gulp.task 'coffee-script', ['compile:clean'], ->
  gulp.src 'app/**/*.coffee'
    .pipe changed 'build/'
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe sourcemaps.write '/'
    .pipe gulp.dest 'build/'

gulp.task 'compile:clean', (cb) ->
  del ['build/'], cb

gulp.task 'release:clean', (cb) ->
  del ['release/'], cb

gulp.task 'release:uglify', ['compile:sources'],  ->
  gulp.src 'build/src/**/*.js'
    .pipe uglify()
    .pipe gulp.dest 'release/src/'

gulp.task 'release:minify', ['compile:assets'],  ->
  gulp.src 'build/**/*.css'
    .pipe minifyCss()
    .pipe gulp.dest 'release/'

gulp.task 'release:images', ['compile:assets'], ->
  gulp.src 'build/assets/images/**/*'
    .pipe gulp.dest 'release/assets/images'

gulp.task 'release:json', ['compile:assets'], ->
  gulp.src 'build/**/*.json'
    .pipe gulp.dest 'release/'

gulp.task 'release:libs', ['compile:sources'], ->
  gulp.src 'build/libs/**/*.js'
    .pipe gulp.dest 'release/libs/'

gulp.task 'release:views', ['compile:assets'], ->
  gulp.src 'build/views/**/*'
    .pipe gulp.dest 'release/views/'

gulp.task 'watch', ['compile'], ->
  watcher = gulp.watch('app/**/*', ['compile:assets', 'compile:sources'])

# Default task call every tasks created so far.
gulp.task 'compile:assets', ['less', 'css', 'eco', 'html', 'yml', 'images', 'translate']
gulp.task 'compile:sources', ['js', 'coffee-script']
gulp.task 'compile', ['compile:clean', 'compile:assets', 'compile:sources']
gulp.task 'default', ['compile']

gulp.task 'clean', ['compile:clean', 'release:clean']

gulp.task 'release', ['release:clean', 'release:uglify', 'release:minify', 'release:json', 'release:libs', 'release:images']