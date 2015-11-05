States = ledger.fup.FirmwareUpdateRequest.States

class @OnboardingDeviceSwitchfirmwareViewController extends @OnboardingViewController

#  view:
#    progressLabel: "#progress"
#    progressBarContainer: "#bar_container"
#
#  constructor: ->
#    super
#    if @params.mode is 'setup'
#      @_request = ledger.app.dongle.getFirmwareUpdater().requestSetupFirmwareUpdate()
#    else
#      @_request = ledger.app.dongle.getFirmwareUpdater().requestOperationFirmwareUpdate()
#    @_request.onProgress @_onProgress.bind(@)
#    @_request.on 'needsUserApproval', @_onUpdateNeedsUserApproval.bind(@)
#    @_request.on 'stateChanged', (ev, data) => @_onStateChanged(data.newState, data.oldState)
#    #@_request.setKeyCardSeed('02294b743102b45323f5588cf8d02703150009100407010c160506141711130a020e0b0312080d0f') if @params.mode is 'setup' # Todo: This is only for debug purpose due to a bug in setup firmware flash
#    @_request.setKeyCardSeed('02294b743102b45323f5588cf8d02703') if @params.mode is 'setup' # Todo: This is only for debug purpose due to a bug in setup firmware flash
#    @_request.unlockWithPinCode(@params.pin) if @params.pin?
#    @_fup = ledger.app.dongle.getFirmwareUpdater()
#
#  onAfterRender: ->
#    super
#    @view.progressBar = new ledger.progressbars.ProgressBar(@view.progressBarContainer)
#    @view.progressBar.setAnimated(false)
#
#    start = =>
#      ledger.app.setExecutionMode(ledger.app.Modes.FirmwareUpdate)
#      @_fup.load =>
#        @_request.startUpdate()
#    if @params.mode is 'operation'
#      seed = ledger.bitcoin.bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
#      ledger.app.dongle.setup @params.pin, seed
#      .then => start()
#      .fail =>
#        ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}
#    else
#      start()
#
#  onDetach: ->
#    super
#    @_request.cancel()
#    @_fup.unload()
#    ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
#
#  _onFirmwareSwitchDone: ->
#    @_request.cancel()
#    ledger.app.reconnectDongleAndEnterWalletMode().then =>
#        if @params.mode is 'setup'
#          @_navigateNextSetup()
#        else
#          @_navigateNextOperation()
#
#  _onRequireUserPin: ->
#
#  _onError: ->
#
#  _onProgress: (state, current, total) ->
#    loadingBlProgress = if state is States.ReloadingBootloaderFromOs then current / total else 1
#    loadingOsProgress = if state is States.LoadingOs then  current / total else (if state is States.InitializingOs then 1 else 0)
#    progress = (loadingBlProgress + loadingOsProgress) / 2
#    @view.progressLabel.text("#{Math.ceil(progress * 100)}%")
#    @view.progressBar.setProgress progress
#
#  _onUpdateNeedsUserApproval: -> @_request.approveCurrentState()
#
#  _onStateChanged: (newState, oldState) ->
#    switch newState
#      when States.Done then @_onFirmwareSwitchDone()
#
#  _navigateNextSetup: ->
#    ledger.app.dongle.isSwappedBip39FeatureEnabled().then (enabled) =>
#      url = if enabled then '/onboarding/management/pin' else '/onboarding/management/security'
#      params = _.clone(@params)
#      ledger.app.router.go url, _.extend(params, swapped_bip39: enabled)
#    .done()
#
#  _navigateNextOperation: ->
#    seed = ledger.bitcoin.bip39.mnemonicPhraseToSeed(@params.mnemonicPhrase)
#    ledger.wallet.checkSetup ledger.app.dongle, seed, @params.pin
#    .then =>
#      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode}
#    .fail =>
#      ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}
