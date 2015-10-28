
ledger.database ||= {}

class ledger.database.DatabasePersistenceAdapter

  constructor: (dbName) ->

  declare: (collection) -> @_postCommand(command: 'declare', collection: collection)

  delete: () -> @_postCommand(command: 'delete')

  saveChanges: (changes) -> @_postCommand(command: 'changes', changes: changes)

  serialize: () -> @_postCommand(command: 'serialize')

  _postCommand: (command) ->