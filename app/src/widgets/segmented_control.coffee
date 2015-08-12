ledger.widgets ?= {}

Styles = {
  Small: 'small-segmented-control'
}

class ledger.widgets.SegmentedControl extends EventEmitter

  @Styles = Styles
  _el: null
  _actions: null

  constructor: (node, style) ->
    super
    @_actions = []
    @_el = $("<div class='#{style}'></div>")
    node.append @_el

  addAction: (label) ->
    action = $("<div class='action'>#{label}</div>")
    action.on 'click', => @_handleActionClick(action)
    @_el.append action
    @_actions.push action
    action

  removeAllActions: ->
    @_el.empty()
    @_actions = []

  setSelectedIndex: (index) ->
    return if index >= @_actions.length
    if @getSelectedIndex() != -1 then @_actions[@getSelectedIndex()].removeClass 'selected'
    @_actions[index].addClass 'selected'

  getSelectedIndex: ->
    for action, index in @_actions
      if action.hasClass 'selected'
        return index
    return -1

  _handleActionClick: (action) ->
    index = @_actions.indexOf action
    return if index == @getSelectedIndex()
    @setSelectedIndex index
    @emit 'selection', {action: action, index: index}