###
  Base view controller for all update view controllers. This class holds methods which are common to all update view controllers.
###
class @UpdateViewController extends @ViewController

  navigation:
    nextRoute: undefined
    previousRoute: undefined
    nextParams: undefined
    previousParams: undefined
  localizablePageSubtitle: undefined
  localizableNextButton: "common.continue"
  localizablePreviousButton: "common.cancel"

  navigateNext: ->
    if @navigation?.nextRoute?
      ledger.app.router.go @navigation.nextRoute, @navigation.nextParams

  navigatePrevious: ->
    if @navigation?.previousRoute?
      ledger.app.router.go @navigation.previousRoute, @navigation.previousParams

  shouldShowPreviousButton: ->
    return no if @params.hidePreviousButton is yes
    @navigation?.previousRoute?

  shouldShowNextButton: ->
    return no if @params.hideNextButton is yes
    @navigation?.nextRoute?

  shouldEnablePreviousButton: ->
    true

  shouldEnableNextButton: ->
    true

  getRequest: -> @parentViewController._request

  ###
    Called once the controller is displayed and the Firmware update request needs a user approval
  ###
  onNeedsUserApproval: ->

  ###
    Called once the controller is displayed and the Firmware update request is notifying a progress
  ###
  onProgress: (state, current, total) ->