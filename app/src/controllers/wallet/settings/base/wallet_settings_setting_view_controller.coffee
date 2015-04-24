class @WalletSettingsSettingViewController extends ViewController

  renderSelector: null

  identifier: () ->
    @className().replace 'SettingViewController', ''

  stylesheetIdentifier: -> null