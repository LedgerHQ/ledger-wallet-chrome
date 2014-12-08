ledger.qr_codes ?= {}

class ledger.qr_codes.Scanner extends EventEmitter
  renderedNode: undefined
  localStream: undefined
  videoEl: undefined
  canvasEl: undefined
  overlayEl: undefined

  startInNode: (node) ->
    return if @renderedNode?
    @renderedNode = $(node)
    height = @renderedNode.height()
    width = @renderedNode.width()

    overlayEl = $('<div id="qrcode_overlay"></div>').appendTo(@renderedNode)
    @overlayEl = overlayEl.get(0)
    videoEl = $('<video width="' + width + 'px" height="' + height + 'px"></video>').appendTo(@renderedNode)
    @videoEl = videoEl.get(0)
    canvasEl = $('<canvas id="qr-canvas" width="' + width + 'px" height="' + height + 'px" style="display:none;"></canvas>').appendTo(@renderedNode)
    @canvasEl = canvasEl.get(0)

    navigator.webkitGetUserMedia {video: true},
    (stream) =>
      @localStream = stream
      @videoEl.src = (window.URL && window.URL.createObjectURL(stream)) || stream
      @videoEl.play()
      _.delay @_decodeCallback.bind(@), 1000
      @emit 'success', stream
    ,
    (videoError) =>
      $(@overlayEl).addClass 'errored'
      $(@overlayEl).text t 'common.qrcode.nowebcam'
      @emit 'error', videoError

    qrcode.callback = (data) =>
      @emit 'qrcode', data

  stop: ->
    return if not @renderedNode?
    @localStream.stop() if @localStream?
    @videoEl.pause()
    $(@videoEl).remove()
    $(@canvasEl).remove()
    $(@overlayEl).remove()
    @videoEl = undefined
    @canvasEl = undefined
    @renderedNode = undefined
    @localStream = undefined
    qrcode.callback = undefined

  _decodeCallback: ->
    if @localStream?
      try
        @canvasEl.getContext('2d').drawImage(@videoEl, 0, 0, $(@canvasEl).width(), $(@canvasEl).height());
        qrcode.decode()
      _.delay @_decodeCallback.bind(@), 250