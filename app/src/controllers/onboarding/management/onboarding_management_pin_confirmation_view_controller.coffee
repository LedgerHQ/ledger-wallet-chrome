class @OnboardingManagementPinconfirmationViewController extends @OnboardingViewController

  navigation:
    continueUrl: '/onboarding/management/seed'
  view:
    continueButton: '#continue_button'
    invalidLabel: '#invalid_pins'

  onAfterRender: ->
    super
    do @_insertPinCode
    do @_listenEvents
    @_updateUI no

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    back: @representativeUrl()
    pin: @params.pin
    rootUrl: @params.rootUrl

  _listenEvents: ->
    @view.pinCode.on 'change', =>
      do @_updateUI

  _insertPinCode: ->
    @view.pinCode = new ledger.pin_codes.PinCode()
    @view.pinCode.insertAfter(@select('div.page-content-container > div'))
    @view.pinCode.setStealsFocus yes

  _updateUI: (animated = yes) ->
    if @_isPinValid()
      @view.invalidLabel.fadeOut(if animated then 250 else 0)
      @view.continueButton.removeClass 'disabled'
    else
      if animated == no
        @view.invalidLabel.fadeOut(0)
      else
        if @view.pinCode.isComplete()
          @view.invalidLabel.fadeIn(if animated then 250 else 0)
        else
          @view.invalidLabel.fadeOut(if animated then 250 else 0)
      @view.continueButton.addClass 'disabled'

  _isPinValid: ->
    @view.pinCode.value()? and @params.pin? and @view.pinCode.value() == @params.pin