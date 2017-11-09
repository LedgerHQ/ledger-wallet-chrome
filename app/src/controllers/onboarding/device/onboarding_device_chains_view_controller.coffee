class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: ".choice"
    remember: "#remember"
    openHelpCenter: "#help"
    recoverTool: "#recover"

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
      @chainChoosen(@networks[parseInt(e.target.attributes.value.value,10)+1])
    dialog.once 'click:un_split', =>
      @chainChoosen(@networks[e.target.attributes.value.value])
    dialog.show()

  chooseSegwit: (e) ->
    dialog = new OnboardingDeviceChainsChoiceDialogViewController({title: t("onboarding.device.chains.segwit_title"), text: t('onboarding.device.chains.segwit_message'), firstChoice: t('onboarding.device.chains.segwit_legacy'), secondChoice: t('onboarding.device.chains.segwit_segwit'), cancel: t('onboarding.device.chains.segwit_cancel')})
    dialog.once 'click:first', =>
      @chainChoosen(@networks[e.target.attributes.value.value])
    dialog.once 'click:second', =>
      @chainChoosen(@networks[parseInt(e.target.attributes.value.value,10)+1])
    dialog.show()

  chooseSegwit2x: (e) ->
    dialog = new OnboardingDeviceChainsChoiceDialogViewController({title: t("onboarding.device.chains.2x.segwit_title"), text: t('onboarding.device.chains.2x.segwit_message'), firstChoice: t('onboarding.device.chains.2x.segwit_legacy'), secondChoice: t('onboarding.device.chains.2x.segwit_segwit'), cancel: t('onboarding.device.chains.2x.segwit_cancel')})
    dialog.once 'click:first', =>
      @chainChoosen(@networks[e.target.attributes.value.value])
    dialog.once 'click:second', =>
      @chainChoosen(@networks[parseInt(e.target.attributes.value.value,10)+1])
    dialog.show()

  recoverTool: (e) ->
    dialog = new OnboardingDeviceChainsRecoverDialogViewController()
    dialog.once 'click:recover', =>
      @chainChoosen(ledger.bitcoin.Networks.bitcoin_recover)
    dialog.show()

  incompatible: () ->
    dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("onboarding.device.chains.bad_device_title"), subtitle: t('onboarding.device.chains.bad_device_message'))
    dialog.show()

  onChainSelected: (e) ->
    l e
    if @networks[e.target.attributes.value.value].name != 'bitcoin_cash_unsplit'
      if (ledger.app.dongle.getFirmwareInformation().getIntFirmwareVersion() >= 0x30010105 or (ledger.app.dongle.getFirmwareInformation().getArchitecture() < 0x30 and ledger.app.dongle.getFirmwareInformation().getIntFirmwareVersion() >= 0x20010004)) && (@networks[e.target.attributes.value.value].name == 'bitcoin' ||  @networks[e.target.attributes.value.value].name == 'bitcoin_2x' || @networks[e.target.attributes.value.value].name == 'litecoin')
        if @networks[e.target.attributes.value.value].name == 'bitcoin_2x'
          @chooseSegwit2x(e)
        else
          @chooseSegwit(e)
      else
        @chainChoosen(@networks[e.target.attributes.value.value])
    else
      if !ledger.app.dongle.getFirmwareInformation().isUsingInputFinalizeFull()
        @incompatible()
      else
        @bitcoinCashSelected(e)

  chainChoosen: (e) ->

    ledger.app.dongle.getPublicAddress "44'/#{@networks[0].bip44_coin_type}'/0'/0/0", (addr) =>
      address = ledger.crypto.SHA256.hashString addr.bitcoinAddress.toString(ASCII)
      tmp = {}
      if @view.remember.is(":checked")
        tmp[address]= e
        ledger.storage.global.chainSelector.set tmp, =>
          ledger.storage.global.chainSelector.get address, (result) =>
            ledger.app.onChainChosen(e)
      else
        tmp[address]= 0
        ledger.storage.global.chainSelector.set tmp, =>
          ledger.storage.global.chainSelector.get address, (result) =>
            ledger.app.onChainChosen(e)


  openSupport: ->
    window.open t 'application.support_url'

  onDetach: ->
    super
