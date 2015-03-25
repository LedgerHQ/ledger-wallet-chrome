ledger.converters ?= {}

###
  This class is a namespace and cannot be instantiated
###
class ledger.converters

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
    Currency converter to satoshi

    @example Converts to Satoshi
      ledger.converters.currencyToSatoshi('USD', 50)

    @param [String] currency The currency that you want to convert
    @param [Number] currencyValue The amount in the given currency
    @return [Number] The formatted amount in satoshi
  ###
  @currencyToSatoshi: (currency, currencyValue) ->
    return if not currency? || not currencyValue?
    currencies = ledger.tasks.TickerTask.instance.getCache()
    # satoshiValueCurrency is the amount in Satoshi for 1 in the given currency
    satoshiValueCurrency = currencies[currency].values[2]['toSatoshis'].value
    satoshiValue = satoshiValueCurrency * currencyValue
    Math.round(satoshiValue)


  ###
    Converter from satoshi to a given currency

    @param [String] currency The currency to which you want your output
    @param [Number] satoshiValue The amount in satoshi
    @return [Number] The formatted amount in the given currency
  ###
  @satoshiToCurrency: (currency, satoshiValue) ->
    return if not currency? || not satoshiValue?
    currencies = ledger.tasks.TickerTask.instance.getCache()
    # currencyValueBTC is the amount in the given currency for 1 BTC
    currencyValueBTC = currencies[currency].values[0]['fromBTC'].value
    val = currencyValueBTC * Math.pow(10, -8)
    currencyValueSatoshi = val * satoshiValue
    return parseFloat(currencyValueSatoshi.toFixed(2))


  ###
    Converter from satoshi to a given currency with formatting

    @param [String] currency The currency to which you want your output
    @param [Number] satoshiValue The amount in satoshi
    @return [Number] The formatted amount in the given currency
  ###
  @satoshiToCurrencyFormatted: (currency, satoshiValue) ->
    return if not currency? || not satoshiValue?
    currencies = ledger.tasks.TickerTask.instance.getCache()
    # currencyValueBTC is the amount in the given currency for 1 BTC
    currencyValueBTC = currencies[currency].values[0]['fromBTC'].value
    val = currencyValueBTC * Math.pow(10, -8)
    currencyValueSatoshi = val * satoshiValue
    res = parseFloat(currencyValueSatoshi.toFixed(2))
    return ledger.i18n.formatAmount(res, currency)