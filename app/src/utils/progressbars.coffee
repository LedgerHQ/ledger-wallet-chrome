@ledger.progressbars ?= {}

class ledger.progressbars.ProgressBar

  _el: null
  _leftEl: null
  _progress: null

  constructor: (node) ->
    @_el = $('<div class="progressbar"></div>')
    @_leftEl = $('<div class="left"></div>')
    @_el.append [@_leftEl]
    @setProgress(0)
    @setAnimated(true)
    node.append @_el

  setAnimated: (animated) ->
    if animated
      @_leftEl.css 'transition', 'width 0.25s ease-in-out'
    else
      @_leftEl.css 'transition', 'none'

  setProgress: (progress) ->
    return if (@_progress is progress) or progress < 0.0 or progress > 1.0
    @_progress = progress
    computedProgress = Math.ceil(progress * 100)
    @_leftEl.css 'width', computedProgress + '%'

  getProgress: -> return @_progress