@ledger.pin_codes ?= {}

class ledger.pin_codes.TinyPinCode

  _el: undefined
  inputsCount: 0
  valuesCount: 0

  insertIn: (parent) ->
    parent.appendChild @el()

  remove: ->
    $(@_el).remove()
    @_el = undefined

  el: ->
    @_buildEl() if not @_el?
    return @_el

  setInputsCount: (count) ->
    return if count == @inputsCount
    @inputsCount = count
    @_updateInputs()

  setValuesCount: (count) ->
    return if count == @valuesCount
    @valuesCount = count
    @_updateInputs()

  _buildEl: ->
    @_el = document.createElement('div')
    @_el.className = 'tiny-pincode'

  _updateInputs: ->
    $(@el()).empty()
    return if @inputsCount == 0
    for i in [0 .. @inputsCount - 1]
      input = document.createElement('div')
      input.className = if i == @valuesCount then 'input selected' else 'input'
      input.innerText = '•' if i < @valuesCount
      @el().appendChild input

class ledger.pin_codes.KeyCard extends EventEmitter

  _el: undefined
  _input: undefined
  _valuesNodes: undefined

  _validableValues: undefined
  _currentValidableValueNode: undefined

  @values = [
    'ABCDEFGHJKLMNPQRSTUVWXYZ',
    'abcdefghijkmnopqrstuvwxyz',
    '0123456789'
  ]

  insertIn: (parent) ->
    @_buildEl() if not @_el?
    parent.appendChild @_el

  remove: ->
    $(@_el).remove()
    @_el = undefined
    @_input = undefined
    @_valuesNodes = undefined
    @_validableValues = undefined
    @_currentValidableValueNode = undefined

  value: ->
    return undefined if not @_el?
    return @_input.value

  setValidableValues: (values) ->
    @_validableValues = if values? then values.slice() else []
    @_currentValidableValueNode = undefined
    @_updateCurrentValidableValue()

  focus: ->
    @_buildEl() if not @_el?
    @_input.focus()

  stealFocus: ->
    @_buildEl() if not @_el?
    @focus()
    $(@_input).on 'blur', =>
      @focus()

  _buildEl: ->
    @_el = document.createElement('div')
    @_el.className = 'keycard'
    @_valuesNodes = []
    for i in [0..2]
      section = document.createElement('div')
      section.className = 'section-title'
      section.innerText = @_sectionTitle i
      values = document.createElement('div')
      values.className = 'section-values'
      for j in [0..(@_sectionValue(i).length - 1)]
        value = document.createElement('div')
        value.className = 'value'
        value.innerText = ledger.pin_codes.KeyCard.values[i][j]
        values.appendChild value
      @_el.appendChild section
      @_el.appendChild values
      @_valuesNodes.push values
    @_input = document.createElement('input')
    @_input.type = 'password'
    @_el.appendChild @_input
    @_updateCurrentValidableValue()
    do @_listenEvents

  _listenEvents: (listen = yes) ->
    if listen
      $(@_input).on 'input', (e) =>
        reg = /^[0-9a-zA-Z]+$/
        if reg.test @_input.value
          @_processNextValidableValue()
        else
          @_input.value = @_input.value.replace(/[^0-9a-zA-Z]/g, '')
      $(@_input).on 'keydown', (e) =>
        if not ((e.which >= 48 and e.which <= 90) or (e.which >= 96 and e.which <= 105))
          e.preventDefault()
          return false
    else
      $(@_input).off 'input'
      $(@_input).off 'keydown'

  _updateCurrentValidableValue: ->
    if @_currentValidableValueNode?
      $(@_currentValidableValueNode).removeClass 'selected'
      @_currentValidableValueNode = undefined
    return if not @_el? or not @_validableValues? or @_validableValues.length == 0
    [index, offset] = @_indexesOfSectionValue @_validableValues[0]
    return if not index? or not offset?
    valueNode = @_sectionValueNodeAtIndexes index, offset
    return if not valueNode?
    @_currentValidableValueNode = valueNode
    $(valueNode).addClass 'selected'
    @emit 'character:waiting', @_validableValues[0]

  _processNextValidableValue: ->
    return if not @_validableValues? or @_validableValues.length == 0
    @_validableValues.splice 0, 1
    @emit 'character:input', @_input.value[@_input.value.length - 1]
    @_updateCurrentValidableValue()
    if @_validableValues.length == 0
      @emit 'completed', @_input.value
      @_listenEvents no

  _sectionTitle: (index) ->
    t (['common.keycard.uppercase_letters', 'common.keycard.lowercase_letters', 'common.keycard.digits'][index])

  _sectionValue: (index, offset) ->
    return ledger.pin_codes.KeyCard.values[index] if not offset?
    ledger.pin_codes.KeyCard.values[index][offset]

  _sectionValueNodeAtIndexes: (index, offset) ->
    return $(@_valuesNodes[index]).children()[offset]

  _indexesOfSectionValue: (char) ->
    for i in [0..ledger.pin_codes.KeyCard.values.length - 1]
      str = ledger.pin_codes.KeyCard.values[i]
      for j in [0..str.length - 1]
        if @_sectionValue(i, j) == char
          return [i, j]
    return [undefined , undefined]

# This class represents a visual pin code input composed of 4 digits.
class ledger.pin_codes.PinCode extends EventEmitter

  _el: null
  _isProtected: yes
  _stealsFocus: no

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
    return if !@isEnabled()
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

  setStealsFocus: (steals) ->
    @_stealsFocus = steals
    if steals
      @focus()

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

  stealsFocus: ->
    return @_stealsFocus

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

    # listen click on element
    $(@_el).on 'click', ->
      if !self.isEnabled()
        self.emit 'click'

    # listen changes in input
    $(@_input()).on 'change keyup keydown focus blur', (e) ->
      return if !self.isEnabled() or self.isReadonly()
      @value = @value.replace(/[^0-9]/g, '')
      do self._updateDigits

      if e.type == 'keyup'
        self.emit 'change', @value if (@value.length >= 0 && @value.length <= 4 and /[0-9]/g.test @value) or (@value == '')

      if e.type == 'keyup' and self.isComplete()
        self.emit 'complete', @value if /[0-9]/g.test @value

      if e.type == 'blur'
        if self.stealsFocus()
          self.focus()

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