class @WalletMessageIndexDialogViewController extends ledger.common.DialogViewController

  view:
    derivationPath: '#derivation_path'
    message: '#message'
    confirmButton: '#confirm_button'
    error: "#error_container"

  onAfterRender: ->
    super
    @_isEditable = @params.editable || no
    chrome.app.window.current().show()
    @view.derivationPath.val("m/" + @params.path)
    @view.message.val(@message)

    unless @_isEditable
      @view.message.attr("read-only", on)
      @view.derivationPath.attr("read-only", on)

  cancel: ->
    unless @_isEditable
      Api.callback_cancel 'sign_message', t('wallet.message.errors.cancelled')
    @dismiss()

  confirm: ->
    path = Api.cleanPath(@view.derivationPath.val())
    message = @view.message.val()
    if _.isEmpty(path) || path.match(/[^0-9\/']/ig)?
      @view.error.text(t("wallet.message.index.invalid_path"))
      return
    if _.isEmpty(message)
      @view.error.text(t("wallet.message.index.invalid_message"))
      return
    dialog = new WalletMessageProcessingDialogViewController(path: path, message: message, editable: @_isEditable)
    @getDialog().push dialog

