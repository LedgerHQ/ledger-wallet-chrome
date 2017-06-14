class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: ".action-rounded-button",
    remember: "#remember"

  networks: []

  initialize: ->
    super
    @networks = JSON.parse @params.networks

  onAfterRender: ->
    super
    @view.chainSelected.on "click", @onChainSelected

  onChainSelected: (e) ->
    ###
    for network in ledger.bitcoin.Networks
      chain = network if network.name == @view.chain
    ###
    if @view.remember.is(":checked")
      ledger.app.dongle.getPublicAddress "44'/#{@networks[0].bip44_coin_type}'/0'/0/0", (addr) =>
        address = ledger.crypto.SHA256.hashString addr
        tmp = {}
        tmp[address]= @networks[e.target.attributes.value.value]
        ledger.storage.global.chainSelector.set tmp, =>
          ledger.storage.global.chainSelector.get address, (result) =>
    ledger.app.onChainChosen(@networks[e.target.attributes.value.value])

  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
