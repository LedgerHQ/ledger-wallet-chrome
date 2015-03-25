@ledger ?= {}

class @ledger.Amount

  Amount = @

  # @param [String, Number] value A BTC amount.
  @fromBtc: (value) ->
    return value if _.isKindOf(value, Amount)
    @fromSatoshi(+value * 1e8)

  # @param [String, Number] value A bits (aka µBTC) amount.
  @fromBits: (value) ->
    return value if _.isKindOf(value, Amount)
    @fromSatoshi(+value * 1e2)

  # @param [String, Number] value A satoshi amount.
  @fromSatoshi: (value) ->
    return value if _.isKindOf(value, Amount)
    new Amount(new Bitcoin.BigInteger(Math.trunc(+value).toString()))

  # @param [Bitcoin.BigInteger] value The amount value in satoshi.
  constructor: (value) ->
    @_number = value.clone()

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
  toSatoshiNumber: () -> @_number.intValue()
  # @return [Bitcoin.BigInteger]
  toBigInteger: () -> @_number.clone()
