module.exports = (configuration) ->
  Q = require 'q'
  return Q() unless configuration.tag?
  git = require 'gulp-git'
  defer = Q.defer()
  git.exec args: 'branch', (err, stdout) ->
    return defer.reject("Unable to retrieve current branch") unless stdout?
    [__, configuration.currentBranch] = stdout.match /\*\s*(.+)\s/
    return defer.reject("Unable to retrieve current branch") unless currentBranch?
    tag = args[1] or currentBranch
    git.exec args: 'stash', (err, stdout) ->
      git.checkout tag, quiet: yes, ->
        defer.resolve()
  defer.promise