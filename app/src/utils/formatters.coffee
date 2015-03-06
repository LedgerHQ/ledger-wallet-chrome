ledger.formatters ?= {}

###
  This class is a namespace and cannot be instantiated
###
class ledger.formatters.bitcoin

  @defaultFormat: 'BTC'

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
    From Satochi
  ###

  ###
    This generic method formats the input value in Satochi to an other unit (BTC, mBTC, uBTC). You can also specify the number of digits following the decimal point.

    @param [Number] value An input value in Satochi
    @param [String] unit The denomination of the currency
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [Number] The formatted value
  ###
  @formatCurrency: (value, unit, precision = -1) ->

    switch unit
      when 'BTC'
        unit = 8
      when 'mBTC'
        unit = 5
      when 'uBTC'
        unit = 2
      when 'satochi'
        unit = 0

    return if not value?
    # to string
    value = value.toString()
    # remove leading 0, add leading 0s until 9 digits
    value = _.str.ltrim value, '0'
    value = _.str.lpad(value, unit + 1, '0')

    # add .
    dotIndex = value.length - unit
    value = _.str.insert value, value.length - unit, '.'
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



  ###
    This method formats the amount with the default currency

    @param [Number] value An input value in Satochi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [Number] The formatted value
  ###
  @fromValue: (value, precision = -1) ->
    @formatCurrency(value, @defaultFormat , precision)


  ###
    This method converts Satochi to BTC

    @param [Number] value An input value in Satochi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [Number] The formatted value
  ###
  @fromSatochiToBTC: (value, precision = -1) ->
    @formatCurrency(value, "BTC", precision)



  ###
    This method converts Satochi to mBTC

    @param [Number] value An input value in Satochi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [Number] The formatted value
  ###
  @fromSatochiToMilliBTC: (value, precision = -1) ->
    @formatCurrency(value, "mBTC", precision)



  ###
    This method converts Satochi to uBTC

    @param [Number] value An input value in Satochi
    @param [Integer] precision Fixed number of decimal places (the number of digits following the decimal point)
    @return [Number] The formatted value
  ###
  @fromSatochiToMicroBTC: (value, precision = -1) ->
    @formatCurrency(value, "uBTC", precision)


  ###
    Whatever to Satochi
  ###

  ###
    This method converts BTC to Satochi

    @param [Number] value An input value in BTC
    @return [Number] The formatted value
  ###
  @fromBtcToSatochi: (value) ->
    return if not value?

    # Move decimal point + 8
    value = value * 100000000
    # to string
    value = value.toString()

    return value


  ###
    This method converts mBTC to Satochi

    @param [Number] value An input value in mBTC
    @return [Number] The formatted value
  ###
  @fromMilliBtcToSatochi: (value) ->
    return if not value?

    value = value * 100000
    # to string
    value = value.toString()

    return value


  ###
    This method converts uBTC to Satochi

    @param [Number] value An input value in uBTC
    @return [Number] The formatted value
  ###
  @fromMicroBtcToSatochi: (value) ->
    return if not value?

    value = value * 100
    # to string
    value = value.toString()

    return value



  ###
    Currency formatter to BTC

    @param [String] currency The currency that you want to convert
    @param [Number] currencyValue The amount in the given currency
    @return [String] The formatted amount in BTC
  ###
  @currencyToBTC: (currency, currencyValue) ->
    return if not currency? || not currencyValue?

    currencies = ledger.tasks.TickerTask.instance.getCache()
    # btcValueCurrency is the amount in BTC for 1 in the given currency
    btcValueCurrency = currencies[currency].values[1]['toBTC'].value
    btcValue = btcValueCurrency * currencyValue

    return btcValue.toFixed(8)


  ###
    Currency formatter to Satochi

    @param [String] currency The currency that you want to convert
    @param [Number] currencyValue The amount in the given currency
    @return [String] The formatted amount in Satochi
  ###
  @currencyToSatochi: (currency, currencyValue) ->
    return if not currency? || not currencyValue?

    currencies = ledger.tasks.TickerTask.instance.getCache()
    # satochiValueCurrency is the amount in Satochi for 1 in the given currency
    satochiValueCurrency = currencies[currency].values[2]['toSatoshis'].value
    satochiValue = satochiValueCurrency * currencyValue
    l(satochiValue)
    return satochiValue.toFixed()


  ###
    Formatter from Satochi to a given currency

    @param [String] currency The currency to which you want your output
    @param [Number] satochiValue The amount in Satochi
    @return [String] The formatted amount in the given currency
  ###
  @satochiToCurrency: (currency, satochiValue) ->
    return if not currency? || not satochiValue?

    currencies = ledger.tasks.TickerTask.instance.getCache()
    # currencyValueBTC is the amount in the given currency for 1 BTC
    currencyValueBTC = currencies[currency].values[0]['fromBTC'].value
    val = currencyValueBTC * Math.pow(10, -8)
    currencyValueSatochi = val * satochiValue
    return currencyValueSatochi.toFixed(4)




###
  Tests
###

#throwAnError = new ledger.formatters.bitcoin

#console.log(ledger.formatters.bitcoin.fromValue(1), 'fromValue');
#console.log(ledger.formatters.bitcoin.fromSatochiToBTC(1), 'fromSatochiToBTC');
#console.log(ledger.formatters.bitcoin.fromSatochiToMilliBTC(1), 'fromSatochiToMilliBTC');
#console.log(ledger.formatters.bitcoin.fromSatochiToMicroBTC(1), 'fromSatochiToMicroBTC');
#console.log(ledger.formatters.bitcoin.fromBtcToSatochi(1), 'fromBtcToSatochi');
#console.log(ledger.formatters.bitcoin.fromMilliBtcToSatochi(1), 'fromMilliBtcToSatochi');
#console.log(ledger.formatters.bitcoin.fromMicroBtcToSatochi(1), 'fromMicroBtcToSatochi');

#console.log(ledger.formatters.bitcoin.currencyFormatterToBTC('USD', 1), 'currencyFormatterToBTC');
