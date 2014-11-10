class @OnboardingManagementPinViewController extends @OnboardingViewController

  defaultParams: {pin_kind: 'auto'}
  view:
    autoRadio: '#auto_radio'
    manualRadio: '#manual_radio'
    weakPinsLabel: '#weak_pins'
    generateLinkButton: '#generate_link'
    continueButton: '#continue_button'
    backButton: '#back_button'
  navigation:
    continueUrl: '/onboarding/management/pinconfirmation'

  initialize: ->
    if @_isPinKindAuto() and not @params.pin?
      @params.pin = @_randomPinCode()

  onAfterRender: ->
    super
    do @_insertPinCodes
    do @_listenEvents
    @_updateUI no

  randomizePinCode: ->
    @params.pin = @_randomPinCode()
    do @_updateUI

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    pin: @params.pin
    back: @representativeUrl()

  _insertPinCodes: ->
    @view.autoPinCode = new ledger.pin_codes.PinCode()
    @view.autoPinCode.insertAfter(@select('#choice-auto > label')[0])
    @view.autoPinCode.setProtected no
    @view.autoPinCode.setReadonly yes
    @view.manualPinCode = new ledger.pin_codes.PinCode()
    @view.manualPinCode.insertAfter(@select('#choice-manual > label')[0])

  _listenEvents: ->
    @view.autoRadio.on 'change', =>
      @params.pin_kind = 'auto'
      @params.pin = @_randomPinCode()
      do @_updateUI
    @view.manualRadio.on 'change', =>
      @params.pin_kind = 'manual'
      @params.pin = undefined
      do @_updateUI
    @view.manualPinCode.on 'change', =>
      @params.pin = @view.manualPinCode.value()
      do @_updateUI

  _updateUI: (animated = yes) ->
    # radio buttons
    @view.autoRadio.prop('checked', @_isPinKindAuto())
    @view.manualRadio.prop('checked', !@_isPinKindAuto())

    # pin codes
    @view.autoPinCode.setEnabled(@_isPinKindAuto())
    @view.manualPinCode.setEnabled(!@_isPinKindAuto())
    if !@_isPinKindAuto()
      @view.manualPinCode.focus()

    # helper links
    if @_isPinKindAuto()
      @view.weakPinsLabel.fadeOut(if animated then 250 else 0)
      @view.generateLinkButton.fadeIn(if animated then 250 else 0)
    else
      @view.weakPinsLabel.fadeIn(if animated then 250 else 0)
      @view.generateLinkButton.fadeOut(if animated then 250 else 0)

    # values
    @view.autoPinCode.clear()
    @view.manualPinCode.clear()
    if @params.pin?
      if @_isPinKindAuto()
        @view.autoPinCode.setValue(@params.pin)
      else
        @view.manualPinCode.setValue(@params.pin)

    # buttons
    if @_isPinValid()
      @view.continueButton.removeClass 'disabled'
    else
      @view.continueButton.addClass 'disabled'

  _isPinKindAuto: ->
    @params.pin_kind == 'auto'

  _isPinValid: ->
    @params.pin? and @params.pin.length == 4

  _randomPinCode: ->
    code = ''
    for i in [1..4]
      code += Math.floor(Math.random() * 10)
    code