
class @WalletAccountsAccountReceiveDialogViewController extends DialogViewController

  refreshQrCode: () ->
    @qrcode.makeCode(@bitcoinAddressUri());

  bitcoinAddressUri: ->
    uri = "bitcoin:" + @params.address
    uri += "?amount=#{@params.amount}" if @params.amount?
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
    @select('#amount_input').on 'keydown', (e) =>
      setTimeout =>
        @params.amount = @select('#amount_input').val()
        @refreshQrCode()
      , 0
      return if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) != -1 or (e.keyCode == 65 && e.ctrlKey == true) or (e.keyCode >= 35 && e.keyCode <= 39))
      if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105))
        e.preventDefault()
