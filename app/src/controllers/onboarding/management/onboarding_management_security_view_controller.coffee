class @OnboardingManagementSecurityViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/pin'

  onAfterRender: ->
    super
    firmware = ledger.app.dongle.getFirmwareInformation()
    if firmware.hasSubFirmwareSupport() and not firmware.hasSetupFirmwareSupport()
      ledger.app.router.go '/onboarding/management/switch_firmware', _.extend(_.clone(@params), mode: 'setup', on_done: '/onboarding/management/security')