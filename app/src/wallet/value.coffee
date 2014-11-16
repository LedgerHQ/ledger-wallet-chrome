ledger.wallet ?= {}

class ledger.wallet.Value

  @from: (value) ->
    return value if _.isKindOf(value, ledger.wallet.Value)
    out = switch
      when _.isString value
        [integerPart, fractionalPart] = value.split('.')

        fractionalPart = _.str.rpad(fractionalPart, 8, '0')
        v = Bitcoin.BigInteger.valueOf(parseInt(integerPart))
        .multiply Bitcoin.BigInteger.valueOf(10e+7)
        .add(Bitcoin.BigInteger.valueOf(parseInt(fractionalPart)))
        new ledger.wallet.Value(v)
      when _.isNumber value then new Value(value)

  constructor: (value = Bitcoin.BigInteger.ZERO) ->
    if _(value).isKindOf(Bitcoin.BigInteger)
      @_number = value
      return this
    @_number = Bitcoin.BigInteger.valueOf value

  add: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.add(value._number))

  substract: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.substract(value._number))

  multiply: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.multiply(value._number))

  divide: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.divide(value._number))

  compare: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    @_number.compareTo(value._number)

  lt: (value) -> @compare(value) < 0
  lte: (value) -> @compare(value) <= 0
  gt: (value) -> @compare(value) > 0
  gte: (value) -> @compare(value) >= 0
  eq: (value) -> @compare(value) == 0
  equals: (value) -> @eq(value)

  toByteString: () -> new ByteString(_.str.lpad(@toString(16), 16, '0'), HEX)

  toString: (base) -> @_number.toString(base)
