class @Api

  @init: ->
    @_has_session = false
    ledger.app.on 'wallet:initialized', ->
      Api._has_session = true
    ledger.app.on 'dongle:disconnected', ->
      Api._has_session = false

  @listener: (event) ->
    data = event.data
    if data.command != 'has_session'
      chrome.app.window.current().show()
    switch data.command
      when 'has_session'
        @hasSession(data)
      when 'bitid'
        @bitid(data)
      when  'send_payment'
        @sendPayment(data)
      when 'sign_message'
        @signMessage(data)
      when 'sign_p2sh'
        @signP2SH(data)
      when 'get_xpubkey'
        @getXPubKey(data)
      when 'get_accounts'
        @getAccounts(data)
      when 'get_operations'
        @getOperations(data)
      when 'get_new_addresses'
        @getNewAddresses(data)
      when 'coinkite_get_xpubkey'
        @coinkiteGetXPubKey(data)
      when 'coinkite_sign_json'
        @coinkiteSignJSON(data)

  @hasSession: (data) ->
    chrome.runtime.sendMessage {
      command: 'has_session',
      success: @_has_session
    }    

  @sendPayment: (data) ->
    ledger.app.router.go '/wallet/send/index', {address: data.address, amount: data.amount}

  @getAccounts: (data) ->
    ledger.app.router.go '/wallet/api/accounts'

  @exportAccounts: (data) ->
    accounts = []
    for account in Account.all()
      accounts.push(account.serialize())
    @callback_success 'get_accounts', accounts: accounts

  @getOperations: (data) ->
    ledger.app.router.go '/wallet/api/operations', {account_id: data.account_id}

  @exportOperations: (account_id) ->
    account = Account.find({"id": account_id}).first()
    operations = []
    for operation in account.get('operations')
      operations.push(operation.serialize())
    @callback_success 'get_operations', operations: operations

  @getNewAddresses: (data) ->
    ledger.app.router.go '/wallet/api/addresses', {account_id: data.account_id, count: data.count}

  @exportNewAddresses: (account_id, count) ->
    account = Account.find({"id": account_id}).first().getWalletAccount()
    current = account.getCurrentPublicAddressIndex()
    ledger.wallet.pathsToAddresses _(_.range(current, current + count)).map((i) ->
      account.getRootDerivationPath() + '/0/' + i
    ), (result) =>
      @callback_success 'get_new_addresses',
        addresses: result
        account_id: account_id
      return

  @signMessage: (data) ->
    try
      ledger.bitcoin.bitid.getAddress path: data.path
      .then (result) =>
        @address = result.bitcoinAddress.value
        ledger.bitcoin.bitid.signMessage(data.message, path: data.path)
        .then (result) =>
          @callback_success('sign_message', signature: result, address: @address)
          return
        .fail (error) =>
          @callback_cancel('sign_message', JSON.stringify(error))
          return
      .fail (error) =>
        @callback_cancel('sign_message', JSON.stringify(error))
        return
    catch error
      callback_cancel('sign_message', JSON.stringify(error))

  @cosignTransaction: (data) ->
    try
      transaction = Bitcoin.Transaction.deserialize(data.transaction);
      ledger.app.dongle.signP2SHTransaction(data.inputs, transaction, data.scripts, data.path)
      .then (result) =>
        @callback_success('cosign_transaction', signatures: result)
        return
      .fail (error) =>
        @callback_cancel('cosign_transaction', JSON.stringify(error))
        return
    catch error
      @callback_cancel('cosign_transaction', JSON.stringify(error))

  @signP2SH: (data) ->
    ledger.app.router.go '/wallet/p2sh/index', {inputs: JSON.stringify(data.inputs), scripts: JSON.stringify(data.scripts), outputs_number: data.outputs_number, outputs_script: data.outputs_script, paths: JSON.stringify(data.paths)}

  @getXPubKey: (data) ->
    ledger.app.router.go '/wallet/xpubkey/index', {path: data.path}

  @bitid: (data) ->
    ledger.app.router.go '/wallet/bitid/index', {uri: data.uri, silent: data.silent}

  @coinkiteGetXPubKey: (data) ->
    ledger.app.router.go '/apps/coinkite/keygen/index', {index: data.index}

  @coinkiteSignJSON: (data) ->
    ledger.app.router.go '/apps/coinkite/cosign/show', {json: JSON.stringify(data.json)}

  @callback_cancel: (command, message) ->
    chrome.runtime.sendMessage 
      command: command,
      success: false,
      message: message

  @callback_success: (command, data) ->
    chrome.runtime.sendMessage $.extend {
        command: command,
        success: true 
      }, data