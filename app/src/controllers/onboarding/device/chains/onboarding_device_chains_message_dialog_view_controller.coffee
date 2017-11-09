class @OnboardingDeviceChainsMessageDialogViewController extends ledger.common.DialogViewController

  view:
    split: ".split"
    un_split: ".un_split"

  show: ->
    super

  onAfterRender: ->
    super
    @view.split.on "click", @split
    @view.un_split.on "click", @un_split

  onDismiss:  ->
    super
    l "On dismiss"

  split: (e) ->
    @emit 'click:split'
    @dismiss()

  un_split: (e) ->
    @emit 'click:un_split'
    @dismiss()

  recoverTool: (e) ->
    dialog = new OnboardingDeviceChainsRecoverDialogViewController()
    dialog.once 'click:recover', =>
      @chainChoosen(ledger.bitcoin.Networks.bitcoin_recover)
    dialog.show()
