ledger.widgets ?= {}

class ledger.widgets.CircleProgressBar extends EventEmitter

  constructor: (node, {width, height} = {}) ->
    node.width(width) if width?
    node.height(height) if height?
    node.addClass("circle-progress-bar-container")
    @_view = new ProgressBar.Circle node.selector,
      color: '#999999'
      trailColor: '#CCCCCC'
      strokeWidth: 3
      trailWidth: 3
      text:
        className: 'progress-text'
        style:
          color: '#000'
          position: 'absolute'
          left: '50%'
          top: '50%'
          padding: 0
          margin: 0
        transform:
          prefix: true
          value: 'translate(-50%, -50%)'

      step: (state, bar) =>
        bar.setText((bar.value() * 100).toFixed(0) + '%');


  setProgress: (progress, animated = yes) ->
    if animated
      @_view.animate(progress)
