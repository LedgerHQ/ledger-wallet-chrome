
class @WalletsManager extends EventEmitter

  _wallets: {}
  _restoreStates: []

  constructor: (app) ->
    @cardFactory = new ChromeapiPlugupCardTerminalFactory()
    app.devicesManager.on 'plug', (e, card) => @connectCard(card)
    app.devicesManager.on 'unplug', (e, card) => @disconnectCard(card)

  connectCard: (card) ->
    @emit 'connecting', card
    @cardFactory.list_async().then (result) =>
      setTimeout =>
        if result.length > 0
          @cardFactory.getCardTerminal(result[0]).getCard_async().then (lwCard) =>
            setTimeout () =>
              @_wallets[card.id] = new ledger.wallet.HardwareWallet(this, card.id, lwCard)
              @_wallets[card.id].once 'connected', (event, wallet) => @emit 'connected', wallet
              @_wallets[card.id].connect()
      , 0

  addRestorableState: (state, expiry) ->
    @_restoreStates.push state
    if expiry? >= 0
      setTimeout () =>
        @removeRestorableState state
      , expiry

  removeRestorableState: (state) ->
    @_restoreStates = _(@_restoreStates).reject (item) -> item is state

  findRestorableStates: (predicate) -> _(@_restoreStates).where predicate

  disconnectCard: (card) ->
    @_wallets[card.id]?.disconnect()
    @emit 'disconnect', card

