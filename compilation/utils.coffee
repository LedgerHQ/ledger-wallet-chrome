
fs = require 'fs'
path = require 'path'
join = path.join

ensureDirectoryExists = (dirname) ->
  unless fs.existsSync(join(__dirname, dirname))
    fs.mkdirSync join(__dirname, dirname), 0o766

ensureDistDir = () -> ensureDirectoryExists 'dist'

ensureSignatureDir = () -> ensureDirectoryExists('signature')

module.exports = {
  ensureDirectoryExists
  ensureDistDir
  ensureSignatureDir
}

