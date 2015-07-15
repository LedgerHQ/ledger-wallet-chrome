class @WalletDialogsXpubDialogViewController extends ledger.common.DialogViewController

  view:
    codeContainer: '#code_container'

  _xpub: null

  show: ->
    @_xpub = "salut"
    super

  onAfterRender: ->
    super
    # configure view
    @view.codeContainer.text @_xpub
    @view.qrcode = new QRCode "qrcode_container",
      text: @_xpub
      width: 196
      height: 196
      colorDark : "#000000"
      colorLight : "#ffffff"
      correctLevel : QRCode.CorrectLevel.H

  email: -> window.open 'mailto:?body=' + @_xpub

  print: -> window.print()

  _getAccount: () ->
    @_account ?= Account.find(index: @params.account_id).first()
    @_account