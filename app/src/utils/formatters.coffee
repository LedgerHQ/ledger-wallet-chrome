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
    try
      throw new Error('This class cannot be instantiated')
    catch e
      console.log(e.name + ": " + e.message)


  ###
    This generic method formats the input value in satoshi to an other unit (BTC, mBTC, uBTC). You can also specify the number of digits following the decimal point.

    @param [Number] value An input value in satoshi
    @param [String] unit The denomination of the unit
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @formatUnit: (value, unit, precision = -1) ->
    return if not value? or not unit?
    switch unit
      when 'BTC'
        unit = 8
      when 'mBTC'
        unit = 5
      when 'uBTC'
        unit = 2
      when 'satoshi'
        unit = 0
      else
        try
          throw new Error("'BtcUnit' must be BTC, mBTC, uBTC or satoshi")
        catch e
          console.log(e.name + ": " + e.message)
    # Check if value is an integer
    if !(value == parseInt(value, 10))
      throw new Error('Satoshi value must be an integer')
    #val = value * Math.pow(10, -unit)
    #l(val)
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
    @formatUnit(value, ledger.preferences.instance.getUIBtcUnit(), precision)


  ###
    This method converts Satoshi to BTC

    @param [Number] value An input value in satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromSatoshiToBTC: (value, precision) ->
    @formatUnit(value, "BTC", precision)


  ###
    This method converts Satoshi to mBTC

    @param [Number] value An input value in Satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromSatoshiToMilliBTC: (value, precision) ->
    @formatUnit(value, "mBTC", precision)


  ###
    This method converts Satoshi to uBTC

    @param [Number] value An input value in Satoshi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [String] The formatted value
  ###
  @fromSatoshiToMicroBTC: (value, precision) ->
    @formatUnit(value, "uBTC", precision)


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
    value = value * Math.pow(10, 8)
    # to string
    value = value.toString()


  ###
    This method converts mBTC to Satoshi

    @param [Number] value An input value in mBTC
    @return [String] The formatted value
  ###
  @fromMilliBtcToSatoshi: (value) ->
    return if not value?
    value = value * Math.pow(10, 5)
    # to string
    value = value.toString()


  ###
    This method converts uBTC to Satoshi

    @param [Number] value An input value in uBTC
    @return [String] The formatted value
  ###
  @fromMicroBtcToSatoshi: (value) ->
    return if not value?
    value = value * Math.pow(10, 2)
    # to string
    value = value.toString()