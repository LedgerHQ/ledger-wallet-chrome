###
  Listens the database and the HD layout in order to ensure consistency in the database.
###
class ledger.tasks.AccountManagerTask extends ledger.tasks.Task

  @instance: new @

  @reset: -> @instance = new @

  constructor: ->
    super("account_manager_task")
    _.bindAll(@, ['onDiscoverNewHdAccount'])

  onStart: ->
    super
    ledger.database.contexts.main.on 'insert:operation',

  onDiscoverNewHdAccount: ->


  onStop: ->