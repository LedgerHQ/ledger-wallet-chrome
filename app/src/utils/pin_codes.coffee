@ledger.pin_codes ?= {}
class @ledger.pin_codes.PinCode extends EventEmitter

  _el: null
  _isProtected: yes

  insertIn: (parent) ->
    return if @_el?
    @_buildEl()
    parent.appendChild @_el

  insertAfter: (node) ->
    return if @_el?
    @_buildEl()
    $(@_el).insertAfter(node)

  removeFromDom: ->
    return unless @_el?
    @_el.parentNode().removeChild(@_el)
    @_el = null

  focus: ->
    $(@_input()).focus()
    do @_updateDigits

  clear: ->
    $(@_input()).val('')
    do @_updateDigits

  setValue: (value) ->
    $(@_input()).val(value)
    do @_updateDigits

  value: ->
    @_input().value

  setEnabled: (enabled) ->
    @_input().disabled = !enabled
    do @_updateDigits

  setReadonly: (readonly) ->
    @_input().readOnly = readonly
    do @_updateDigits

  setProtected: (protect) ->
    @_isProtected = protect
    do @_updateDigits

  isEnabled: ->
    return !@_input().disabled

  isReadonly: ->
    return @_input().readOnly

  isProtected: ->
    return @_isProtected

  isComplete: ->
    return @_input().value.length == @_digits().length

  _input: ->
    return undefined unless @_el?
    $(@_el).find('input')[0]

  _digits: ->
    return undefined unless @_el?
    $(@_el).find('div')

  _buildEl: ->
    # element
    @_el = document.createElement('div')
    @_el.className = 'pincode'

    # digits
    for index in [1..4]
      digit = document.createElement('div')
      @_el.appendChild(digit)

    #input
    input = document.createElement('input')
    input.maxLength = 4
    input.type = 'password'
    @_el.appendChild(input)
    do @_listenEvents

  _listenEvents: ->
    self = @

    # listen click on digits
    for digit in @_digits()
      $(digit).on 'click', ->
        return if !self.isEnabled() or self.isReadonly()
        do self.focus
      $(digit).on 'mousedown', (e) ->
        return if !self.isEnabled() or self.isReadonly()
        e.preventDefault()

    # listen changes in input
    $(@_input()).on 'change keyup keydown focus blur', (e) ->
      return if !self.isEnabled() or self.isReadonly()
      @value = @value.replace(/[^0-9]/g, '')
      do self._updateDigits

      if e.type == 'keyup' and self.isComplete()
        self.emit 'complete' if /[0-9]/g.test @value

  _updateDigits: ->
    for index in [0..@_digits().length - 1]
      digit = @_digits()[index]
      @_setDigitFilled(digit, index < @_input().value.length && @isProtected())
      @_setDigitDisabled(digit, !@isEnabled())
      if @_input().value[index]? and !@isProtected()
        digit.innerText = @_input().value[index]
      else
        digit.innerText = ''
      if @isReadonly()
        @_setDigitFocused(digit, no)
        @_setDigitSelected(digit, no)
      else
        if $(@_input()).is ':focus'
          @_setDigitFocused(digit, yes)
          if @_input().value.length >= @_digits().length
            @_setDigitSelected(digit, no)
          else
            @_setDigitSelected(digit, index == @_input().value.length)
        else
          @_setDigitFocused(digit, no)
          @_setDigitSelected(digit, no)

  _setDigitFocused: (digit, focused) ->
    @_setDigitClassEnabled digit, 'focused', focused

  _setDigitSelected: (digit, selected) ->
    @_setDigitClassEnabled digit, 'selected', selected

  _setDigitFilled: (digit, filled) ->
    @_setDigitClassEnabled digit, 'filled', filled

  _setDigitDisabled: (digit, disabled) ->
    @_setDigitClassEnabled digit, 'disabled', disabled

  _setDigitClassEnabled: (digit, className, enabled) ->
    if enabled == on
      $(digit).addClass(className)
    else
      $(digit).removeClass(className)