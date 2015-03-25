class @WalletSendIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'
    sendButton: '#send_button'
    totalInput: '#total_input'
    errorContainer: '#error_container'
    receiverInput: '#receiver_input'
    videoCaptureContainer: '#video_capture_container'
    qrcodeVideo: '#qrcode_video'
    qrcodeIndication: '#qrcode_indication'
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

  onDetach: ->
    super
    @_stopScanner()

  onDismiss: ->
    super
    @_stopScanner()

  send: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()
      dialog = new WalletSendPreparingDialogViewController amount: @_transactionAmount(), address: @_receiverBitcoinAddress()
      @getDialog().push dialog

  openScanner: ->
    successBlock = =>
      @view.errorContainer.hide()
      @view.videoCaptureContainer.one 'webkitTransitionEnd', =>
        @startScanner()
      @view.videoCaptureContainer.addClass 'opened'
      @view.openScannerButton.hide()
      @view.closeScannerButton.show()

    ledger.managers.permissions.request 'videoCapture', (granted) =>
      if granted
        _.defer => successBlock()

  closeScanner: ->
    @view.videoCaptureContainer.one 'webkitTransitionEnd', =>
      @_stopScanner()
    @view.videoCaptureContainer.removeClass 'opened'
    @view.openScannerButton.show()
    @view.closeScannerButton.hide()

  startScanner: ->
    return if @view.qrcodeScanner?
    @view.qrcodeScanner = new ledger.qr_codes.Scanner()
    @view.qrcodeScanner.once 'error', (event, data) =>
      @view.qrcodeIndication.hide()
    @view.qrcodeScanner.once 'success', (event, data) =>
      @view.qrcodeIndication.show()
    @view.qrcodeScanner.on 'qrcode', (event, data) =>
      # handle data
      params = ledger.managers.schemes.bitcoin.parseURI data
      if params?
        @view.amountInput.val params.amount if params.amount?
        @view.receiverInput.val params.address if params.address?
        @_updateTotalInput()
        @closeScanner()
    @view.qrcodeScanner.startInNode @view.qrcodeVideo.get(0)

  _stopScanner: ->
    return if not @view.qrcodeScanner?
    @view.qrcodeScanner.off 'qrcode'
    @view.qrcodeScanner.off 'error'
    @view.qrcodeScanner.off 'success'
    @view.qrcodeScanner.stop()
    @view.qrcodeScanner = undefined

  _listenEvents: ->
    @view.amountInput.on 'keydown', =>
      _.defer =>
        @_updateTotalInput yes
    @view.openScannerButton.on 'click', =>
      @openScanner()

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
    @view.totalInput.text ledger.formatters.fromValue(val) + ' BTC ' + t 'wallet.send.index.transaction_fees_text'