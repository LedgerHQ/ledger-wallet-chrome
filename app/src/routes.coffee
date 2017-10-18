# routes that do not need a plugged ledger wallet
ledger.router ?= {}
ledger.router.ignorePluggedWalletForRouting = @ledger.isDev
ledger.router.pluggedWalletRoutesExceptions = [
  '/',
  '/onboarding/device/plug'
  '/onboarding/device/connecting'
  '/onboarding/device/forged'
]

# routes declarations
@declareRoutes = (route, app) ->
  ## Default
  route '/', ->
    if app.isInWalletMode()
      app.router.go '/onboarding/device/plug', {animateIntro: yes}
    else
      app.router.go '/update/welcome'

  ## Onboarding
  # Device
  route '/onboarding/device/plug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePlugViewController

  route '/onboarding/device/unplug', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceUnplugViewController

  route '/onboarding/device/connecting', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceConnectingViewController

  route '/onboarding/device/pin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDevicePinViewController

  route '/onboarding/device/chains/litecoin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceChainsLitecoinViewController
  
  route '/onboarding/device/chains', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceChainsViewController

  route '/onboarding/device/opening', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceOpeningViewController

  route '/onboarding/device/update', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceUpdateViewController

  route '/onboarding/device/error', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceErrorViewController

  route '/onboarding/device/unsupported', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceUnsupportedViewController

  route '/onboarding/device/failed', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceFailedViewController

  route '/onboarding/device/wrongpin', (params) ->
    app.router.go '/onboarding/device/error',
      message: _.str.sprintf t('onboarding.device.errors.wrongpin.tries_left'), params['?params'].tries_left
      indication: _.str.sprintf(t('onboarding.device.errors.wrongpin.unplug_plug'), ledger.config.network.plural)

  route '/onboarding/device/frozen', (params) ->
    app.router.go '/onboarding/device/error',
      serious: yes
      message: _.str.sprintf(t('onboarding.device.errors.frozen.blank_next_time'), ledger.config.network.plural)
      indication: _.str.sprintf(t('onboarding.device.errors.frozen.unplug_plug'), ledger.config.network.plural)

  route '/onboarding/device/forged', (params) ->
    app.router.go '/onboarding/device/error',
      message: _.str.sprintf(t('onboarding.device.errors.forged.forbidden_access'), ledger.config.network.plural)
      indication: t 'onboarding.device.errors.forged.get_help'

  route '/onboarding/device/swapped_bip39_provisioning', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceSwappedbip39provisioningViewController

  route '/onboarding/device/switch_firmware', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingDeviceSwitchfirmwareViewController

  # Management
  route '/onboarding/management/security', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSecurityViewController

  route '/onboarding/management/done', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementDoneViewController

  route '/onboarding/management/welcome', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementWelcomeViewController

  route '/onboarding/management/pinconfirmation', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementPinconfirmationViewController

  route '/onboarding/management/pin', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementPinViewController

  route '/onboarding/management/seedconfirmation', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSeedconfirmationViewController

  route '/onboarding/management/seed', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSeedViewController

  route '/onboarding/management/summary', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementSummaryViewController

  route '/onboarding/management/provisioning', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementProvisioningViewController

  route '/onboarding/management/recovery_mode', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementRecoverymodeViewController

  route '/onboarding/management/recovery_device', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementRecoverydeviceViewController

  route '/onboarding/management/convert', (params) ->
    app.navigate ONBOARDING_LAYOUT, OnboardingManagementConvertViewController

  ## Wallet
  # Accounts
  route 'wallet/accounts/index', ->
    app.navigate WALLET_LAYOUT, WalletAccountsIndexViewController

  route '/wallet/accounts/alloperations', (params) ->
    app.navigate WALLET_LAYOUT, WalletAccountsAlloperationsViewController

  route '/wallet/accounts/{id}/show', (params) ->
    app.navigate WALLET_LAYOUT, WalletAccountsShowViewController

  route '/wallet/accounts/{id}/operations', (params) ->
    app.navigate WALLET_LAYOUT, WalletAccountsOperationsViewController

  route '/wallet/accounts/{id}', (params) ->
    app.router.go "/wallet/accounts/#{params['id']}/show"

  route '/wallet/accounts', ->
    app.router.go "/wallet/accounts/index"

  # Send
  route '/wallet/send/index:?params:', (params = {}) ->
    dialog = new WalletSendIndexDialogViewController(params["?params"] or {})
    dialog.show()

  # Receive
  route '/wallet/receive/index:?params:', (params = {}) ->
    dialog = new WalletReceiveIndexDialogViewController(params["?params"] or {})
    dialog.show()

  # Settings
  route '/wallet/settings/index', (params) ->
    dialog = new WalletSettingsIndexDialogViewController()
    dialog.show()

  # Chains
  route '/wallet/switch/chains', (params) ->
    ledger.app.releaseWallet(no, no)
    tmp = {}
    tmp[ledger.app.chains.currentKey]= 0
    ledger.storage.global.chainSelector.set tmp, =>
      ledger.app.onDongleIsUnlocked(ledger.app.dongle)


  # Help
  route '/wallet/help/index', (params) ->
    window.open t 'application.support_url'

  ## Firmware Update
  route '/update/index', (params) ->
    app.navigate UPDATE_LAYOUT, UpdateIndexViewController

  route '/update/plug', (params) ->
    app.navigate UPDATE_LAYOUT, UpdatePlugViewController

  route '/update/unplug', (params) ->
    app.navigate UPDATE_LAYOUT, UpdateUnplugViewController

  route '/update/seed', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateSeedViewController

  route '/update/erasing', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateErasingViewController

  route '/update/unlocking', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateUnlockingViewController

  route '/update/updating', ->
    app.navigate UPDATE_LAYOUT, UpdateUpdatingViewController

  route '/update/loading', ->
    app.navigate UPDATE_LAYOUT, UpdateLoadingViewController

  route '/update/done', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateDoneViewController

  route '/update/linux', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateLinuxViewController

  route '/update/cardcheck', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateCardcheckViewController

  route '/update/error', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateErrorViewController

  route '/update/welcome', (param) ->
    app.navigate UPDATE_LAYOUT, UpdateWelcomeViewController

  # BitID
  route '/wallet/bitid/index', (params = {}) ->
    dialog = new WalletBitidIndexDialogViewController({ uri: params["?params"]?.uri, silent: params["?params"]?.silent })
    dialog.show()

  route '/wallet/bitid/form', (params) ->
    dialog = new WalletBitidFormDialogViewController()
    dialog.show()

  # XPubKey
  route '/wallet/xpubkey/index', (params = {}) ->
    dialog = new WalletXpubkeyIndexDialogViewController({ path: params["?params"]?.path })
    dialog.show()

  # Message
  route '/wallet/message/index', (params = {}) ->
    dialog = new WalletMessageIndexDialogViewController({ path: params["?params"]?.path, message: params["?params"]?.message })
    dialog.show()

  # P2SH
  route '/wallet/p2sh/index', (params = {}) ->
    dialog = new WalletP2shIndexDialogViewController({ inputs: params["?params"]?.inputs, scripts: params["?params"]?.scripts, outputs_number: params["?params"]?.outputs_number, outputs_script: params["?params"]?.outputs_script, paths: params["?params"]?.paths })
    dialog.show()

  ## API
  route '/wallet/api/accounts', (params = {}) ->
    dialog = new WalletApiAccountsDialogViewController()
    dialog.show()

  route '/wallet/api/operations', (params = {}) ->
    dialog = new WalletApiOperationsDialogViewController({ account_id: params["?params"]?.account_id })
    dialog.show()

  route '/wallet/api/addresses', (params = {}) ->
    dialog = new WalletApiAddressesDialogViewController({ account_id: params["?params"]?.account_id, count: params["?params"]?.count })
    dialog.show()

  ## Coinkite
  route '/apps/coinkite/dashboard/index', (params) ->
    app.navigate COINKITE_LAYOUT, AppsCoinkiteDashboardIndexViewController

  route '/apps/coinkite/settings/index', (params) ->
    dialog = new AppsCoinkiteSettingsIndexDialogViewController()
    dialog.show()

  route '/apps/coinkite/keygen/index', (params) ->
    dialog = new AppsCoinkiteKeygenIndexDialogViewController({ index: params["?params"]?.index })
    dialog.show()

  route '/apps/coinkite/keygen/processing', (params) ->
    dialog = new AppsCoinkiteKeygenProcessingDialogViewController()
    dialog.show()

  route '/apps/coinkite/cosign/index', (params) ->
    dialog = new AppsCoinkiteCosignIndexDialogViewController()
    dialog.show()

  route '/apps/coinkite/cosign/show', (params) ->
    dialog = new AppsCoinkiteCosignShowDialogViewController({ json: params["?params"]?.json })
    dialog.show()

  route '/apps/coinkite/dashboard/compatibility', (params) ->
    dialog = new AppsCoinkiteDashboardCompatibilityDialogViewController()
    dialog.show()

  route '/apps/coinkite/help/index', (params) ->
    window.open t 'application.support_coinkite_url'

  ## Specs

  route '/specs/index', ->
    app.navigate SPECS_LAYOUT, SpecIndexViewController

  route '/specs/result', ->
    app.navigate SPECS_LAYOUT, SpecResultViewController
