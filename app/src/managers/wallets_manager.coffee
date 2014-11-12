
class @WalletsManager extends EventEmitter

  _wallets: {}

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
              @_wallets[card.id] = new ledger.wallet.Wallet(card.id, lwCard)
              @_wallets[card.id].once 'connected', (event, wallet) => @emit 'connected', wallet
              @_wallets[card.id].connect()
      , 0

  disconnectCard: (card) ->

