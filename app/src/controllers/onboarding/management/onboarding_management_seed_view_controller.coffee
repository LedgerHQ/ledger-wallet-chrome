class @OnboardingManagementSeedViewController extends @OnboardingViewController

  view:
    seedContainer: '#seed_container'
    invalidLabel: '#invalid_label'
    indicationLabel: '#indication_label'
    continueButton: '#continue_button'
    copyButton: '#copy_button'
    printButton: '#print_button'
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
    for input in @view.inputs
      input.on 'keydown', (e) =>
        return if @params.wallet_mode == 'create'
        element = e.target
        $(element).removeClass 'seed-invalid'
        setTimeout =>
          @params.mnemonic = @_writtenMnemonic()
          do @_updateUI
        , 0
      input.on 'blur', (e) =>
        return if @params.wallet_mode == 'create'
        element = e.target
        @_inputIsValid $(element)
          
      input.on 'paste', (e) =>
        element = e.target
        setTimeout =>
          words = $(element).val().split(/[^A-Za-z]/)
          words = words.filter(Boolean)
          beginInput = 0
          for input2 in @view.inputs
            if input2[0] is $(element)[0]
              beginInput = @view.inputs.indexOf(input2)
          for i in [0..words.length - 1]
            if @view.inputs[i + beginInput]
              @view.inputs[i + beginInput].val(words[i])
              @_inputIsValid @view.inputs[i + beginInput]
          @params.mnemonic = @_writtenMnemonic()
          do @_updateUI
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

    # hide copy button
    if @params.wallet_mode == 'create'
      @view.copyButton.show()
      @view.printButton.show()
    else
      @view.copyButton.hide()
      @view.printButton.hide()

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
    if input.val() != "" and input.val() not in ledger.bitcoin.bip39.wordlist
      input.addClass 'seed-invalid'
    else
      input.removeClass 'seed-invalid'