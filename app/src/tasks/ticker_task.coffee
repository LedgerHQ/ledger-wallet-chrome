###
  Put currencies in cache memory
###
class CurrencyCache

  _cache: {}

  get: () ->
    return @_cache

  set: (currencies) ->
    @_cache = currencies


###
  Update tickers task
###
class ledger.tasks.TickerTask extends ledger.tasks.Task

  constructor: () ->
    super('tickerTaskID')
    @_currenciesRestClient = new ledger.api.CurrenciesRestClient
    @_cache = new CurrencyCache


  # Create a single instance of TickerTask
  @instance: new @()

  @reset: () ->
    @instance = new @

  onStart: () ->
    super
    @updateTicker()

  updateTicker: () ->
    return unless @isRunning()
    @_currenciesRestClient.getAllCurrencies (currencies, error) =>
      @_cache.set(currencies)
      #10 minutes * 60 seconds * 1000 milliseconds = 600000ms
      setTimeout((() => @updateTicker()), 600000)
      #l(@_cache.get())
      return


  getCache: () ->
    @_cache.get()
