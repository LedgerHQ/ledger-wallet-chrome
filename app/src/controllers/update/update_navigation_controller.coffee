class @UpdateNavigationController extends @NavigationController

  view:
    pageSubtitle: "#page_subtitle"
    previousButton: "#previous_button"
    nextButton: "#next_button"

  onAttach: ->
    @_request = ledger.fup.FirmwareUpdater.instance.requestFirmwareUpdate()
    @_request.on 'plug', => @_onPlugDongle()
    @_request.on 'unplug', =>  @_onDongleNeedPowerCycle()
    @_request.on 'stateChanged', (ev, data) => @_onStateChanged(data.newState, data.oldState)
    @_request.on 'needsUserApproval', @_onNeedsUserApproval
    ledger.app.on 'dongle:disconnected', =>
      if _(@topViewController()).isKindOf(UpdateIndexViewController) or _(@topViewController()).isKindOf(UpdateSeedViewController) or _(@topViewController()).isKindOf(UpdateDoneViewController) or _(@topViewController()).isKindOf(UpdateErrorViewController)
        ledger.app.setExecutionMode(ledger.app.Modes.Wallet)
        ledger.app.router.go '/onboarding/device/plug', animateIntro: no
    @_request.on 'error', (event, error) => @_onError(error.cause)
    @_request.onProgress @_onProgress.bind(@)
    ledger.fup.FirmwareUpdater.instance.load =>

  renderChild: ->
    super
    @topViewController().once 'afterRender', =>
      # update page subtitle
      @view.pageSubtitle.text t @topViewController().localizablePageSubtitle
      # update navigation
      @updateNavigationItems()

  onDetach: ->
    @_request.cancel()

  updateNavigationItems: ->
    @view.previousButton.html '<i class="fa fa-angle-left"></i> ' + t(@topViewController().localizablePreviousButton)
    @view.nextButton.html t(@topViewController().localizableNextButton) + ' <i class="fa fa-angle-right"></i>'
    if @topViewController().shouldShowNextButton() then @view.nextButton.show() else @view.nextButton.hide()
    if @topViewController().shouldShowPreviousButton() then @view.previousButton.show() else @view.previousButton.hide()
    if @topViewController().shouldEnableNextButton() then @view.nextButton.removeClass 'disabled' else @view.nextButton.addClass 'disabled'
    if @topViewController().shouldEnablePreviousButton() then @view.previousButton.removeClass 'disabled' else @view.previousButton.addClass 'disabled'

  _onPlugDongle: ->
    @_currentError = null
    ledger.app.router.go '/update/plug'

  _onErasingDongle: ->
    ledger.app.router.go '/update/erasing'

  _onDongleNeedPowerCycle: ->
    unless @_currentError?
      ledger.app.router.go '/update/unplug'

  _onReloadingBootloaderFromOs: ->
    ledger.app.router.go '/update/updating'

  _onLoadingOs: ->
    ledger.app.router.go '/update/loading'

  _onDone: ->
    ledger.app.router.go '/update/done'

  _onError: (error) ->
    @_currentError = error
    ledger.app.router.go '/update/error', {errorCode: error.code}

  _onStateChanged: (newState, oldState) ->
    switch newState
      when ledger.fup.FirmwareUpdateRequest.States.Erasing
        unless @_request.hasGrantedErasurePermission()
          @_onErasingDongle()
      when ledger.fup.FirmwareUpdateRequest.States.ReloadingBootloaderFromOs then @_onReloadingBootloaderFromOs()
      when ledger.fup.FirmwareUpdateRequest.States.LoadingOs then @_onLoadingOs()
      when ledger.fup.FirmwareUpdateRequest.States.LoadingBootloaderReloader then @_onLoadingOs()
      when ledger.fup.FirmwareUpdateRequest.States.LoadingBootloader then @_onLoadingOs()
      when ledger.fup.FirmwareUpdateRequest.States.Done then @_onDone()

  _onNeedsUserApproval: ->
    if @topViewController()?.isRendered()
      @topViewController().onNeedsUserApproval()
    else
      @topViewController().once 'afterRender', => @topViewController().onNeedsUserApproval()

  _onProgress: (state, current, total) ->
    if @topViewController()?.isRendered()
      @topViewController().onProgress(state, current, total)
    else
      @topViewController().once 'afterRender', => @topViewController().onProgress(state, current, total)