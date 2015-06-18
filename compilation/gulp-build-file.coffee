
_ = require 'underscore'
gutil = require 'gulp-util'
File = gutil.File
through = require 'through2'
Eco = require 'eco'
fs = require 'fs'

transformStream = (configuraton, file, encoding, done) ->
  @push file
  do done

flushStream = (configuration, done) ->
  console.log process.cwd()
  template = fs.readFileSync 'compilation/build.coffee.template', "utf-8"
  buildFileContent = Eco.render(template, configuration)
  @push new File(cwd: '', base: '', path: "src/build.coffee", contents: new Buffer(buildFileContent))
  do done

module.exports = (configuration) -> through.obj(_.partial(transformStream, configuration), _.partial(flushStream, configuration))