
###
  Base view controller for all update view controllers. This class holds methods which are common to all update view controllers.
###
class @UpdateViewController extends @ViewController

  getRequest: -> @parentViewController._request
