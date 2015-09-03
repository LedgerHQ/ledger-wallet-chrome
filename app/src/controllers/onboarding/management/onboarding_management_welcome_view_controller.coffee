class @OnboardingManagementWelcomeViewController extends @OnboardingViewController

  onBeforeRender: ->
    super
    @isSwappedBip32Compatible = ledger.app.dongle.getFirmwareInformation().hasSwappedBip39SetupSupport()