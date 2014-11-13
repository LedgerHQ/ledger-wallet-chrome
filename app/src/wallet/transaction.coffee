@ledger.wallet ?= {}

class ledger.wallet.Transaction

  init: (@amount, @fees, callback) ->

  prepare: (@inputs, changePath, recipientAddress, callback) ->

  validate: (validationKey, callback) ->

  @prepareTransaction: (accountPath, callback) ->