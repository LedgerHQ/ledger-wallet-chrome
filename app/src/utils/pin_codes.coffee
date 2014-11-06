@ledger.pin_codes ?= {}
class @ledger.pin_codes.PinCode extends EventEmitter

  _el: null

  insertIn: (parent) ->
    return if @_el?
    @_buildEl()
    parent.appendChild @_el

  remove: ->
    return unless @_el?
    @_el.parentNode().removeChild(@_el)
    @_el = null

  focus: ->
    return unless @_el?
    $(@_input()).focus()
    do @_updateDigits

  clear: ->
    return unless @_el?
    $(@_input()).val('')
    do @_updateDigits

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
    @_el.className = 'pin-code'

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
        do self.focus
      $(digit).on 'mousedown', (e) ->
        e.preventDefault()

    # listen changes in input
    $(@_input()).on 'change keyup keydown focus blur', (e) ->
      @value = @value.replace(/[^0-9]/g, '')
      do self._updateDigits

      if e.type == 'keyup' and self.isComplete()
        self.emit 'complete', @value if /[0-9]/g.test @value

  _updateDigits: ->
    for index in [0..@_digits().length - 1]
      digit = @_digits()[index]
      @_setDigitFilled(digit, index < @_input().value.length)
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

  _setDigitClassEnabled: (digit, className, enabled) ->
    if enabled == on
      $(digit).addClass(className)
    else
      $(digit).removeClass(className)