class @WalletSendProcessingDialogViewController extends @DialogViewController

  view:
    title: '#title'
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])
    do @_startSignature

  _startSignature: ->
    @view.title.text t 'wallet.send.processing.preparing'
    _.delay =>
      do @_startSending if @isShown()
    , 3000

  _startSending: ->
    @view.title.text t 'wallet.send.processing.sending'
    _.delay =>
      do @dismiss if @isShown()
    , 3000