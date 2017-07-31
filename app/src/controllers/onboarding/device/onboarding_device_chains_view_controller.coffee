class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: ".choice"
    remember: "#remember"

  networks: []

  initialize: ->
    super
    @networks = JSON.parse @params.networks
    l @networks

  onAfterRender: ->
    super
    @view.chainSelected.on "click", @onChainSelected

  bitcoinCashSelected: (e) ->
    dialog = new OnboardingDeviceChainsMessageDialogViewController()
    dialog.once 'click:split', =>
      @chainChoosen(@networks[2])
    dialog.once 'click:un_split', =>
      @chainChoosen(@networks[1])
    dialog.show()

  incompatible: () ->
    dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("onboarding.device.chains.bad_device_title"), subtitle: t('onboarding.device.chains.bad_device_message'))
    dialog.show()

  onChainSelected: (e) ->
    if @networks[e.target.attributes.value.value].name != 'bitcoin_cash_unsplit'
      @chainChoosen(@networks[e.target.attributes.value.value])
    else
      if !ledger.app.dongle.getFirmwareInformation().isUsingInputFinalizeFull()
        @incompatible()
      else
        @bitcoinCashSelected(e)

  chainChoosen: (e) ->
    if @view.remember.is(":checked")
      ledger.app.dongle.getPublicAddress "44'/#{@networks[0].bip44_coin_type}'/0'/0/0", (addr) =>
        address = ledger.crypto.SHA256.hashString addr
        tmp = {}
        tmp[address]= e
        ledger.storage.global.chainSelector.set tmp, =>
          ledger.storage.global.chainSelector.get address, (result) =>
            ledger.app.onChainChosen(e)
    else
      ledger.app.onChainChosen(e)


  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
