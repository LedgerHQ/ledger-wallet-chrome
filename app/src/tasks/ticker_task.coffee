###
  Put currencies in cache memory
###
class CurrencyCache

  _cache: {}
  _chromeStore: new ledger.storage.ChromeStore('ticker')
  #chromeStore.get 'ticker_cache', (r) =>
  # _cache = r.ticker_cache?


  get: () ->
    return @_cache

  set: (currencies) ->
    @_cache = currencies
    @_chromeStore.set {ticker_cache: currencies}

  isCacheEmpty: () ->
    _.isEmpty(@_cache)


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
    @_updateTicker yes

  updateTicker: -> @_updateTicker no

  _updateTicker: (scheduleNext) ->
    return unless @isRunning()
    @_currenciesRestClient.getAllCurrencies (currencies) =>
      @_cache.set(currencies)
      #5 minutes * 60 seconds * 1000 milliseconds = 600000ms
      setTimeout((() => @updateTicker()), 300000) if scheduleNext
      @emit 'updated', @_cache.get()
      #l @_cache.get()

  getCache: () ->
    @_cache.get()

  getCacheAsync: (callback=undefined) ->
    if @_cache.isCacheEmpty()
      @once 'updated', (event, data) => callback?(data)
      @_updateTicker no
    else
      callback?(@_cache.get())
