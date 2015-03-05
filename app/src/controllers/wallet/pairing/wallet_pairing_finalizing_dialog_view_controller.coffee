class @WalletPairingFinalizingDialogViewController extends DialogViewController

  view:
    phoneNameInput: '#phone_name_input'
    errorLabel: "#error_label"

  onAfterRender: ->
    super
    @_request = @params.request
    @_request?.onComplete (screen, error) =>
      @_request = null
      if screen?
        @getDialog().push new WalletPairingSuccessDialogViewController(screen: screen)
      else
        @getDialog().push new WalletPairingErrorDialogViewController(reason: error)
    @view.errorLabel.hide()
    @view.phoneNameInput.val(t 'wallet.pairing.finalizing.default_name')
    _.defer =>
      @view.phoneNameInput.focus()
      @view.phoneNameInput.on 'blur', =>
        @view.phoneNameInput.focus()

  terminate: ->
    @_verifyEnteredName (showedError) =>
      @_request?.setSecureScreenName(@_enteredName()) if showedError is false

  onDismiss: ->
    super
    @_request?.cancel()

  onDetach: ->
    super
    @view.phoneNameInput.off 'blur'

  _enteredName: ->
    return _.str.trim(@view.phoneNameInput.val())

  _verifyEnteredName: (completion) ->
    name = @_enteredName()
    resultBlock = (message) =>
      # check message
      if message?
        @view.errorLabel.text(message)
        @view.errorLabel.show()
        completion?(true)
      else
        @view.errorLabel.text("")
        @view.errorLabel.hide()
        completion?(false)
    # check name
    if name.length == 0
      resultBlock(t 'wallet.pairing.finalizing.please_enter_a_name')
    else
      ledger.m2fa.PairedSecureScreen.getByNameFromSyncedStore name, (screen) =>
        resultBlock(if screen? then t 'wallet.pairing.finalizing.name_already_used_by_paired_device' else null)