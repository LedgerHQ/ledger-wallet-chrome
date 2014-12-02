
ledger.db ?= {}
ledger.db.contexts ?= {}

class ledger.db.contexts.Context



  getCollection: (name) ->


_.extend ledger.db.contexts,

  open: (callback) ->