class @OnboardingManagementSeedViewController extends @OnboardingViewController

  view:
    seedContainer: '#seed_container'
    invalidLabel: '#invalid_label'
    indicationLabel: '#indication_label'
    continueButton: '#continue_button'
  navigation:
    continueUrl: '/onboarding/management/summary'

  initialize: ->
    super
    if @params.dongle_mode == 'create'
      @params.mnemonic = ledger.bitcoin.bip39.generateMnemonic()

  navigationContinueParams: ->
    dongle_mode: @params.dongle_mode
    back: @representativeUrl()
    pin: @params.pin
    rootUrl: @params.rootUrl
    seed: ledger.bitcoin.bip39.generateSeed @params.mnemonic

  onAfterRender: ->
    super
    do @_generateInputs
    do @_listenEvents
    @_updateUI no

  _generateInputs: ->
    @view.inputs = []
    for i in [0..ledger.bitcoin.bip39.mnemonicWordsNumber() - 1]
      div = document.createElement("div")
      div.className = 'seed-word'
      span = document.createElement("span")
      span.innerHTML = (i + 1) + '.'
      div.appendChild(span)
      input = document.createElement("input")
      input.type = 'text'
      div.appendChild(input)
      @view.inputs.push $(input)
      @view.seedContainer.append div
      if i == 0
        input.focus()

  _listenEvents: ->
    for input in @view.inputs
      input.on 'keydown', =>
        return if @params.dongle_mode == 'create'
        setTimeout =>
          @params.mnemonic = @_writtenMnemonic()
          do @_updateUI
        , 0

  _updateUI: (animated = yes) ->
    if animated == no
      # hide indication label
      if @params.dongle_mode == 'create'
        @view.indicationLabel.show()
      else
        @view.indicationLabel.hide()

      # switch of readonly
      for input in @view.inputs
        if @params.dongle_mode == 'create'
          input.prop 'readonly', yes
          input.prop 'disabled', yes
        else
          input.prop 'readonly', no
          input.prop 'disabled', no

      # write words
      if @params.mnemonic?
        words = @params.mnemonic.split(' ')
        for i in [0 .. words.length - 1]
          @view.inputs[i].val(words[i])

    # validate mnemonic
    if @_mnemonicIsValid()
      @view.invalidLabel.fadeOut(if animated then 250 else 0)
      @view.continueButton.removeClass 'disabled'
    else
      if ledger.bitcoin.bip39.numberOfWordsInMnemonic(@params.mnemonic) == ledger.bitcoin.bip39.mnemonicWordsNumber()
        @view.invalidLabel.fadeIn(if animated then 250 else 0)
      else
        @view.invalidLabel.fadeOut(if animated then 250 else 0)
      @view.continueButton.addClass 'disabled'

  _writtenMnemonic: ->
    mnemonic = ''
    first = yes
    for input in @view.inputs
      mnemonic += ' ' if not first
      mnemonic += _.string.trim(input.val()).toLowerCase()
      first = no
    mnemonic

  _mnemonicIsValid: ->
    ledger.bitcoin.bip39.mnemonicIsValid(@params.mnemonic)