class @OnboardingPlugViewController extends @ViewController

  _spinner: null

  _addSpinner: ->
    opts =
      lines: 9
      length: 0
      width: 3
      radius: 20
      corners: 0
      rotate: 0
      direction: 1
      color: '#000'
      speed: 0.8
      trail: 20
      shadow: false
      hwaccel: false
      className: 'spinner'
      zIndex: 0
      position: 'relative'

    @_spinner = new Spinner(opts).spin(@select('div.greyed-container')[0])

  onAfterRender: ->
    super
    do @_addSpinner