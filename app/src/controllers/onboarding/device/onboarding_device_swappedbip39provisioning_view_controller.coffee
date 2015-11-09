
EstimatedTime = (4 * 60 + 30) * 1000

class @OnboardingDeviceSwappedbip39provisioningViewController extends @OnboardingViewController

  view:
    progressBar: '#circle_progress_bar'
    carousel: '.carousel'

  carouselTexts: [
    "Ledger Nano is a Bitcoin wallet on a smartcard device, small format and low weight.<br /> Comfortable and simple to use, you connect it directly to a USB port to manage your account.",
    "Extensible Duo from de Super market on a Random device, power format efficient low format.<br /> Comfortable to applaude to car, you unchained it card to a money transport strong management.",
    "Ledger Nano is a Bitcoin wallet on a smartcard device, small format and low weight.<br /> Comfortable and simple to use, you connect it directly to a USB port to manage your account.",
    "Ledger Nano is a Bitcoin wallet on a smartcard device, small format and low weight.<br /> Comfortable and simple to use, you connect it directly to a USB port to manage your account."
  ]

  onAfterRender: ->
    super
    @_progressBar = new ledger.widgets.CircleProgressBar(@view.progressBar, width: 70, height: 70)
    window.pr = @_progressBar

    @_startTime = new Date().getTime()
    @_interval = setInterval(@_refreshProgression.bind(this), 1000)

    @_initializeCarousel()

    # Important part
    if @params.wallet_mode is 'create'
      @_finalizeSetup()
    else
      @_performSetup()
    # !Important part

  onDetach: ->
    super
    clearInterval(@_interval)

  _initializeCarousel: ->
    @view.carousel.empty()

    for text in @carouselTexts
      child =
        $("<div class=\"carousel-item \">#{t(text)}</div>")
      @view.carousel.append(child)

    @view.carousel.slick
      dots: on
      infinite: on
      autoplay: on
      arrows: off
      accessibility: off
      draggable: off
      fade: on
      speed: 500

  _refreshProgression: ->
    diff = new Date().getTime() - @_startTime
    @_progressBar.setProgress(Math.min(diff / EstimatedTime, 1))

  _finalizeSetup: ->
    ledger.app.dongle.setupFinalizeBip39().then =>
      # Next step flash the dongle in operation firmware
      @navigateContinue '/onboarding/device/switch_firmware', _.extend(_.clone(@params), mode: 'operation')
    .fail =>
      @navigateContinue '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}

  _performSetup: ->
    ledger.app.dongle.restoreSwappedBip39 @params.pin, @params.mnemonicPhrase
    .then => ledger.app.dongle.restoreFinalizeBip29()
    .then =>
      @navigateContinue '/onboarding/device/switch_firmware', _.extend(_.clone(@params), mode: 'operation')
      return
    .fail (err) =>
      debugger
      if @params.retrying? is false and off
        params = _.clone @params
        _.extend params, retrying: yes
        @navigateContinue '/onboarding/device/switch_firmware', _.extend(_.clone(@params), mode: 'setup')
      else
        ledger.app.router.go '/onboarding/management/done', {wallet_mode: @params.wallet_mode, error: 1}