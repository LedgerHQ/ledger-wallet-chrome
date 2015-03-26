@ledger.progressbars ?= {}

class ledger.progressbars.ProgressBar

  _el: null
  _rightEl: null
  _leftEl: null
  _progress: null

  constructor: (node) ->
    @_el = $('<div class="progressbar"></div>')
    @_rightEl = $('<div class="right"></div>')
    @_leftEl = $('<div class="left"></div>')
    @_el.append [@_leftEl, @_rightEl]
    @setProgress(0)
    node.append @_el

  setProgress: (progress) ->
    return if (@_progress is progress) or progress < 0.0 or progress > 1.0
    @_progress = progress
    computedProgress = Math.ceil(progress * 100)
    @_leftEl.css 'width', computedProgress + '%'
    @_rightEl.css 'width', 100 - computedProgress + '%'

  getProgress: -> return @_progress