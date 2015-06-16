gulp  = require 'gulp'

yargs = require 'yargs'
        .usage 'Usage: $0 <command> [commands] [options]'
        .command 'build', 'Build the application'
        .command 'watch', 'Watch any changes in the sources and trigger application build'
        .command 'zip', 'Build the application and zip it'
        .command 'package', 'Build the application and create a crx file'
        .command 'clean', 'Clean files'
        .command 'doc', 'Create the documentation'
        .command 'generate', 'Compute generated files (i.e. Firmware update manifest file)'
        .command 'configure', 'Configure the default build flavors'
        .command 'release', 'Build, zip and package application'
        .help('help')
        .option 't',
            alias: 'tag',
            default: null
            describe: 'the git tag of the Chrome Application version to build',
            type: 'string'
        .option 'd',
          alias: 'debug'
          default: yes
          type: 'boolean'
        .option 'r',
          alias: 'release'
          default: no
          type: 'boolean'
        .option 'n',
          alias: 'network'
          default: 'bitcoin'
        .option 'f',
          alias: 'flavor'
          default: []
          type: 'array'
        .strict()
argv = yargs.argv

configuration =
  mode: if argv['release'] then 'release' else 'debug'
  network: argv['network']
  tag: argv['tag']

configuration.flavors = [configuration.mode, configuration.network].concat(argv['flavor'])

checkoutAndRun = (script, conf = configuration) ->
  gitFinalize = require('./compilation/script-git-finalize')
  task = require("./compilation/#{script}")
  require('./compilation/script-git-setup')(conf).then -> task(conf)
  .then -> gitFinalize(conf)

gulp.task 'build', -> checkoutAndRun('script-build')
gulp.task 'zip', -> checkoutAndRun('script-zip')
gulp.task 'package', -> checkoutAndRun('script-package')
gulp.task 'release', -> checkoutAndRun('script-release')

gulp.task 'doc', -> require('./compilation/script-doc')(configuration)
gulp.task 'generate', -> require('./compilation/script-generate')(configuration)

gulp.task 'configure', ->


gulp.task 'watch', ['debug'], ->
  gulp.watch('app/**/*', ['build'])

gulp.task 'clean', (cb) -> del ['build/'], cb

gulp.task 'default', -> yargs.showHelp('log')

console.log require('./compilation/script-git-setup')
