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

    @param [Number] currencyValue The amount in the given currency
    @param [String] currency The currency that you want to convert
    @return [Number] The formatted amount in satoshi
  ###
  @currencyToSatoshi: (currencyValue, currency) =>
    currency ?= ledger.preferences.instance.getCurrency()
    currencies = ledger.tasks.TickerTask.instance.getCache()
    # satoshiValueCurrency is the amount in Satoshi for 1 in the given currency
    satoshiValueCurrency = currencies[currency].values[2]['toSatoshis'].value || 0
    satoshiValue = satoshiValueCurrency * currencyValue
    Math.round(satoshiValue)


  ###
    Converter from satoshi to a given currency

    @param [Number] satoshiValue The amount in satoshi
    @param [String] currency The currency to which you want your output
    @return [Number] The formatted amount in the given currency
  ###
  @satoshiToCurrency: (satoshiValue, currency) =>
    currency ?= ledger.preferences.instance.getCurrency()
    currencies = ledger.tasks.TickerTask.instance.getCache()

    # currencyValueBTC is the amount in the given currency for 1 BTC
    currencyValueBTC = currencies[currency].values[0]['fromBTC'].value || 0
    val = currencyValueBTC * Math.pow(10, -8)
    currencyValueSatoshi = val * satoshiValue
    ledger.i18n.formatNumber(parseFloat(currencyValueSatoshi.toFixed(2)))

  ###
    Converter from satoshi to a given currency with formatting

    @param [Number] satoshiValue The amount in satoshi
    @param [String] currency The currency to which you want your output
    @return [Number] The formatted amount in the given currency
  ###
  @satoshiToCurrencyFormatted: (satoshiValue, currency) =>
    currency ?= ledger.preferences.instance.getCurrency()
    currencies = ledger.tasks.TickerTask.instance.getCache()
    
    if currencies?[currency]?.values?[0]?['fromBTC']?.value?
      # currencyValueBTC is the amount in the given currency for 1 BTC
      currencyValueBTC = currencies[currency].values[0]['fromBTC'].value || 0
      val = currencyValueBTC * Math.pow(10, -8)
      currencyValueSatoshi = val * satoshiValue
      res = parseFloat(currencyValueSatoshi.toFixed(2))
    else
      res = undefined
    return ledger.i18n.formatAmount(res, currency)