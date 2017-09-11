class @OnboardingDeviceChainsViewController extends @OnboardingViewController

  view:
    chainSelected: ".choice"
    remember: "#remember"
    advanced: "#advanced"
    uasf: "#uasf"
    segwit2x: "#segwit2x"
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
    @view.advanced.change(@toggleAdvanced.bind(this))
    @toggleAdvanced()

  toggleAdvanced: () ->
    if @view.advanced.is(":checked")
      @view.uasf.show()
      @view.segwit2x.show()
      @view.openHelpCenter.hide()
      @view.recoverTool.show()
    else
      @view.uasf.hide()
      @view.segwit2x.hide()
      @view.openHelpCenter.show()
      @view.recoverTool.hide()

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
      if (ledger.app.dongle.getFirmwareInformation().getIntFirmwareVersion() >= 0x30010105 or (ledger.app.dongle.getFirmwareInformation().getArchitecture() < 0x30 and ledger.app.dongle.getFirmwareInformation().getIntFirmwareVersion() >= 0x20010004)) && (@networks[e.target.attributes.value.value].name == 'bitcoin' ||  @networks[e.target.attributes.value.value].name == 'bitcoin_segwit2x' ||@networks[e.target.attributes.value.value].name == 'litecoin')
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
