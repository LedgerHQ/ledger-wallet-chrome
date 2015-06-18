describe "TickerTask", ->

  originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL

  beforeAll ->
    ledger.tasks.Task.stopAllRunningTasks()
    jasmine.DEFAULT_TIMEOUT_INTERVAL = 50000


  it "should set currencies into cache", (done) ->
    ledger.tasks.TickerTask.instance.start()
    ledger.tasks.TickerTask.instance.getCacheAsync (currencies) ->
      # Yes you have to repeat "jasmine.objectContaining()" for nested object...
      expect(currencies).toEqual jasmine.objectContaining
        EUR: jasmine.objectContaining
          name: "Euro"
          symbol: "€"
          ticker: "EUR"
        USD: jasmine.objectContaining
          name: "United States dollar"
          symbol: "$"
          ticker: "USD"
        GBP: jasmine.objectContaining
          name: "Pound sterling"
          symbol: "£"
          ticker: "GBP"
      expect(ledger.tasks.TickerTask.instance.getCache()).toEqual jasmine.objectContaining
        EUR: jasmine.objectContaining
          name: "Euro"
          symbol: "€"
          ticker: "EUR"
        USD: jasmine.objectContaining
          name: "United States dollar"
          symbol: "$"
          ticker: "USD"
        GBP: jasmine.objectContaining
          name: "Pound sterling"
          symbol: "£"
          ticker: "GBP"
      done()


  afterAll ->
    ledger.tasks.Task.resetAllSingletonTasks()
    ledger.tasks.Task.stopAllRunningTasks()
    jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout



