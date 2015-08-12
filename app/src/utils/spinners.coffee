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
    hwaccel: true
    className: 'spinner'
    zIndex: 0
    position: 'relative'
  return new Spinner(opts).spin(target)

@ledger.spinners.createTinySpinner = (target) ->
  opts =
    lines: 7
    length: 0
    width: 2
    radius: 5
    corners: 0
    rotate: 0
    direction: 1
    color: '#000'
    speed: 0.8
    trail: 50
    shadow: false
    hwaccel: true
    className: 'tinySpinner'
    position: 'relative'
  return new Spinner(opts).spin(target)