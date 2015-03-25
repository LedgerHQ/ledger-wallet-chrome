ledger.wallet ?= {}

Value = null

class ledger.wallet.Value

  Value = @

  @from: (value) ->
    return value if _.isKindOf(value, ledger.wallet.Value)
    out = switch
      when _.isString value
        [integerPart, fractionalPart] = value.split('.')

        fractionalPart = _.str.rpad(fractionalPart, 8, '0')
        v = new Bitcoin.BigInteger(integerPart)
        .multiply Bitcoin.BigInteger.valueOf(10e+7)
        .add(new Bitcoin.BigInteger(fractionalPart))
        new ledger.wallet.Value(v)
      when _.isNumber value then new Value(value)
    out

  constructor: (value = Bitcoin.BigInteger.ZERO) ->
    if _(value).isKindOf(Bitcoin.BigInteger)
      @_number = value
      return this
    @_number = new Bitcoin.BigInteger(value.toString())

  add: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.add(value._number))

  subtract: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.subtract(value._number))

  multiply: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.multiply(value._number))

  divide: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.divide(value._number))

  pow: (e) ->
    e = Value.from(e) unless _(e).isKindOf(ledger.wallet.Value)
    new Value(@_number.pow(e._number))

  mod: (value) ->
    value = Value.from(value) unless _(value).isKindOf(ledger.wallet.Value)
    new Value(@_number.mod(value._number))

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

  toNumber: () -> @_number.intValue()
