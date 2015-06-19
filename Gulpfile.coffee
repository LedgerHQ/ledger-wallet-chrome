gulp  = require 'gulp'
runSequence = require 'run-sequence'
Q = require 'q'

fs = require 'fs'

defaultPreferences =
  build_dir: 'build/'
  tag: null
  debug: yes
  release: no
  flavors: []
  network: 'bitcoin'

unless fs.existsSync('./.compilation_preferences.json')
  fs.writeFileSync "./.compilation_preferences.json", JSON.stringify(defaultPreferences)

preferences = require './.compilation_preferences'

yargs = require 'yargs'
        .usage 'Usage: $0 <command> [commands] [options]'
        .command 'build', 'Build the application'
        .command 'watch', 'Watch any changes in the sources and trigger application build'
        .command 'zip', 'Build the application and zip it'
        .command 'package', 'Build the application and create a crx file'
        .command 'clean', 'Clean files'
        .command 'doc', 'Create the documentation'
        .command 'generate', 'Compute generated files (i.e. Firmware update manifest file)'
        .command 'configure', 'Configure default compilation flags'
        .command 'reset', 'Reset to the default compilation flags'
        .example '$0 configure --release --network testnet', 'set the default build mode to "release" with the "testnet" network'
        .command 'release', 'Build, zip and package application'
        .help('help')
        .option 'b',
          alias: 'build-dir'
          default: preferences.build_dir
          describe: 'the destination directory'
          type: 'string'
        .option 't',
            alias: 'tag',
            default: preferences.tag
            describe: 'the git tag of the Chrome Application version to build',
            type: 'string'
        .option 'd',
          alias: 'debug'
          default: preferences.debug
          type: 'boolean'
        .option 'r',
          alias: 'release'
          default: preferences.release
          type: 'boolean'
        .option 'n',
          alias: 'network'
          default: preferences.network
        .option 'f',
          alias: 'flavor'
          default: preferences.flavors
          type: 'array'
        .strict()
argv = yargs.argv

configuration =
  buildDir: argv.b
  mode: if argv['release'] then 'release' else 'debug'
  network: argv['network']
  tag: argv['tag']
  time: new Date().getTime()

configuration.flavors = argv['flavor'].concat [configuration.network, configuration.mode, 'all']

checkoutAndRun = (script, conf = configuration) ->
  gitFinalize = require('./compilation/script-git-finalize')
  task = require("./compilation/#{script}")
  require('./compilation/script-git-setup')(conf).then -> task(conf)
  .then -> gitFinalize(conf)

taskQueue = Q()

gulp.task 'build', -> taskQueue = taskQueue.then -> checkoutAndRun('script-build')
gulp.task 'zip', ->  taskQueue = taskQueue.then -> checkoutAndRun('script-zip')
gulp.task 'package', -> taskQueue = taskQueue.then -> checkoutAndRun('script-package')

gulp.task 'doc', ->  taskQueue = taskQueue.then -> require('./compilation/script-doc')(configuration)
gulp.task 'generate', ->  taskQueue = taskQueue.then -> require('./compilation/script-generate')(configuration)

gulp.task 'configure', ->
  taskQueue = taskQueue.then ->
    newPreferences =
      build_dir: configuration.buildDir
      tag: configuration.tag
      debug: configuration.mode is 'debug'
      release: configuration.mode is 'release'
      flavors: argv['flavor']
      network: configuration.network
    fs.writeFileSync "./.compilation_preferences.json", JSON.stringify(newPreferences)

gulp.task 'reset', ->
  fs.writeFileSync "./.compilation_preferences.json", JSON.stringify(defaultPreferences)

gulp.task 'watch', ['clean'], ->
  gulp.watch('app/**/*', ['build'])

gulp.task 'clean', ->  taskQueue = taskQueue.then -> require('rimraf').sync(configuration.buildDir)

gulp.task 'default', -> yargs.showHelp('log')
