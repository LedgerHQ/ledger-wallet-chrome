ledger.database ?= {}
migrations = _

class ledger.database.MigrationHandler

  constructor: (context) ->
    @context = context

    versionMatcherToRegex = (versionMatcher) ->
      if _.isRegExp(versionMatcher)
        versionMatcher
      else if !versionMatcher or versionMatcher is 'unknown' or versionMatcher is '*'
        /.*/
      else
        new RegExp("^" + versionMatcher.replace(/\./g, '\\.').replace(/\*/g, '.*') + "$")

    @_migrations = ({from: versionMatcherToRegex(migration.from), to: versionMatcherToRegex(migration.to), apply: migration.apply} for migration in migrations)

  applyMigrations: () ->
    configurationVersion = Configuration.getInstance(@context).getCurrentApplicationVersion()
    configurationVersion ?= 'unknown'
    manifestVersion = chrome.runtime.getManifest().version
    @performMigrations configurationVersion, manifestVersion
    Configuration.getInstance(@context).setCurrentApplicationVersion(manifestVersion)

  performMigrations: (fromVersion, toVersion) ->
    for migration in @_migrations
      if fromVersion.match(migration.from) and toVersion.match(migration.to)
        migration.apply @context


migrations = [
  # {from: 'unknown', to: '1.0.6', apply: -> l 'MIGRATION 1'}
  # {from: 'unknown', to: '*', apply: -> l 'MIGRATION 2'}
  {from: '1.[0-3].[0-5]', to: '1.3.*', apply: (context) -> migrate_from_1_0_3_x_to_1_4_x(context)}
]

migrate_from_1_0_3_x_to_1_4_x = (context) ->
  # Force to save every sync properties on the sync store
  if (account = Account.findById(0, context))?
    for operation in Operation.all(context)
      operation.set('account', account).save()
    account.set('wallet', Wallet.findById(1, context)).save()

  for Model in ledger.database.Model.AllModelClasses()
    if Model.hasSynchronizedProperties()
      collection = context.getCollection(Model.getCollectionName())
      for object in Model.all(context)
        collection.updateSynchronizedProperties(object)