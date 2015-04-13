class @WalletSettingsSectionDialogViewController extends DialogViewController

  settingViewControllersClasses: [] # [FirstViewControllerClass, AnotherViewControllerClass, ...]
  _settingViewControllersInstances: {} # {FirstViewControllerClass: instance}

  onAfterRender: ->
    super
    @_reloadSettingViewControllers()

  openOtherSettings: ->
    @getDialog().push (new WalletSettingsIndexDialogViewController())

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
      value.onDetach()
    @_settingViewControllersInstances = {}

  _reloadSettingViewControllers: ->
    # clear existing instances
    @_killSettingViewControllers()

    # loop through classes
    for className in @settingViewControllersClasses
      continue if not className?

      # instantiate view controller
      instance = new className

      # get render node
      renderNode = @select instance.renderSelector
      continue if not renderNode?

      # retain instance
      @_settingViewControllersInstances[className] = instance
      instance.onAttach()

      # render view controller
      instance.render(renderNode)