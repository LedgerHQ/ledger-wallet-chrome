describe "TickerTask", ->

  tickerTask = null

  beforeAll (done) ->
    tickerTask = new ledger.tasks.TickerTask
    done()

  it "should set currencies into cache", (done) ->
    tickerTask.updateTicker()
    tickerTask.once 'updated', ->
      # Yes you have to repeat "jasmine.objectContaining()" for nested object...
      expect(tickerTask.getCache()).toEqual jasmine.objectContaining
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



