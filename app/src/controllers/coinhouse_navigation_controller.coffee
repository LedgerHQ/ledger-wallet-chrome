class @CoinhouseNavigationController extends @NavigationController

  childViewControllerContentId: 'coinhouse_navigation_controller_content'

  render: (selector) ->
    super
    do @onBeforeRender
    @emit 'beforeRender', @
    render 'coinhouse_navigation_controller_layout', @, (html) =>
      selector.html(html)
      do @renderChild
      do @onAfterRender
      @emit 'afterRender', @
