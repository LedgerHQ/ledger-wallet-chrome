
fs = require 'fs'
path = require 'path'
join = path.join

ensureDirectoryExists = (dirname) ->
  unless fs.existsSync(join(dirname))
    fs.mkdirSync join(dirname), 0o766

ensureDistDir = () -> ensureDirectoryExists 'dist'

ensureSignatureDir = () -> ensureDirectoryExists('signature')

module.exports = {
  ensureDirectoryExists
  ensureDistDir
  ensureSignatureDir
}

