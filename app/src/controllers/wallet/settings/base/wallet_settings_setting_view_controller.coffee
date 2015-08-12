class @WalletSettingsSettingViewController extends ledger.common.ViewController

  renderSelector: null

  identifier: () ->
    @className().replace 'SettingViewController', ''

  stylesheetIdentifier: -> null