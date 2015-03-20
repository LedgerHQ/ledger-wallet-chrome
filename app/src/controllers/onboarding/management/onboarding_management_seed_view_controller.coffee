class @OnboardingManagementSeedViewController extends @OnboardingViewController

  view:
    seedContainer: '#seed_container'
    invalidLabel: '#invalid_label'
    indicationLabel: '#indication_label'
    continueButton: '#continue_button'
    actionsContainer: "#actions_container"
  navigation:
    continueUrl: '/onboarding/management/summary'

  initialize: ->
    super
    if @params.wallet_mode == 'create'
      @params.mnemonic = ledger.bitcoin.bip39.generateMnemonic()

  navigationContinueParams: ->
    wallet_mode: @params.wallet_mode
    back: @representativeUrl()
    pin: @params.pin
    rootUrl: @params.rootUrl
    seed: ledger.bitcoin.bip39.generateSeed @params.mnemonic

  onAfterRender: ->
    super
    do @_generateInputs
    do @_listenEvents
    @_updateUI no

  copy: ->
    text = @params.mnemonic
    input = document.createElement("textarea");
    input.id = "toClipboard"
    input.value = text
    document.body.appendChild(input)
    input.focus()
    input.select()
    document.execCommand('copy')
    input.remove()

  print: ->
    window.print()

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
      $(input).suggest(ledger.bitcoin.bip39.wordlist);
      if i == 0
        input.focus()

  _listenEvents: ->
    self = @
    for input in @view.inputs
      input.on 'keydown', ->
        return if self.params.wallet_mode == 'create'
        $(this).removeClass 'seed-invalid'
        setTimeout =>
          self.params.mnemonic = self._writtenMnemonic()
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
          self.params.mnemonic = self._writtenMnemonic()
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
      if @params.mnemonic?
        words = @params.mnemonic.split(' ')
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

  _inputIsValid: (input) ->
    text = _.str.trim(input.val()).toLowerCase()
    if text != "" and text not in ledger.bitcoin.bip39.wordlist
      input.addClass 'seed-invalid'
    else
      input.removeClass 'seed-invalid'