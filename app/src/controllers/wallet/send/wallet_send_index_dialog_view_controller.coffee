class @WalletSendIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'
    sendButton: '#send_button'
    totalInput: '#total_input'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'
    videoCaptureContainer: '#video_capture_container'
    qrcodeVideo: '#qrcode_video'
    openScannerButton: '#open_scanner_button'
    closeScannerButton: '#close_scanner_button'

  onAfterRender: () ->
    super
    @view.amountInput.amountInput()
    @view.errorContainer.hide()
    @view.closeScannerButton.hide()
    do @_updateTotalInput
    do @_listenEvents

  onShow: ->
    super
    @view.amountInput.focus()

  onDismiss: ->
    super
    @stopScanner()

  send: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()
      @once 'dismiss', =>
        dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress()
        dialog.show()
      @dismiss()

  openScanner: ->
    @view.videoCaptureContainer.one 'webkitTransitionEnd', =>
      @startScanner()
    @view.videoCaptureContainer.addClass 'opened'
    @view.openScannerButton.hide()
    @view.closeScannerButton.show()

  closeScanner: ->
    @view.videoCaptureContainer.one 'webkitTransitionEnd', =>
      @stopScanner()
    @view.videoCaptureContainer.removeClass 'opened'
    @view.openScannerButton.show()
    @view.closeScannerButton.hide()

  startScanner: ->
    return if @view.qrcodeScanner?
    @view.qrcodeScanner = new ledger.qr_codes.Scanner()
    @view.qrcodeScanner.on 'qrcode', (event, data) =>
      # handle data
      @closeScanner()
    @view.qrcodeScanner.startInNode @view.qrcodeVideo.get(0)

  stopScanner: ->
    return if not @view.qrcodeScanner?
    @view.qrcodeScanner.off 'qrcode'
    @view.qrcodeScanner.stop()
    @view.qrcodeScanner = undefined

  _listenEvents: ->
    @view.amountInput.on 'keydown', =>
      _.defer =>
        @_updateTotalInput yes

  _receiverBitcoinAddress: ->
    _.str.trim(@view.receiverInput.val())

  _transactionAmount: ->
    _.str.trim(@view.amountInput.val())

  _nextFormError: ->
    # check amount
    if @_transactionAmount().length == 0 or not ledger.wallet.Value.from(@_transactionAmount()).gt(0)
      return t 'common.errors.invalid_amount'
    else if not Bitcoin.Address.validate @_receiverBitcoinAddress()
      return t 'common.errors.invalid_receiver_address'
    undefined

  _updateTotalInput: ->
    val = parseInt(ledger.wallet.Value.from(@_transactionAmount()).add(10000).toString()) #+ 0.0001 btc
    @view.totalInput.text ledger.formatters.bitcoin.fromValue(val) + ' BTC ' + t 'wallet.send.index.transaction_fees_text'