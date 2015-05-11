class @WalletPairingFinalizingDialogViewController extends ledger.common.DialogViewController

  cancellable: no

  view:
    phoneNameInput: '#phone_name_input'
    errorLabel: "#error_label"

  onAfterRender: ->
    super
    @_request = @params.request
    @_request?.onComplete @_onComplete

    # setup ui
    @view.errorLabel.hide()
    suggestedName = if @_request.getSuggestedDeviceName()?.length == 0 then t 'wallet.pairing.finalizing.default_name' else @_request.getSuggestedDeviceName()
    @view.phoneNameInput.val(suggestedName)

    # update input
    _.defer =>
      @view.phoneNameInput.focus()
      @view.phoneNameInput.on 'blur', =>
        @view.phoneNameInput.focus()

  terminate: ->
    @_verifyEnteredName().then => @_request?.setSecureScreenName(@_enteredName())

  onDismiss: ->
    super
    @_request?.cancel()

  onDetach: ->
    super
    @view.phoneNameInput.off 'blur'

  _enteredName: ->
    return _.str.trim(@view.phoneNameInput.val())

  _onComplete: (screen, error) ->
    l screen, error
    @_request = null
    @dismiss =>
      if screen?
        dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.pairing.errors.pairing_succeeded"), subtitle: _.str.sprintf(t("wallet.pairing.errors.dongle_is_now_paired"), screen.name))
      else
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.pairing.errors.pairing_failed"), subtitle: t("wallet.pairing.errors." + error))
      dialog.show()

  _verifyEnteredName: ->
    d = ledger.defer()
    resultBlock = (message) =>
      # check message
      if message?
        @view.errorLabel.text(message)
        @view.errorLabel.show()
        d.reject(message)
      else
        @view.errorLabel.text("")
        @view.errorLabel.hide()
        d.resolve()
    # check name
    name = @_enteredName()
    if name.length == 0
      resultBlock(t 'wallet.pairing.finalizing.please_enter_a_name')
    else
      ledger.m2fa.PairedSecureScreen.getByNameFromSyncedStore name, (screen) =>
        resultBlock(if screen? then t 'wallet.pairing.finalizing.name_already_used_by_paired_device' else null)
    d.promise
