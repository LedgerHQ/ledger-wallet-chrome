class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: "#chainSelected",
    chain: "#chain"

  onAfterRender: ->
    super
    @view.chainSelected.once "click", @onChainSelected

  onChainSelected: ->
    chain = {}
    for network in ledger.bitcoin.Networks
      chain = network if network.name == @view.chain
    ledger.app.onChainChosen(chain)

  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
    ledger.app.off 'wallet:initialized', @onWalletInitialized
    ledger.app.off 'wallet:initialization:creation', @onWalletIsSynchronizing