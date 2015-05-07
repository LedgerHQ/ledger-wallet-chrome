class @WalletsManager extends EventEmitter

  _wallets: {}
  _restoreStates: []

  constructor: (app) ->
    @cardFactory = new ChromeapiPlugupCardTerminalFactory()
    @factoryDongleBootloader = new ChromeapiPlugupCardTerminalFactory(0x1808);
    @factoryDongleBootloaderHID = new ChromeapiPlugupCardTerminalFactory(0x1807);
    app.devicesManager.on 'plug', (e, card) => @connectCard(card)
    app.devicesManager.on 'unplug', (e, card) => @disconnectCard(card)

  connectCard: (card) ->
    try
      card.isInBootloaderMode = if card.productId is 0x1808 or card.productId is 0x1807 then yes else no
      @emit 'connecting', card
      result = []
      @cardFactory.list_async()
      .then (cards) =>
        result = result.concat(cards)
        @factoryDongleBootloader.list_async()
      .then (cards) =>
        result = result.concat(cards)
        @factoryDongleBootloaderHID.list_async()
      .then (cards) =>
        result = result.concat(cards)
        _.defer =>
          if result.length > 0
            @cardFactory.getCardTerminal(result[0]).getCard_async().then (lwCard) =>
              _.defer =>
                @_wallets[card.id] = new ledger.wallet.HardwareWallet(this, card, lwCard)
                @_wallets[card.id].once 'connected', (event, wallet) =>
                  @emit 'connected', wallet
                  if _(ledger.app.devicesManager.devices()).where(id: wallet.id).length is 0
                    _.defer => wallet.disconnect()
                @_wallets[card.id].once 'forged', (event, wallet) => @emit 'forged', wallet
                @_wallets[card.id].connect()
    catch er
      e er

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

  getConnectedWallets: -> _(_.values(@_wallets)).filter (w) -> w._state isnt ledger.wallet.States.DISCONNECTED

