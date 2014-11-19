class @WalletSendIndexDialogViewController extends DialogViewController

  view:
    amountInput: '#amount_input'
    sendButton: '#send_button'
    totalInput: '#total_input'

  onAfterRender: () ->
    super
    @view.amountInput.amountInput()
    do @_updateTotalInput
    @_toggleSendButtonConfirmable no
    do @_listenEvents

  onShow: ->
    super
    @view.amountInput.focus()

  send: ->
    

  _listenEvents: ->
    @view.amountInput.on 'keydown', =>
      _.defer =>
        @_updateTotalInput yes

    @view.sendButton.on 'blur', =>
      _.defer =>
        @_toggleSendButtonConfirmable no

  _toggleSendButtonConfirmable: (confirmable) ->
    if confirmable
      @view.sendButton.addClass 'confirmable'
      @view.sendButton.text t 'wallet.send.index.confirm'
    else
      @view.sendButton.removeClass 'confirmable'
      @view.sendButton.text t 'wallet.send.index.send'

  _updateTotalInput: ->
    initalVal = if @view.amountInput.val()? then @view.amountInput.val() else 0
    val = parseInt(ledger.wallet.Value.from(initalVal).add(1000).toString()) * 10e-8 #0.00001 btc
    @view.totalInput.text val + ' BTC ' + t 'wallet.send.index.transaction_fees_text'