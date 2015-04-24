class @WalletReceiveIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'
    receiverAddress: "#receiver_address"

  initialize: ->
    super
    @params.address = ledger.wallet.HDWallet.instance.getAccount(0).getCurrentPublicAddress()

  onAfterRender: ->
    super
    @view.qrcode = new QRCode "qrcode_frame",
        text: @_bitcoinAddressUri()
        width: 196
        height: 196
        colorDark : "#000000"
        colorLight : "#ffffff"
        correctLevel : QRCode.CorrectLevel.H
    @view.amountInput.amountInput(ledger.preferences.instance.getBitcoinUnitMaximumDecimalDigitsCount())
    @view.receiverAddress.text @params.address
    do @_listenEvents

  onShow: ->
    super
    @view.amountInput.focus()

  mail: ->
    window.open 'mailto:?body=' + @params.address

  print: ->
    window.print()

  _listenEvents: ->
    @view.amountInput.on 'keydown', (e) =>
      _.defer =>
        @params.amount = ledger.formatters.fromSatoshiToBTC(ledger.formatters.fromValueToSatoshi(@view.amountInput.val()))
        @_refreshQrCode()

  _refreshQrCode: () ->
    @view.qrcode.makeCode(@_bitcoinAddressUri());

  _bitcoinAddressUri: ->
    uri = "bitcoin:" + @params.address
    uri += "?amount=#{@params.amount}" if @params.amount?.length > 0
    uri