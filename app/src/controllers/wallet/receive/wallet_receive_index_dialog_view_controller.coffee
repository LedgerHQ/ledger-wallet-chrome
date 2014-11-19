class @WalletReceiveIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'

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
    @view.amountInput.amountInput()
    do @_listenEvents

  onShow: ->
    super
    @view.amountInput.focus()

  _listenEvents: ->
    @view.amountInput.on 'keydown', (e) =>
      _.defer =>
        @params.amount = @view.amountInput.val()
        @_refreshQrCode()

  _refreshQrCode: () ->
    @view.qrcode.makeCode(@_bitcoinAddressUri());

  _bitcoinAddressUri: ->
    uri = "bitcoin:" + @params.address
    uri += "?amount=#{@params.amount}" if @params.amount?.length > 0
    uri