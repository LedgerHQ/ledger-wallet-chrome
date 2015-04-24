class @WalletSettingsSectionDialogViewController extends DialogViewController

  settingViewControllersClasses: [] # [FirstViewControllerClass, AnotherViewControllerClass, ...]
  _settingViewControllersInstances: {} # {FirstViewControllerClass: instance}
  _childrenRenderCount = 0

  render: (selector) ->
    # before render
    @renderedSelector = selector
    do @onBeforeRender
    @emit 'beforeRender', {sender: @}

    # render self
    render @viewPath(), @, (html) =>
      mainNode = $(html)

      # render children
      @once 'children:rendered', =>
        # set css
        @setControllerStylesheet =>
          # insert in dom
          selector.empty().append mainNode

          # after render
          @_isRendered = yes
          do @onAfterRender
          @emit 'afterRender', {sender: @}
      @_reloadSettingViewControllers(mainNode)

  openOtherSettings: ->
    @getDialog().pop()

  identifier: () ->
    @className().replace 'SectionDialogViewController', ''

  onDetach: ->
    super
    @_killSettingViewControllers()

  handleAction: (actionName, params) ->
    for key, value of @_settingViewControllersInstances
      if value.handleAction(actionName, params) is yes
        return yes
    return super(actionName, params)

  _killSettingViewControllers: ->
    for key, value of @_settingViewControllersInstances
      value.parentViewController = undefined
      value.onDetach()
    @_settingViewControllersInstances = {}

  _reloadSettingViewControllers: (mainNode) ->
    # clear existing instances
    @_killSettingViewControllers()
    @_childrenRenderCount = 0

    # loop through classes
    for className in @settingViewControllersClasses
      continue if not className?

      # instantiate view controller
      instance = new className

      # get render node
      renderNode = mainNode.find instance.renderSelector
      continue if not renderNode?

      # retain instance
      @_settingViewControllersInstances[className] = instance
      instance.parentViewController = @
      instance.onAttach()

      # render view controller
      instance.render(renderNode)
      instance.once 'afterRender', @_childrenRenderCallback.bind(@)

  _childrenRenderCallback: ->
    @_childrenRenderCount++
    if @_childrenRenderCount >= @settingViewControllersClasses.length
      @emit 'children:rendered'