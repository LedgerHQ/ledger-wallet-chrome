class @OnboardingManagementSeedViewController extends @OnboardingViewController

  view:
    seedContainer: '#seed_container'
    invalidLabel: '#invalid_indication'
    indicationLabel: '#indication_label'
    continueButton: "#continue_button"
  navigation:
    continueUrl: '/onboarding/management/provisioning'
  _numberOfWords: 24

  initialize: ->
    if @params.wallet_mode == 'create'
      @params.mnemonic = "nimble heady busy request pigs annoy bikes angle discover obeisant abrasive unbiased grotesque nut pies allow groan oranges spell mine measure offend turn direction"

  navigationContinueParams: ->
    back: @representativeUrl()
    pin: @params.pin

  onAfterRender: ->
    super
    do @_generateInputs
    do @_listenEvents
    @_updateUI no

  _generateInputs: ->
    @view.inputs = []
    for i in [0..@_numberOfWords - 1]
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

  _listenEvents: ->
    return if @params.wallet_mode == 'create'
    for input in @view.inputs
      input.on 'keydown', =>
        setTimeout =>
          @params.mnemonic = @_writtenMnemonic()
          do @_updateUI
        , 0

  _updateUI: (animated = yes) ->
    if animated == no
      # hide invalid label
      @view.invalidLabel.hide()

      # hide indication label
      if @params.wallet_mode == 'create'
        @view.indicationLabel.show()
      else
        @view.indicationLabel.hide()

      # switch to readonly
      if @params.wallet_mode == 'create'
        for input in @view.inputs
          input.prop 'readonly', yes

      # write words
      if @params.mnemonic?
        words = @params.mnemonic.split(' ')
        for i in [0 .. words.length - 1]
          @view.inputs[i].val(words[i])
    else
      # continue button
      if @params.wallet_mode != 'create'
        if @_mnemonicIsValid()
          @view.invalidLabel.fadeOut(250)
          @view.continueButton.removeClass 'disabled'
        else
          @view.invalidLabel.fadeIn(250)
          @view.continueButton.addClass 'disabled'

  _writtenMnemonic: ->
    mnemonic = ''
    first = yes
    for input in @view.inputs
      mnemonic += ' ' if not first
      mnemonic += input.val()
      first = no
    mnemonic

  _mnemonicIsValid: ->
    return @params.mnemonic[@params.mnemonic.length - 1] != ' '