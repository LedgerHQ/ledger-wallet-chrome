class @OnboardingDeviceChainsChoiceDialogViewController extends ledger.common.DialogViewController

  view:
    first: ".first"
    second: ".second"
    link: '#link'
    cancel: ".cancel"

  constructor: ({@title, @text, @firstChoice, @secondChoice, @cancel}) ->
    super


  show: ->
    super

  onAfterRender: ->
    super
    @view.first.on "click", @first
    @view.second.on "click", @second
    @view.cancel.on "click", @first

  onDismiss:  ->
    super

  openLink: ->
    open("https://bitcoincore.org/en/2016/01/26/segwit-benefits/")


  first: (e) ->
    @emit 'click:first'
    @dismiss()

  second: (e) ->
    @emit 'click:second'
    @dismiss()
