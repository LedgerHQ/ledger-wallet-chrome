class @WalletSendProcessingDialogViewController extends @DialogViewController

  view:
    title: '#title'
    spinnerContainer: '#spinner_container'

  onAfterRender: ->
    super
    @view.spinner = ledger.spinners.createLargeSpinner(@view.spinnerContainer[0])
    do @_startSignature

  _startSignature: ->
    @view.title.text t 'wallet.send.processing.validating'
    # sign transaction
    _.delay =>
      return if not @isShown()
      @_startSending()
    , 3000

  _startSending: ->
    @view.title.text t 'wallet.send.processing.sending'
    # push transaction
    _.delay =>
      return if not @isShown()
      @once 'dismiss', =>
        dialog = new WalletSendSuccessDialogViewController()
        dialog.show()
      @dismiss()
    , 3000