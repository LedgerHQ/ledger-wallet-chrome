class @OnboardingDeviceChainsChoiceDialogViewController extends ledger.common.DialogViewController

  view:
    first: ".first"
    second: ".second"
    link: '#link'
    cancel: ".cancel"
    option: ".option"

  constructor: ({@title, @text, @firstChoice, @secondChoice, @cancelChoice, @optionChoice}) ->
    super


  show: ->
    super

  onAfterRender: ->
    super
    @view.first.on "click", @first
    @view.second.on "click", @second
    @view.cancel.on "click", @cancel
    @view.option.on "click", @option

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

  option: (e) ->
    @emit 'click:option'
    @dismiss()

  cancel: (e) ->
    @emit 'click:cancel'
    @dismiss()
