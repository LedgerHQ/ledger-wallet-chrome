class @OnboardingNavigationController extends @NavigationController

  render: (selector) ->
    super
    do @onBeforeRender
    @emit 'beforeRender', @
    @topViewController.render selector
    do @onAfterRender
    @emit 'afterRender', @