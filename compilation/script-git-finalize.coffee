
module.exports = (configuration) ->
  Q = require 'q'
  return Q() unless configuration.tag?
  git = require 'gulp-git'
  defer = Q.defer()

  git.checkout configuration.currentBranch, quiet: yes, ->
    if configuration.isStashed
      git.exec args: 'stash pop', -> defer.resolve()
    else
      defer.resolve()

  defer.promise