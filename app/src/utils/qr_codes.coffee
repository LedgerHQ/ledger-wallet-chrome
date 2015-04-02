ledger.qr_codes ?= {}

class ledger.qr_codes.Scanner extends EventEmitter
  localStream: undefined
  mainEl: undefined
  videoEl: undefined
  canvasTagEl: undefined
  videoTagEl: undefined
  overlayEl: undefined

  startInNode: (node) ->
    return if @mainEl?
    renderedNode = $(node)
    height = renderedNode.height()
    width = renderedNode.width()

    # build els
    @mainEl = $('<div class="qrcode"></div>')
    @overlayEl = $('<div class="overlay"></div>')
    @videoEl = $('<div class="video"></div>')
    @videoTagEl = $('<video width="' + width + 'px" height="' + height + 'px"></video>')
    @canvasTagEl = $('<canvas id="qr-canvas" width="' + width + 'px" height="' + height + 'px" style="display:none;"></canvas>')
    @videoEl.append @videoTagEl
    @videoEl.append @canvasTagEl
    @mainEl.append @videoEl
    @mainEl.append @overlayEl
    renderedNode.append @mainEl

    # start capture
    navigator.webkitGetUserMedia {video: true}, (stream) =>
      @localStream = stream
      @videoTagEl.get(0).src = (window.URL && window.URL.createObjectURL(stream)) || stream
      @videoTagEl.get(0).play()
      _.delay @_decodeCallback.bind(@), 1000
      @emit 'success', stream
    , (videoError) =>
      @overlayEl.addClass 'errored'
      @overlayEl.text t 'common.qrcode.nowebcam'
      @emit 'error', videoError

    qrcode.callback = (data) =>
      @emit 'qrcode', data

  stop: ->
    return if not @mainEl?
    @localStream?.stop()
    @videoTagEl?.get(0).pause()
    @videoEl = undefined
    @canvasTagEl = undefined
    @videoTagEl = undefined
    @overlayEl = undefined
    @localStream = undefined
    @mainEl = undefined
    qrcode.callback = undefined

  _decodeCallback: ->
    if @localStream?
      try
        @canvasTagEl.get(0).getContext('2d').drawImage(@videoTagEl.get(0), 0, 0, @canvasTagEl.width(), @canvasTagEl.height())
        qrcode.decode()
      _.delay @_decodeCallback.bind(@), 250