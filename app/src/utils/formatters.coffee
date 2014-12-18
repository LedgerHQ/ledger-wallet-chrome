ledger.formatters ?= {}
ledger.formatters.bitcoin ?= {}

_.extend ledger.formatters.bitcoin,
  fromValue: (value, precision = -1) ->
    return if not value?
    # to string
    value = value.toString()
    # remove leading 0, add leading 0s until 9 digits
    value = _.str.ltrim value, '0'
    value = _.str.lpad(value, 9, '0')
    # add .
    dotIndex = value.length - 8
    value = _.str.insert value, value.length - 8, '.'
    if precision < 0
      # remove trailing 0s
      value = _.str.rtrim value, '0'
    else
      # truncate after .
      value = value.slice(0, dotIndex + 1 + precision)
    # remove . if necessary
    if _.str.endsWith value, '.'
      value = _.str.splice value, -1, 1
    return value