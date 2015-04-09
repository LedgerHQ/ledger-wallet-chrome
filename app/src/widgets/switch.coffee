ledger.widgets ?= {}
###
  Switch
###
class ledger.widgets.Switch extends EventEmitter

  # @param The node to which the switch will be appended to
  constructor: (node) ->
    @_switchEl = $('<div class="switch"><div class="switch-circle"></div></div>')
    @_switchEl.appendTo(node)

  ###
    Set switch state
    @param [Boolean] state The state of the switch
    @param [Boolean] isAnimated If the switch must be animated
  ###
  setOn: (state, isAnimated) ->
    if state is on
      @_switchEl.addClass('switch-isOn')
      $(@_switchEl.children()[0]).addClass('switch-circle-isOn')
      if isAnimated?
        if isAnimated is yes
          $(@_switchEl.children()[0]).addClass('switch-circle-isOn-isAnimated')
          @_switchEl.addClass('switch-isAnimated')
      else
        # Default to Animated
        $(@_switchEl.children()[0]).addClass('switch-circle-isOn-isAnimated')
        @_switchEl.addClass('switch-isAnimated')
    else
      @_switchEl.removeClass('switch-isOn')
      $(@_switchEl.children()[0]).removeClass('switch-circle-isOn')
      if isAnimated?
        if isAnimated is yes
          $(@_switchEl.children()[0]).addClass('switch-circle-isAnimated')
          @_switchEl.addClass('switch-isAnimated')
    undefined




# Get switch state
  isOn: ->
    @_switchEl.hasClass('switch-isOn')

