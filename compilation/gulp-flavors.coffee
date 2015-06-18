
_ = require 'underscore'
through = require 'through2'
gutil = require 'gulp-util'
File = gutil.File

computePriority = (fileFlavors, configurationFlavors) ->
  priorities =  (_(configurationFlavors).indexOf(flavor) for flavor in fileFlavors)
  _(priorities).max (priority) -> priority

transformStream = ({flavors, merge} = {merge: yes}, file, encoding, done) ->
  @_plugingPrivate ||= {}
  files = (@_plugingPrivate._files ||= {})
  [__, filename] = file.path.match /.+\/(.+)$/
  if matches = filename.match /\w+((?:\.\w+)+)\.\w+$/
    [__, fileFlavors...] = matches[1].split('.')
    unflavoredName = filename.replace('.' + fileFlavors.join('.'), '')
    unflavoredPath = file.path.replace(filename, unflavoredName)
    if _(fileFlavors).every((f) -> _(flavors).contains(f))
      file.___flavorPriority = computePriority(fileFlavors, flavors)
      (files[unflavoredPath] ||= []).push file
      files[unflavoredPath]
  else
    file.___flavorPriority = -1
    (files[file.path] ||= []).push file
  do done

flushStream = ({flavors, merge} = {merge: yes}, done) ->
  for path, files of @_plugingPrivate._files
    continue if files.length is 0
    files = _(files).sortBy('___flavorPriority')
    {cwd, base} = files[0]
    if files.length is 1
      @push new File(cwd: cwd, base: base, path: path, contents: files[0].contents, stat: files[0].stat)
    else if merge is no
      @push new File(cwd: cwd, base: base, path: path, contents: files[files.length - 1].contents, stat: files[0].stat)
    else
      buffer = ''
      stat = files[0]
      for file in files
        buffer += file.contents.toString() + gutil.linefeed
        stat = file.stat if file.stat.mtime > stat.mtime
      @push new File(cwd: cwd, base: cwd, path: path, contents: new Buffer(buffer), stat: stat)
  do done

module.exports = (configuration) -> through.obj(_.partial(transformStream, configuration), _.partial(flushStream, configuration))