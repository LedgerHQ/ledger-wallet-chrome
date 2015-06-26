###
  ActionBarViewController holds an action bar containing actions buttons and breadcrumbs declared by its child.
###
class ledger.common.ActionBarNavigationController extends ledger.common.NavigationController

  push: (viewController) ->
    super viewController
    @updateActionBar()

  onAfterRender: ->
    super
    @updateActionBar()

  updateActionBar: ->
    l 'Action bar update'
    unless @topViewController().getActionBarDeclaration?
      @getActionBar().hide()
      return
    @getActionBar().show()
    declaration = @topViewController().getActionBarDeclaration()
    actionBar = @getActionBar().edit()
    actionBar.clearAll()
    for action in declaration.actions
      {title, icon, url} = action
      actionBar.addAction(title, icon, url)
    for breadcrumbPart in declaration.breadcrumb
      {title, url} = breadcrumbPart
      actionBar.addBreadcrumbPart(title, url)
    actionBar.commit()

  getActionBar: -> @_actionBar ||= new @constructor.ActionBar(@getActionBarDrawer())

  getActionBarDrawer: -> null

class Action

  constructor: (@actionBar, @title, @icon, @url) ->

  remove: -> @actionBar.removeAction(this)


class BreadcrumbPart

  constructor: (@actionBar, @title, @url) ->

  remove: -> @actionBar.removeBreadcrumbPart(this)

###
  ActionBar interface for managing actions and breadcrumbs
###
class ledger.common.ActionBarNavigationController.ActionBar

  constructor: (drawer) ->
    @_isInEditMode = no
    @_actions = []
    @_breadcrumb = []
    @_drawer = drawer
    @_invalidate = @_invalidate.bind(this)

  ###
    Create a new action and insert it in the action bar
  ###
  addAction: (title, icon, url, position = -1) ->
    action = new Action(this, title, icon, url)
    if position isnt -1
      @_actions = @_actions.slice(0, position).concat([action]).concat(@_actions.slice(position))
    else
      @_actions.push action
    @invalidate()

  addBreadcrumbPart: (title, url, position = -1) ->
    part = new BreadcrumbPart(this, title, url)
    if position isnt -1
      @_breadcrumb = @_breadcrumb.slice(0, position).concat([part]).concat(@_breadcrumb.slice(position))
    else
      @_breadcrumb.push part
    @invalidate()

  removeAction: (action) ->
    @_actions = _(@_actions).without(action)
    @invalidate()

  removeBreadcrumbPart: (part) ->
    @_breadcrumb = _(@_breadcrumb).without(part)
    @invalidate()

  getActions: -> @_actions
  getBreadcrumb: -> @_breadcrumb

  clearAll: ->
    @clearActions()
    @clearBreadcrumb()
    @invalidate()

  clearActions: ->
    @_actions = []
    @invalidate()
    @

  clearBreadcrumb: ->
    @_breadcrumb = []
    @invalidate()
    @

  invalidate: ->
    clearTimeout @_invalidateTimeout if @_invalidateTimeout?
    @_invalidateTimeout = _.defer(@_invalidate) unless @_isInEditMode
    @

  _invalidate: ->
    @_drawer?.draw @_breadcrumb, @_actions

  edit: ->
    @_isInEditMode = yes
    @invalidate()

  commit: ->
    @_isInEditMode = no
    @_invalidate()
    @

  hide: ->
    # TODO

  show: ->
    # TODO

class ledger.common.ActionBarNavigationController.ActionBar.Drawer

  constructor: ->
    @_breadcrumbNodes = []
    @_actionsNodes = []

  createBreadcrumbPartView: (title, url, position) -> null

  createBreadcrumbSeparatorView: (position) -> null

  createActionView: (title, icon, url, position) -> null

  createActionSeparatorView: (position) -> null

  getActionBarHolderView: -> null

  getBreadCrumbHolderView: -> null

  getActionsHolderView: -> null

  draw: (breadcrumb, actions) ->
    breadcrumbNode.remove() for breadcrumbNode in @_breadcrumbNodes
    actionNode.remove() for actionNode in @_actionsNodes
    @_breadcrumbNodes = []
    @_actionsNodes = []
    for breadcrumbPart, index in breadcrumb
      if index > 0
        separatorNode = @createBreadcrumbSeparatorView(index)
        if separatorNode?
          @_breadcrumbNodes.push separatorNode
          @getBreadCrumbHolderView()?.append(separatorNode)
      node = @createBreadcrumbPartView(breadcrumbPart.title, breadcrumbPart.url, index)
      if node?
        @_breadcrumbNodes.push node
        @getBreadCrumbHolderView()?.append(node)

    for action, index in actions
      if index > 0
        separatorNode = @createActionSeparatorView(index)
        if separatorNode?
          @_actionsNodes.push separatorNode
          @getActionsHolderView()?.append(separatorNode)
      node = @createActionView(action.title, action.icon, action.url, index)
      if node?
        @_actionsNodes.push node
        @getActionsHolderView()?.append(node)
    return

  hide: ->
    # TODO hide