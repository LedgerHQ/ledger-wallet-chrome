ledger.widgets ?= {}

###
  Switch
###
class ledger.widgets.Switch extends EventEmitter

  # @param The node on which the switch will be appended to
  constructor: (node) ->
    @_switchEl = $('<div class="switch"><div class="circle"></div></div>')
    @_switchEl.appendTo(node)
    @_switchEl.click =>
      @setOn(!@isOn(), true)
      @emit (if @isOn() then "isOn" else "isOff")

  ###
    Set switch state
    @param [Boolean] state The state of the switch
    @param [Boolean] isAnimated If the switch must be animated
  ###
  setOn: (state, isAnimated = false) ->
    if isAnimated
      @_switchEl.addClass('animated')
    else
      @_switchEl.removeClass('animated')

    if state is on
      @_switchEl.addClass('on')
    else
      @_switchEl.removeClass('on')
    state

  # Get switch state
  isOn: -> @_switchEl.hasClass('on')