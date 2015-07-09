{exec} = require 'child_process'
Q = require 'Q'

module.exports = () ->
  defer = Q.defer()
  child = exec './node_modules/.bin/codo -v app/src/', {}, () ->
    child.stdin.pipe process.stdin
    child.stdout.pipe process.stdout
    child.stderr.pipe process.stderr
    defer.resolve()
  defer.promise