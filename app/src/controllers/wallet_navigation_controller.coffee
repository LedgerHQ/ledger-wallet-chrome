class @WalletNavigationController extends @NavigationController

  render: (selector) ->
    super
    do @onBeforeRender
    @emit 'beforeRender', @
    render 'wallet_navigation_controller_layout', @, (html) =>
      selector.html(html)
      do @renderChild
      do @onAfterRender
      @emit 'afterRender', @
