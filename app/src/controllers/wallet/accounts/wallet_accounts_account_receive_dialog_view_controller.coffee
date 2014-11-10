
class @WalletAccountsAccountReceiveDialogViewController extends DialogViewController

  refreshQrCode: () ->
    @qrcode.makeCode(@bitcoinAddressUri());

  bitcoinAddressUri: ->
    uri = "bitcoin:" + @params.address
    uri += "?amount=#{@params.amount}" if @params.amount?.length > 0
    uri

  onBeforeRender: () ->
    @params.address = '1DDGTMZUxwYwRdWcyVBmSrGEoVXkVTd6xS'

  onAfterRender: () ->
    super
    @qrcode = new QRCode "qrcode_frame",
        text: @bitcoinAddressUri()
        width: 196
        height: 196
        colorDark : "#000000"
        colorLight : "#ffffff"
        correctLevel : QRCode.CorrectLevel.H
    @select('#amount_input').keepFocus()
    @select('#amount_input').numberInput()
    @select('#amount_input').on 'keydown', (e) =>
      setTimeout =>
        @params.amount = @select('#amount_input').val()
        @refreshQrCode()
      , 0

  onShow: ->
    super
    @select('#amount_input').focus()