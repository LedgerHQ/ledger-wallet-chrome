class @CommonDialogsQrcodeDialogViewController extends @DialogViewController

  view:
    videoCaptureContainer: '#video_capture_container'
  qrcodeCheckBlock: null

  onAfterRender: ->
    super
    @_startScanner()

  show: ->
    ledger.managers.permissions.request 'videoCapture', (granted) =>
      _.defer => super

  onDetach: ->
    super
    @_stopScanner()

  onDismiss: ->
    super
    @_stopScanner()

  _startScanner: ->
    return if @view.qrcodeScanner?
    @view.qrcodeScanner = new ledger.qr_codes.Scanner()
    @view.qrcodeScanner.on 'qrcode', (event, data) =>
      if @qrcodeCheckBlock? and @qrcodeCheckBlock(data) is true
        @emit 'qrcode', data
        @dismiss()
    @view.qrcodeScanner.startInNode @view.videoCaptureContainer

  _stopScanner: ->
    return if not @view.qrcodeScanner?
    @view.qrcodeScanner.off 'qrcode'
    @view.qrcodeScanner.stop()
    @view.qrcodeScanner = undefined