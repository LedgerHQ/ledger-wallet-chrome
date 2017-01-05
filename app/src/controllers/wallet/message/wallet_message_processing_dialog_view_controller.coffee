class @WalletMessageProcessingDialogViewController extends ledger.common.DialogViewController

  view:
    contentContainer: '#content_container'
    hash: "#message_hash"

  onAfterRender: ->
    super
    hash = ledger.crypto.SHA256.hashString(@params.message).toUpperCase()
    @view.hash.text(hash.substr(0, 4) + "..." + hash.substr(-4))
    try
      ledger.bitcoin.bitid.getAddress path: @params.path
      .then (result) =>
        address = result.bitcoinAddress.value
        ledger.bitcoin.bitid.signMessage(@params.message, path: @params.path)
        .then (result) =>
          Api.callback_success('sign_message', signature: result, address: address)
          @dismiss =>
            if @params.editable
              dialog = new WalletMessageResultDialogViewController(signature: result, address: address, message: @params.message)
            else
              dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("wallet.message.errors.sign_message_successfull"))
            dialog.show()
          return
        .fail (error) =>
          Api.callback_cancel('sign_message', JSON.stringify(error))
          @dismiss =>
            dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.message.errors.sign_message_failed"), subtitle: error)
            dialog.show()
          return
      .fail (error) =>
        Api.callback_cancel('sign_message', JSON.stringify(error))
        @dismiss =>
          dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.message.errors.derivation_failed"), subtitle: error)
          dialog.show()
        return
    catch error
      Api.callback_cancel('sign_message', JSON.stringify(error))
      @dismiss =>
        dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.message.errors.sign_message_failed"), subtitle: error)
        dialog.show()


