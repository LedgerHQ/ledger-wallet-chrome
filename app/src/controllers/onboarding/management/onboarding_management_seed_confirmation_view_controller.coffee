Bip39 = ledger.bitcoin.bip39

class @OnboardingManagementSeedconfirmationViewController extends @OnboardingViewController

  view:
    seedContainer: '#seed_container'
    invalidLabel: '#invalid_label'
    continueButton: '#continue_button'
  navigation:
    continueUrl: '/onboarding/management/summary'

  initialize: ->
    super

    # generate random indexes
    numbersToGenerate = 2
    randomIndexes = []
    generator = -> Math.floor(Math.random() * Bip39.DEFAULT_PHRASE_LENGTH)
    while (yes)
      if randomIndexes.length == numbersToGenerate
        break
      if randomIndexes.length == 0
        randomIndexes.push generator()
      else
        num = generator()
        randomIndexes.push num if not _.contains(randomIndexes, num)
    @params.randomIndexes = _.sortBy(randomIndexes, (num) -> num)

  onAfterRender: ->
    super
    @_generateInputs()
    @_listenEvents()
    @_updateUI no

  navigateContinue: ->
    if @_areWordsValid()
      @view.invalidLabel.fadeOut(0)
      super
    else
      @view.invalidLabel.fadeIn(250)

  navigationContinueParams: ->
    pin: @params.pin
    mnemonicPhrase: @params.mnemonicPhrase

  _generateInputs: ->
    # generate inputs
    @view.inputs = []
    for i in [0...Bip39.DEFAULT_PHRASE_LENGTH]
      word = document.createElement("div")
      word.className = 'seed-word'
      span = document.createElement("span")
      span.innerHTML = (i + 1) + '.'
      word.appendChild(span)
      div = document.createElement("div")
      word.appendChild(div)
      if _.contains(@params.randomIndexes, i)
        input = document.createElement("input")
        input.type = 'text'
        div.appendChild(input)
        @view.inputs.push $(input)
      else
        $(word).addClass('disabled')
      @view.seedContainer.append word

      # focus first input
      @view.inputs[0]?.focus()

  _listenEvents: ->
    for input in @view.inputs
      input.on 'keydown paste', =>
        _.defer => @_updateUI()

  _updateUI: (animated = yes) ->
    if !animated
      @view.invalidLabel.hide()

    if @_areWordsWritten()
      @view.continueButton.removeClass 'disabled'
    else
      @view.continueButton.addClass 'disabled'

  _writtenWord: (input) ->
    return _.str.trim(input.val()).toLowerCase()

  _areWordsWritten: ->
    _.reduce(@view.inputs, ((bool, input) => bool && @_writtenWord(input).length > 0), yes)

  _areWordsValid: ->
    mnemonic = @params.mnemonicPhrase.split(' ')
    for i in [0...@params.randomIndexes.length]
      num = @params.randomIndexes[i]
      input = @view.inputs[i]
      word = mnemonic[num]
      if word != @_writtenWord(input)
        return false
    return true