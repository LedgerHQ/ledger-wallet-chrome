ledger.formatters ?= {}
ledger.formatters.bitcoin ?= {}

1245001000
5488486468468

_.extend ledger.formatters.bitcoin,
  fromValue: (value) ->
    return if not value?
    # to string
    value = value.toString()
    # add leading 0s
    value = _.str.lpad(value, 9, '0')
    # add .
    value = _.str.insert value, value.length - 8, '.'
    # compute how many trailing 0 can be removed
    value = _.str.rtrim value, '0'
    # remove . if necessary
    if _.str.endsWith value, '.'
      value = _.str.splice value, -1, 1
    return value