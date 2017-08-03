class @OnboardingDeviceChainsRecoverDialogViewController extends ledger.common.DialogViewController

  view:
    recover: ".recover"

  show: ->
    super

  onAfterRender: ->
    super
    @view.recover.on "click", @recover

  onDismiss:  ->
    super

  recover: (e) ->
    @emit 'click:recover'
    @dismiss()