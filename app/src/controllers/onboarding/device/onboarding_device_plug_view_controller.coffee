class @OnboardingDevicePlugViewController extends @OnboardingViewController

  defaultParams:
    animateIntro: no
  view:
    contentContainer: '#content-container'
    logoContainer: '.logo-container'
    greyedContainer: '.greyed-container'
    actionsContainer: '.actions-container'

  onAfterRender: ->
    super
    if @params.animateIntro is true
      do @_animateIntro
    else
      do @_listenEvents

  openSupport: ->
    window.open t 'application.support_key_not_recognized_url'

  _hideContent: (hidden, animated = yes) ->
    @view.contentContainer.children().each (index, node) =>
      node = $(node)
      if hidden == yes
        node.fadeOut(if animated then 250 else 0)
      else
        node.fadeIn(if animated then 250 else 0)

  _animateIntro: ->
    @view.greyedContainer.hide()
    @view.actionsContainer.hide()
    @view.logoContainer.css 'z-index', '1000'
    @view.logoContainer.css 'position', 'relative'
    @view.logoContainer.css 'top', (@view.contentContainer.height() - @view.logoContainer.outerHeight()) / 2
    setTimeout =>
      do @_listenEvents
      @view.greyedContainer.fadeIn(750)
      @view.actionsContainer.fadeIn(750)
      @view.logoContainer.animate {top: 0}, 750
    , 1500

  navigateContinue: ->
    ledger.app.router.go '/onboarding/device/connecting'

  _listenEvents: ->
    if (ledger.app.wallet? and !ledger.app.wallet.isInBootloaderMode()) or ledger.app.isConnectingDongle()
      do @navigateContinue
    else
      ledger.app.once 'dongle:connecting', =>
        do @navigateContinue