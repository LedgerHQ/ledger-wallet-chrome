class @AppsCoinkiteKeygenIndexDialogViewController extends DialogViewController

  cancellable: no

  view:
    derivationPath: '#derivation_path'

  onAfterRender: ->
    super
    chrome.app.window.current().show()

  cancel: ->
    Api.callback_cancel 'coinkite_get_xpubkey', t("apps.coinkite.keygen.errors.cancelled")
    @dismiss()

  confirm: ->
    dialog = new AppsCoinkiteKeygenProcessingDialogViewController index: @params.index, api: true
    @getDialog().push dialog