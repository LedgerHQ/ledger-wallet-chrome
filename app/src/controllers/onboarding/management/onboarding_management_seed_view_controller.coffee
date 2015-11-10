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

  navigationContinueParams: ->
    pin: @params.pin
    mnemonicPhrase: @params.mnemonicPhrase

  navigateContinue: ->
    if @params.wallet_mode == 'create'
      @navigation.continueUrl = '/onboarding/management/seedconfirmation'
    else
      @navigation.continueUrl = '/onboarding/management/summary'
    super

  onAfterRender: ->
    super
    # setup ui
    @_generateInputs()
    @_listenEvents()
    @_updateUI(no)

    # generate seed
    if @params.wallet_mode == 'create' and not @params.mnemonicPhrase?
      if @params.swapped_bip39
        ledger.app.dongle.setupSwappedBip39(@params.pin).then (result) =>
          @params.mnemonicPhrase = result.mnemonic.join(' ')
          @_updateUI(no)
        .fail (error) =>
          @navigateContinue '/onboarding/device/switch_firmware', _.extend(_.clone(@params), mode: 'setup')
      else
        @params.mnemonicPhrase = Bip39.generateMnemonicPhrase(Bip39.DEFAULT_PHRASE_LENGTH)
        @_updateUI(no)

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
      span.innerHTML = if @params.swapped_bip39 then String.fromCharCode(0x41 + i) + '.' else (i + 1) + '.'
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
    return if @params.wallet_mode == 'create'
    self = @
    for input in @view.inputs
      input.on 'keydown', ->
        $(this).removeClass 'seed-invalid'
        setTimeout ->
          self.params.mnemonicPhrase = self._writtenMnemonic()
          do self._updateUI
        , 0
      input.on 'blur', ->
        return if self.params.wallet_mode == 'create'
        self._validateInput $(this)
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
              self._validateInput self.view.inputs[i + beginInput]
          self.params.mnemonicPhrase = self._writtenMnemonic()
          do self._updateUI
        , 0

  _updateUI: (limited = yes) ->
    if limited == no
      # hide indication label
      if @params.wallet_mode == 'create'
        @view.invalidLabel.hide()
        @view.indicationLabel.show()
      else
        @view.invalidLabel.fadeOut(0)
        @view.indicationLabel.hide()

      # switch of readonly
      for input in @view.inputs
        if @params.wallet_mode == 'create'
          input.prop 'readonly', yes
          input.prop 'disabled', yes
        else
          input.prop 'readonly', no
          input.prop 'disabled', no

      # hide copy button
      if @params.wallet_mode == 'create'
        @view.actionsContainer.show()
      else
        @view.actionsContainer.hide()

      # write words
      if @params.mnemonicPhrase?
        words = @params.mnemonicPhrase.split(' ')
        for i in [0 .. words.length - 1]
          @view.inputs[i].val(words[i])

      # validate words
      for input in @view.inputs
        @_validateInput(input)

    # validate mnemonic
    if @params.wallet_mode == 'create'
      if not @params.mnemonicPhrase?
          @view.continueButton.addClass 'disabled'
      else
          @view.continueButton.removeClass 'disabled'
    else
      if Bip39.utils.mnemonicPhraseWordsLength(@params.mnemonicPhrase) == Bip39.DEFAULT_PHRASE_LENGTH
        if @params.swapped_bip39
          valid = Bip39.utils.isMnemonicWordsValid(Bip39.utils.mnemonicWordsFromPhrase(@params.mnemonicPhrase))
        else
          valid = Bip39.isMnemonicPhraseValid(@params.mnemonicPhrase)
        if valid
          @view.continueButton.removeClass 'disabled'
          @view.invalidLabel.fadeOut(250)
        else
          @view.continueButton.addClass 'disabled'
          @view.invalidLabel.fadeIn(250)
      else
        @view.invalidLabel.fadeOut(250)
        @view.continueButton.addClass 'disabled'

  _writtenMnemonic: ->
    (_.string.trim(input.val()).toLowerCase() for input in @view.inputs).join(' ')

  _writtenWord: (input) ->
    return _.str.trim(input.val()).toLowerCase()

  _validateInput: (input) ->
    return if @params.wallet_mode is 'create'
    text = @_writtenWord(input)
    if Bip39.utils.isMnemonicWordValid(text)
      input.removeClass 'seed-invalid'
    else
      input.addClass 'seed-invalid'
