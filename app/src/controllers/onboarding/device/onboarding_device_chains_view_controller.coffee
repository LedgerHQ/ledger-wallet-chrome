class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: "#chainSelected",
    chain: "#chain",
    remember: "#remember"

  networks: []

  initialize: ->
    super
    @networks = JSON.parse @params.networks

  onAfterRender: ->
    super
    @view.chainSelected.on "click", @onChainSelected

  onChainSelected: ->
    ###
    for network in ledger.bitcoin.Networks
      chain = network if network.name == @view.chain
    ###
    if @view.remember.is(":checked")
      l " remember"
      ledger.app.dongle.getPublicAddress "44'/#{@networks[0].bip44_coin_type}'/0'/0/0", (addr) =>
        address = ledger.crypto.SHA256.hashString addr
        tmp = {}
        tmp[address]= @networks[@view.chain.val()]
        l tmp
        ledger.storage.global.chainSelector.set tmp, =>
          ledger.storage.global.chainSelector.get address, (result) =>
            l result
    ledger.app.onChainChosen(@networks[@view.chain.val()])

  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
