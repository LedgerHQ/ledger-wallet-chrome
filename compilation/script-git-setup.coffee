
module.exports = (configuration) ->
  Q = require 'q'
  return Q() unless configuration.tag?
  git = require 'gulp-git'
  defer = Q.defer()
  git.exec args: 'branch', (err, stdout) ->
    return defer.reject("Unable to retrieve current branch") unless stdout?
    [__, configuration.currentBranch] = stdout.match /\*\s*(.+)\s/
    return defer.reject("Unable to retrieve current branch") unless configuration.currentBranch?
    git.exec args: 'stash', (err, stdout) ->
      return defer.reject(err) if err
      configuration.isStashed = stdout.match(/HEAD/)?
      git.checkout configuration.tag, quiet: yes, (err) ->
        if err?
          git.exec args: 'fetch', (err, stdout) ->
            git.checkout configuration.tag, quiet: yes, (err) ->
              defer.reject("Unable to checkout on tag #{configuration.tag}") if err?
        else
          defer.resolve()
  defer.promise