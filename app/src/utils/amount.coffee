@ledger ?= {}

class @ledger.Amount

  Amount = @

  # @param [String, Number] value A satoshi amount.
  @fromSatoshi: (value) ->
    return value if _.isKindOf(value, Amount)
    return new Amount(value) if _.isKindOf(value, Bitcoin.BigInteger)
    new Amount(new Bitcoin.BigInteger(value.toString()))

  # @param [Bitcoin.BigInteger] value The amount value in satoshi.
  constructor: (value=Bitcoin.BigInteger.ZERO) ->
    @_value = value.clone()

  # @param [ledger.Amount] amount
  # @return [ledger.Amount]
  add: (amount) ->
    amount = Amount.fromSatoshi(amount)
    new Amount(@_value.add(amount._value))

  # @param [ledger.Amount] amount
  # @return [ledger.Amount]
  subtract: (amount) ->
    amount = Amount.fromSatoshi(amount)
    new Amount(@_value.subtract(amount._value))

  # @param [String, Number, Bitcoin.BigInteger] number
  # @return [ledger.Amount]
  multiply: (number) ->
    number = Amount.fromSatoshi(number)
    new Amount(@_value.multiply(number._value))

  pow: (e) ->
    e = Amount.fromSatoshi(e)
    new Amount(@_value.pow(e._value))

  mod: (amount) ->
    amount = Amount.fromSatoshi(amount)
    new Amount(@_value.mod(amount._value))

  divide: (amount) ->
    amount = Amount.fromSatoshi(amount)
    new Amount(@_value.divide(amount._value))

  # @param [ledger.Amount, Number, ] amount
  # @return [Number]
  compare: (amount) ->
    amount = Amount.fromSatoshi(amount)
    @_value.compareTo(amount._value)

  # @return [Boolean]
  lt: (amount) -> @compare(amount) < 0
  # @return [Boolean]
  lte: (amount) -> @compare(amount) <= 0
  # @return [Boolean]
  gt: (amount) -> @compare(amount) > 0
  # @return [Boolean]
  gte: (amount) -> @compare(amount) >= 0
  # @return [Boolean]
  eq: (amount) -> @compare(amount) == 0
  # @return [Boolean]
  equals: (amount) -> @eq(amount)

  # @return [ByteString]
  toByteString: () -> new ByteString(_.str.lpad(@toSatoshiString(16), 16, '0'), HEX)
  # @param [Number] base 10 or 16
  # @return [String]
  toBtcString: (base=10) -> @toBtcNumber().toString(base)
  # @return [Number]
  toBtcNumber: () -> @toSatoshiNumber() / 1e8
  # @param [Number] base 10 or 16
  # @return [String]
  toBitsString: (base=10) -> @toBitsNumber().toString(base)
  # @return [Number]
  toBitsNumber: () -> @toSatoshiNumber() / 1e2
  # @param [Number] base 10 or 16
  # @return [String]
  toSatoshiString: (base=10) -> @toSatoshiNumber().toString(base)
  # @return [Number]
  toSatoshiNumber: () -> @_value.intValue()
  # @return [Bitcoin.BigInteger]
  toBigInteger: () -> @_value.clone()
  toNumber: -> @_value.intValue()
  toString: (base) -> @_value.toString(base)
