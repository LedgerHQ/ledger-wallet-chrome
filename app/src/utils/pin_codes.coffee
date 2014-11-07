@ledger.pin_codes ?= {}

# This class represents a visual pin code input composed of 4 digits.
class @ledger.pin_codes.PinCode extends EventEmitter

  _el: null
  _isProtected: yes

  # Convenience method to insert the pin code inside a given parent node.
  # The pin code is always appended at the bottom child list.
  # @param [Node] parent The parent node in which insert the pin code.
  insertIn: (parent) ->
    return if @_el?
    @_buildEl()
    parent.appendChild @_el

  # Convenience method to insert the pin code after a given node.
  # The pin code is always inserted as a sibling of the given node.
  # @param [Node] node The soon-to-be sibling node.
  insertAfter: (node) ->
    return if @_el?
    @_buildEl()
    $(@_el).insertAfter(node)

  # Removes the pin code from the DOM.
  removeFromDom: ->
    return unless @_el?
    @_el.parentNode().removeChild(@_el)
    @_el = null

  # Sets focus to the pin code.
  focus: ->
    $(@_input()).focus()
    do @_updateDigits

  # Clears all entered inputs.
  clear: ->
    $(@_input()).val('')
    do @_updateDigits

  # Sets a new value.
  # @param [Number|String] A new value.
  setValue: (value) ->
    $(@_input()).val(value)
    do @_updateDigits

  # Gets the current pin code value.
  # @return [String] The current pin value.
  value: ->
    @_input().value

  # Sets the pin code as enabled.
  # Enabled pin codes accepts inputs and can send events.
  # @param [Boolean] enabled Whether or not enable the pin code.
  setEnabled: (enabled) ->
    @_input().disabled = !enabled
    do @_updateDigits

  # Sets the pin code as readonly.
  # Readonly pin codes don't allow any input.
  # @param [Boolean] readonly Whether or not set the pin code as readonly.
  setReadonly: (readonly) ->
    @_input().readOnly = readonly
    do @_updateDigits

  # Sets the pin code as protected. By default, all pin codes are protected.
  # Protected pin codes show dots instead of their real value.
  # @param [Boolean] protect Whether or not protect the pin code.
  setProtected: (protect) ->
    @_isProtected = protect
    do @_updateDigits

  # Gets the current enabled flag.
  # @return [Boolean] The current enabled flag.
  isEnabled: ->
    return !@_input().disabled

  # Gets the current readonly flag.
  # @return [Boolean] The current readonly flag.
  isReadonly: ->
    return @_input().readOnly

  # Gets the current protected flag.
  # @return [Boolean] The current protected flag.
  isProtected: ->
    return @_isProtected

  # Gets the current complete flag (all 4 digits have been entered).
  # @return [Boolean] The current complete flag.
  isComplete: ->
    return @_input().value.length == @_digits().length

  # @private
  _input: ->
    return undefined unless @_el?
    $(@_el).find('input')[0]

  # @private
  _digits: ->
    return undefined unless @_el?
    $(@_el).find('div')

  # @private
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

  # @private
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

      if e.type == 'keyup'
        self.emit 'change' if (@value.length >= 0 && @value.length <= 4 and /[0-9]/g.test @value) or (@value == '')

      if e.type == 'keyup' and self.isComplete()
        self.emit 'complete' if /[0-9]/g.test @value

  # @private
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

  # @private
  _setDigitFocused: (digit, focused) ->
    @_setDigitClassEnabled digit, 'focused', focused

  # @private
  _setDigitSelected: (digit, selected) ->
    @_setDigitClassEnabled digit, 'selected', selected

  # @private
  _setDigitFilled: (digit, filled) ->
    @_setDigitClassEnabled digit, 'filled', filled

  # @private
  _setDigitDisabled: (digit, disabled) ->
    @_setDigitClassEnabled digit, 'disabled', disabled

  # @private
  _setDigitClassEnabled: (digit, className, enabled) ->
    if enabled == on
      $(digit).addClass(className)
    else
      $(digit).removeClass(className)