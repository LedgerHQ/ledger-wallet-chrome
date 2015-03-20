
###
  Base view controller for all update view controllers. This class holds methods which are common to all update view controllers.
###
class @UpdateViewController extends @ViewController

  getRequest: -> @parentViewController._request

  ###
    Called once the controller is displayed and the Firmware update request needs a user approval
  ###
  onNeedsUserApproval: ->

  ###
    Called once the controller is displayed and the Firmware update request is notifying a progress
  ###
  onProgress: (state, current, total) ->