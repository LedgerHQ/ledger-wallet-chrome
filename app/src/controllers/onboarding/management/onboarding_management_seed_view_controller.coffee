Bip39 = ledger.bitcoin.bip39

class @OnboardingManagementSeedViewController extends @OnboardingViewController

  view:
    seedContainer: '#seed_container'
    invalidLabel: '#invalid_label'
    indicationLabel: '#indication_label'
    continueButton: '#continue_button'
    actionsContainer: "#actions_container"
  navigation:
    continueUrl: null

  initialize: ->
    super
    if @params.wallet_mode == 'create'
      @params.mnemonicPhrase = Bip39.generateMnemonicPhrase(Bip39.DEFAULT_PHRASE_LENGTH)

  navigationContinueParams: ->
    hash =
      pin: @params.pin
    if @params.wallet_mode == 'create'
      hash.mnemonicPhrase = @params.mnemonicPhrase
    else
      hash.seed = Bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
    hash

  navigateContinue: ->
    if @params.wallet_mode == 'create'
      @navigation.continueUrl = '/onboarding/management/seedconfirmation'
    else
      @navigation.continueUrl = '/onboarding/management/summary'
    super

  onAfterRender: ->
    super
    @view.indicationLabel.fadeOut(0)
    @view.seedContainer.fadeOut(0)
    initializeUi = (animate = no) =>
      do @_generateInputs
      do @_listenEvents
      @_updateUI no
      @view.seedContainer.fadeIn(if animate then 250 else 0)
      @view.indicationLabel.fadeIn(if animate then 250 else 0)

    if @params.swapped_bip39 and @params.wallet_mode == 'create'
      @view.invalidLabel.fadeOut(0)
      ledger.app.dongle.setupSwappedBip39(@params.pin).then (result) =>
        @params.mnemonicPhrase = result.mnemonic.join(' ')
        initializeUi(yes)
      .fail (error) =>
        ledger.app.router.go '/onboarding/management/switch_firmware', _.extend(_.clone(@params), mode: 'setup', on_done: '/onboarding/management/seed')
    else if @params.swapped_bip39
      # Handle restore swapped bip39
    else
      initializeUi()

  copy: ->
    text = @params.mnemonicPhrase
    input = document.createElement("textarea");
    input.id = "toClipboard"
    input.value = text
    document.body.appendChild(input)
    input.focus()
    input.select()
    document.execCommand('copy')
    input.remove()

  print: ->
    ledger.print.Piper.instance.canUsePiper (isPiper) =>
      if isPiper
        ledger.print.Piper.instance.printMnemonic @params.mnemonic
      else
        window.print()

  _generateInputs: ->
    @view.inputs = []
    for i in [0...Bip39.DEFAULT_PHRASE_LENGTH]
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
      $(input).suggest(Bip39.wordlist);
      if i == 0
        input.focus()

  _listenEvents: ->
    self = @
    for input in @view.inputs
      input.on 'keydown', ->
        return if self.params.wallet_mode == 'create'
        $(this).removeClass 'seed-invalid'
        setTimeout ->
          self.params.mnemonicPhrase = self._writtenMnemonic()
          do self._updateUI
        , 0
      input.on 'blur', ->
        return if self.params.wallet_mode == 'create'
        self._inputIsValid $(this)
      input.on 'paste', ->
        setTimeout =>
          words = $(this).val().split(/[^A-Za-z]/)
          words = words.filter(Boolean)
          beginInput = 0
          for tmp in self.view.inputs
            if tmp[0] is $(this)[0]
              beginInput = self.view.inputs.indexOf(tmp)
          for i in [0..words.length - 1]
            if self.view.inputs[i + beginInput]
              self.view.inputs[i + beginInput].val(words[i])
              self._inputIsValid self.view.inputs[i + beginInput]
          self.params.mnemonicPhrase = self._writtenMnemonic()
          do self._updateUI
        , 0

  _updateUI: (animated = yes) ->
    if animated == no
      # hide indication label
      if @params.wallet_mode == 'create'
        @view.indicationLabel.show()
      else
        @view.indicationLabel.hide()

      # switch of readonly
      for input in @view.inputs
        if @params.wallet_mode == 'create'
          input.prop 'readonly', yes
          input.prop 'disabled', yes
        else
          input.prop 'readonly', no
          input.prop 'disabled', no

      # write words
      if @params.mnemonicPhrase?
        words = @params.mnemonicPhrase.split(' ')
        for i in [0 .. words.length - 1]
          @view.inputs[i].val(words[i])

      # hide copy button
      if @params.wallet_mode == 'create'
        @view.actionsContainer.show()
      else
        @view.actionsContainer.hide()

      # validate words
      for input in @view.inputs
        @_inputIsValid($(input))

    # validate mnemonic
    unless @params.swapped_bip39
      if Bip39.isMnemonicPhraseValid(@params.mnemonicPhrase)
        @view.invalidLabel.fadeOut(if animated then 250 else 0)
        @view.continueButton.removeClass 'disabled'
      else
        if Bip39.utils.mnemonicPhraseWordsLength(@params.mnemonicPhrase) == Bip39.DEFAULT_PHRASE_LENGTH
          @view.invalidLabel.fadeIn(if animated then 250 else 0)
        else
          @view.invalidLabel.fadeOut(if animated then 250 else 0)
        @view.continueButton.addClass 'disabled'

  _writtenMnemonic: ->
    (_.string.trim(input.val()).toLowerCase() for input in @view.inputs).join(' ')

  _inputIsValid: (input) ->
    text = _.str.trim(input.val()).toLowerCase()
    if @params.wallet_mode is 'create' or Bip39.utils.isMnemonicWordValid(text)
      input.removeClass 'seed-invalid'
    else
      input.addClass 'seed-invalid'
