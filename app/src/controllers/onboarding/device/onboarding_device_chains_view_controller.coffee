class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: ".choice"
    remember: "#remember"

  networks: []

  initialize: ->
    super
    @networks = JSON.parse @params.networks
    l "netwooooooooooooooo"
    l @networks

  onAfterRender: ->
    super
    @view.chainSelected.on "click", @onChainSelected

  bitcoinCashSelected: (e) ->
    dialog = new CommonDialogsConfirmationDialogViewController()
    dialog.setMessageLocalizableKey 'onboarding.device.chains.bitcoin_cash_warning'
    dialog.positiveLocalizableKey = 'common.yes'
    dialog.negativeLocalizableKey = 'common.no'
    dialog.once 'click:positive', =>
      @chainChoosen(e)
    dialog.show()

  incompatible: () ->
    dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("onboarding.device.chains.bad_device_title"), subtitle: t('onboarding.device.chains.bad_device_message'))
    dialog.show()

  onChainSelected: (e) ->
    if @networks[e.target.attributes.value.value].name == 'bitcoin_cash'
      if !ledger.app.dongle.getFirmwareInformation().hasScreenAndButton()
        @incompatible()
      else
        @bitcoinCashSelected(e)
    else
      @chainChoosen(e)


  chainChoosen: (e) ->
    if @view.remember.is(":checked")
      ledger.app.dongle.getPublicAddress "44'/#{@networks[0].bip44_coin_type}'/0'/0/0", (addr) =>
        address = ledger.crypto.SHA256.hashString addr
        tmp = {}
        tmp[address]= @networks[e.target.attributes.value.value]
        ledger.storage.global.chainSelector.set tmp, =>
          ledger.storage.global.chainSelector.get address, (result) =>
            ledger.app.onChainChosen(@networks[e.target.attributes.value.value])
    else
      ledger.app.onChainChosen(@networks[e.target.attributes.value.value])


  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
