ledger.formatters ?= {}

###
  This class is a namespace and cannot be instantiated
###
class ledger.formatters

  ###
    This constructor prevent the class to be instantiated

    @throw [Object] error Throw an error when user try to instantiates the class
  ###
  constructor: ->
    throw new Error('This class cannot be instantiated')

  ###
    This generic method formats the input value in satoshi to an other unit (BTC, mBTC, bits). You can also specify the number of digits following the decimal point.

    @param [Number] value An input value in satoshi
    @param [String] unit The denomination of the unit
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @formatUnit: (value, unit, precision = -1) ->
    return if not value? or not unit?
    found = no
    for k, v of ledger.preferences.defaults.Display.units
      if v.symbol == unit
        unit = v.unit
        found = yes
        break
    throw new Error("unit must be in " + _.reduce(ledger.preferences.instance.getAllBitcoinUnits(), (cumul, unit) -> return cumul + ', ' + unit), '') if found == no

    integerPart = new Bitcoin.BigInteger(value.toString())
    .divide Bitcoin.BigInteger.valueOf(10).pow(unit)

    fractionalPartTmp = new Bitcoin.BigInteger(value.toString())
    .mod Bitcoin.BigInteger.valueOf(10).pow(unit)
    fractionalPart = _.str.lpad(fractionalPartTmp, unit, '0')

    if (precision is -1)
      fractionalPart = fractionalPart.replace(/\.?0+$/, '')
    else
      if(fractionalPart < precision)
        fractionalPart = _.str.rpad(fractionalPart, precision, '0')
      else
        d = fractionalPart.length - precision
        fractionalPart = parseFloat(fractionalPart) / Math.pow(10, d)
        fractionalPart = _.str.lpad(Math.ceil(fractionalPart).toString(), precision, '0')

    value = integerPart + '.' + fractionalPart
    # remove . if necessary
    if _.str.endsWith value, '.'
      value = _.str.splice value, -1, 1
    return value


  ###
    This method formats the amount with the default currency

    @param [Number] value An input value in satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromValue: (value, precision) ->
    @formatUnit(value, ledger.preferences.instance.getBtcUnit(), precision)


  ###
    This method formats the amount and add symbol
  ###
  @formatValue: (value, precision) ->
    num = @formatUnit(value, ledger.preferences.instance.getBtcUnit(), precision)
    if @symbolIsFirst()
      return @getUnitSymbol() + ' ' + num
    else
      return num + ' ' + @getUnitSymbol()


  ###
    Symbol order
  ###
  @symbolIsFirst: ->
    isNaN parseInt(ledger.i18n.formatAmount(0, ledger.preferences.defaults.Display.units.bitcoin.symbol).charAt(0))


  ###
    Add unit symbol
  ###
  @getUnitSymbol: ->
    ledger.preferences.instance.getBtcUnit()


  ###
    This method converts Satoshi to BTC

    @param [Number] value An input value in satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromSatoshiToBTC: (value, precision) ->
    @formatUnit(value, ledger.preferences.defaults.Display.units.bitcoin.symbol, precision)


  ###
    This method converts Satoshi to mBTC

    @param [Number] value An input value in Satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromSatoshiToMilliBTC: (value, precision) ->
    @formatUnit(value, ledger.preferences.defaults.Display.units.milibitcoin.symbol, precision)


  ###
    This method converts Satoshi to bits/uBTC

    @param [Number] value An input value in Satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromSatoshiToMicroBTC: (value, precision) ->
    @formatUnit(value, ledger.preferences.defaults.Display.units.microbitcoin.symbol, precision)


  ###
    Whatever to Satoshi
  ###

  ###
    This method converts BTC to Satoshi

    @param [Number] value An input value in BTC
    @return [String] The formatted value
  ###
  @fromBtcToSatoshi: (value) ->
    return if not value?
    value = value * Math.pow(10, ledger.preferences.defaults.Display.units.bitcoin.unit)
    # to string
    value = value.toString()


  ###
    This method converts mBTC to Satoshi

    @param [Number] value An input value in mBTC
    @return [String] The formatted value
  ###
  @fromMilliBtcToSatoshi: (value) ->
    return if not value?
    value = value * Math.pow(10, ledger.preferences.defaults.Display.units.milibitcoin.unit)
    # to string
    value = value.toString()


  ###
    This method converts uBTC to Satoshi

    @param [Number] value An input value in uBTC
    @return [String] The formatted value
  ###
  @fromMicroBtcToSatoshi: (value) ->
    return if not value?
    value = value * Math.pow(10, ledger.preferences.defaults.Display.units.microbitcoin.unit)
    # to string
    value = value.toString()