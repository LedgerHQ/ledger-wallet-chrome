
module.exports = (configuration) ->
  Q = require 'q'
  return Q() unless configuration.tag?
  git = require 'gulp-git'
  defer = Q.defer()

  checkoutBack = ->
    git.checkout configuration.currentBranch, quiet: yes, ->
      defer.resolve()
  if configuration.isStashed
    git.exec args: 'stash pop', -> checkoutBack()
  else
    checkoutBack()

  defer.promise