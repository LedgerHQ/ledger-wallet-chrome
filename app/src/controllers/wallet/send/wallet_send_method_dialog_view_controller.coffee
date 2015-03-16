class @WalletSendMethodDialogViewController extends @DialogViewController

  pairMobilePhone: ->
    dialog = new WalletPairingIndexDialogViewController()
    dialog.show()
    dialog.getDialog().once 'dismiss', =>
      l 'toto'
