class @WalletMessageIndexDialogViewController extends ledger.common.DialogViewController

  view:
    derivationPath: '#derivation_path'
    addressSelect: '#address'
    message: '#message'
    confirmButton: '#confirm_button'
    error: "#error_container"

  onAfterRender: ->
    super
    @_isEditable = @params.editable || no
    chrome.app.window.current().show()
    @view.derivationPath.val("m/" + Api.cleanPath(@params.path))
    @view.message.val(@params.message)
    unless @_isEditable
      @view.message.attr("readonly", on)
      @view.derivationPath.attr("readonly", on)
      @view.addressSelect.hide()
    else
      @view.derivationPath.hide()
      @view.addressSelect.show()
      for pair in ledger.wallet.Wallet.instance.getAllAddresses()
        @view.addressSelect.append("<option value=\"#{pair.key}\">#{pair.value}</option>")
      @view.addressSelect.chosen()
      $('.chosen-container').css(width: '100%')

  cancel: ->
    unless @_isEditable
      Api.callback_cancel 'sign_message', t('wallet.message.errors.cancelled')
    @dismiss()

  confirm: ->
    path = Api.cleanPath(@view.derivationPath.val())
    if @_isEditable
      path = Api.cleanPath(@view.addressSelect.val())
    message = @view.message.val()
    if !ledger.app.dongle.getFirmwareInformation().hasScreenAndButton() and !path.startsWith(ledger.bitcoin.bitid.ROOT_PATH)
      @view.error.text(t("wallet.message.index.unsupported_path"))
      return
    if _.isEmpty(path) || path.match(/[^0-9\/'xa-f]/ig)?
      @view.error.text(t("wallet.message.index.invalid_path"))
      return
    if _.isEmpty(message)
      @view.error.text(t("wallet.message.index.invalid_message"))
      return
    dialog = new WalletMessageProcessingDialogViewController(path: path, message: message, editable: @_isEditable)
    @getDialog().push dialog

