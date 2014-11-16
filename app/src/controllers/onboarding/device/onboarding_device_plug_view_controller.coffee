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
    @view.spinner = ledger.spinners.createLargeSpinner(@select('div.greyed-container')[0])
    if @params.animateIntro
      do @_animateIntro

  _hideContent: (hidden, animated = yes) ->
    @view.contentContainer.children().each (index, node) =>
      node = $(node)
      if hidden == yes
        node.fadeOut(if animated then 250 else 0)
      else
        node.fadeIn(if animated then 250 else 0)

  _animateIntro: ->
#    @_hideContent yes, no
#    @view.introLogo = document.createElement 'img'
#    @view.introLogo.src = '../assets/images/onboarding/large_logo.png'
#    @view.introLogo.width = 244
#    @view.introLogo.height = 181
#    @view.introLogo.zIndex = 1000
#    @view.introLogo.style.margin = 'auto auto'
#    @view.contentContainer.append @view.introLogo
#    setTimeout =>
#      $(@view.introLogo).fadeOut 250, =>
#        @view.introLogo.remove()
#        delete @view.introLogo
#        @_hideContent no
#    , 1000
    @view.greyedContainer.hide()
    @view.actionsContainer.hide()
    @view.logoContainer.css 'z-index', '1000'
    @view.logoContainer.css 'position', 'relative'
    @view.logoContainer.css 'top', (@view.contentContainer.height() - @view.logoContainer.outerHeight()) / 2
    setTimeout =>
      @view.greyedContainer.fadeIn(750)
      @view.actionsContainer.fadeIn(750)
      @view.logoContainer.animate {top: 0}, 750
    , 1500

  openSupport: ->
    window.open t 'application.support_url'