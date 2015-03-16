@ledger ?= {}

class @ledger.Amount

  Amount = @

  # @param [String, Number] value A BTC amount.
  @fromBtc: (value) ->
    return value if _.isKindOf(value, Amount)
    @fromSatoshi(+value * 10e7)

  # @param [String, Number] value A satoshi amount.
  @fromSatoshi: (value) ->
    return value if _.isKindOf(value, Amount)
    new Amount(Math.trunc(+value).toString())

  # @param [Bitcoin.BigInteger] value The amount value in satoshi.
  constructor: (@_number) ->
    @_number = value

  # @param [ledger.Amount] amount
  # @return [ledger.Amount]
  add: (amount) ->
    new Amount(@_number.add(amount._number))

  # @param [ledger.Amount] amount
  # @return [ledger.Amount]
  substract: (amount) ->
    new Amount(@_number.substract(amount._number))

  # @param [String, Number, Bitcoin.BigInteger] number
  # @return [ledger.Amount]
  multiply: (number) ->
    number = new Bitcoin.BigInteger(number.toString()) unless _(number).isKindOf(Bitcoin.BigInteger)
    new Amount(@_number.multiply(value._number))

  # @param [ledger.Amount] amount
  # @return [Number]
  compare: (amount) ->
    @_number.compareTo(value.amount)

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
  toBtcString: (base=10) -> @_number.toString(base)
  # @return [Number]
  toBtcNumber: () -> @_number.intValue()
  # @param [Number] base 10 or 16
  # @return [String]
  toSatoshiString: (base=10) -> @_number.toString(base)
  # @return [Number]
  toSatoshiNumber: () -> @_number.intValue()
  # @return [Bitcoin.BigInteger]
  toBigInteger: () -> @_number.clone()
