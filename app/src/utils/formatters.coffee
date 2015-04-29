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

    decimalSeparator = ledger.number.getLocaleDecimalSeparator(ledger.preferences.instance.getLocale().replace('_', '-'))
    thousandSeparator = ledger.number.getLocaleThousandSeparator(ledger.preferences.instance.getLocale().replace('_', '-'))

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

    reverseIntegerPart = integerPart.toString().match(/./g).reverse()
    integerPart = []
    for digit, index in reverseIntegerPart
      integerPart.push digit
      integerPart.push thousandSeparator if (index + 1) % 3 == 0 and (index + 1) < reverseIntegerPart.length
    value = integerPart.reverse().join('') + decimalSeparator + fractionalPart
    # remove . if necessary
    if _.str.endsWith value, decimalSeparator
      value = _.str.splice value, -1, 1
    value


  ###
    This method formats the amount with the default currency

    @param [Number] value An input value in satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromValue: (value, precision) ->
    @formatUnit(value, @_getBtcUnit(), precision)


  ###
    This method formats the amount and add symbol
  ###
  @formatValue: (value, precision) ->

    num = @formatUnit(value, @_getBtcUnit(), precision)
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
    @_getBtcUnit()


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
    @_formatUnitToSatoshi(value, 'bitcoin')


  ###
    This method converts mBTC to Satoshi

    @param [Number] value An input value in mBTC
    @return [String] The formatted value
  ###
  @fromMilliBtcToSatoshi: (value) ->
    return if not value?
    @_formatUnitToSatoshi(value, 'milibitcoin')


  ###
    This method converts uBTC/bits to Satoshi

    @param [Number] value An input value in uBTC
    @return [String] The formatted value
  ###
  @fromMicroBtcToSatoshi: (value) ->
    return if not value?
    @_formatUnitToSatoshi(value, 'microbitcoin')


  # This generic method formats the input value in units (BTC, mBTC, bits) to Satoshi
  @_formatUnitToSatoshi: (value, _name) ->
    [intPart, fracPart] = value.toString().split(".")
    fracPart ?= ''
    # Check if value should be truncated
    if fracPart.length > ledger.preferences.defaults.Display.units[_name].unit
      @_logger().warn('Fractional part cannot be less than one Satoshi')
      fracPart = fracPart.substring(0, ledger.preferences.defaults.Display.units[_name].unit)
    else
      fracPart = _.str.rpad(fracPart, ledger.preferences.defaults.Display.units[_name].unit, '0')
    res = intPart + fracPart
    num = new Bitcoin.BigInteger(res.toString())
    num.toString()


  @fromValueToSatoshi: (value) ->
    switch @getUnitSymbol()
      when ledger.preferences.defaults.Display.units.bitcoin.symbol then return @fromBtcToSatoshi(value)
      when ledger.preferences.defaults.Display.units.milibitcoin.symbol then return @fromMilliBtcToSatoshi(value)
      when ledger.preferences.defaults.Display.units.microbitcoin.symbol then return @fromMicroBtcToSatoshi(value)
    undefined

  @_logger: ->
    ledger.utils.Logger.getLoggerByTag('Formatters')

  ###
    This private method defaults to BTC when preferences are not yet ready
    (API calls don't wait for the wallet to be fully initialized)

    @return [String] The BTC formatting unit
  ###
  @_getBtcUnit: ->
    if ledger.preferences.instance?
      ledger.preferences.instance.getBtcUnit()
    else
      'BTC'
