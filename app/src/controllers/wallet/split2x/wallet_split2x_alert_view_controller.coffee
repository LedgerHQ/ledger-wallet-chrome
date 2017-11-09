class @WalletSplit2xAlertViewController extends ledger.common.DialogViewController

  cancellable: no

  view:
    ignore: ".ignore"
    split: ".split"

  constructor: ({@tx}) ->
    if @tx
      @message = t("split2x.alert.will_message")
    else
      @message = t("split2x.alert.might_message")
    super

  show: ->
    super

  onAfterRender: ->
    super
    @view.ignore.on "click", @ignore
    @view.split.on "click", @split

  onDismiss:  ->
    super

  wsid: ->
    open("https://bitcoincore.org/en/2016/01/26/segwit-benefits/")


  ignore: (e) ->
    @emit 'click:ignore'
    @dismiss()

  split: (e) ->
    @emit 'click:split'
    @dismiss()
