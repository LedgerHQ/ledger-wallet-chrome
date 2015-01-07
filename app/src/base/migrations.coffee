
class @MigrationHandler

  constructor: (context) ->
    @context = context

  applyMigrations: () ->
    configurationVersion = Configuration.getInstance(@context).getCurrentApplicationVersion()
    configurationVersion ?= 'unknown'
    manifestVersion = chrome.runtime.getManifest().version
    @performMigrations configurationVersion, manifestVersion
    Configuration.getInstance(@context).setCurrentApplicationVersion(manifestVersion)

  performMigrations: (fromVersion, toVersion) ->
    for migration in migrations
      if (migration.from is fromVersion or migration.from is '*') and (migration.to is toVersion or migration.to is '*')
        migration.apply()

migrations = [
  # {from: 'unknown', to: '1.0.6', apply: -> l 'MIGRATION 1'}
  # {from: 'unknown', to: '*', apply: -> l 'MIGRATION 2'}
]