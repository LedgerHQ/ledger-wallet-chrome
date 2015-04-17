ledger.widgets ?= {}
###
  Switch
###
class ledger.widgets.Switch extends EventEmitter

  # @param The node on which the switch will be appended to
  constructor: (node) ->
    @_switchEl = $('<div class="switch"><div class="switch-circle"></div></div>')
    @_switchEl.appendTo(node)
    @_switchEl.click =>
      if @isOn()
        @setOn(no)
      else
        @setOn(yes)

  ###
    Set switch state
    @param [Boolean] state The state of the switch
    @param [Boolean] isAnimated If the switch must be animated
  ###
  setOn: (state, isAnimated=true) ->
    if state is on
      @emit 'switch:on'
      @_switchEl.addClass('switch-isOn')
      $(@_switchEl.children()[0]).addClass('switch-circle-isOn')
    else
      @emit 'switch:off'
      @_switchEl.removeClass('switch-isOn')
      $(@_switchEl.children()[0]).removeClass('switch-circle-isOn')

    if isAnimated
      @_switchEl.addClass('switch-isAnimated')
      $(@_switchEl.children()[0]).addClass('switch-circle-isAnimated')
    else
      l '(false, false)'
      @_switchEl.removeClass('switch-isAnimated')
      $(@_switchEl.children()[0]).removeClass('switch-circle-isAnimated')
    undefined


# Get switch state
  isOn: ->
    @_switchEl.hasClass('switch-isOn')

