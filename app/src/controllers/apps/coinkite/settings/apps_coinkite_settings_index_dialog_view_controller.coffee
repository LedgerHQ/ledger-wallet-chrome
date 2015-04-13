class @AppsCoinkiteSettingsIndexDialogViewController extends DialogViewController

  view:
    apiKeyInput: '#api_key_input'
    apiSecretInput: '#api_secret_input'
    saveButton: '#save_button'

  onAfterRender: () ->
    super
    ledger.storage.sync.get "__apps_coinkite_api_key", (r) =>
      @view.apiKeyInput.val(r.__apps_coinkite_api_key)
    ledger.storage.sync.get "__apps_coinkite_api_secret", (r) =>
      @view.apiSecretInput.val(r.__apps_coinkite_api_secret)

  onShow: ->
    super
    @view.apiKeyInput.focus()

  save: ->
    ledger.storage.sync.set
      "__apps_coinkite_api_key": @view.apiKeyInput.val()
      "__apps_coinkite_api_secret": @view.apiSecretInput.val()
    @dismiss()
