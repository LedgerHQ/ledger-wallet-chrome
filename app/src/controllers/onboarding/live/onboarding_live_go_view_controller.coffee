
isHW1 = -> !ledger.app.dongle.getFirmwareInformation().hasSecureScreenAndButton()
isNanoS = -> ledger.app.dongle.getFirmwareInformation().hasSecureScreenAndButton()
class @OnboardingLiveGoViewController extends ledger.common.ViewController

  constructor: (params) ->
    super
    console.log(params)
    @_next = @constructor._next
    @constructor._next = null
    @_viewPath = if isNanoS() then "/onboarding/live/go" else "/onboarding/live/go_hw1"

  goNext: () -> @_next()

  go: ->
    if isNanoS()
      window.open("http://ledger.com/live")
    else
      window.open t 'application.support_url'

  skip: -> @goNext()

  support: ->
    if isNanoS()
      window.open t 'application.support_url'
    else
      @goNext()

  viewPath: -> @_viewPath

@OnboardingLiveGoViewController.go = (next) ->
  # Beware big ugly stuff
  ledger.storage.global.live.get("live_count", (result) ->
    count = result.live_count or 0
    if (count < 2)
      ledger.storage.global.live.set(live_count: count + 1)
      OnboardingLiveGoViewController._next = next
      ledger.app.router.go '/onboarding/live/go'
    else
      next()
  )
