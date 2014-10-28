
# t: current time, b: begInnIng value, c: change In value, d: duration


jQuery.easing['jswing'] = jQuery.easing['swing']

$.extend $.easing,

  default: 'smooth'

  swing: (t, b, c, d) -> $.easing[$.easing.default](t, b, c, d)

  accelerate_deccelerate: (t, b, c, d) -> (Math.cos((t + 1) * Math.PI) / 2.0) + 0.5

  smooth: (t, b, c, d) -> Math.pow(t - 1, 5) + 1


