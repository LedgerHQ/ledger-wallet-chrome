@ledger.spinners ?= {}
@ledger.spinners.createLargeSpinner = (target) ->
  opts =
    lines: 9
    length: 0
    width: 3
    radius: 16
    corners: 0
    rotate: 0
    direction: 1
    color: '#000'
    speed: 0.6
    trail: 20
    shadow: false
    hwaccel: false
    className: 'spinner'
    zIndex: 0
    position: 'relative'
  return new Spinner(opts).spin(target)