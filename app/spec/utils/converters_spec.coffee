describe "Currency converters", ->

  converters = ledger.converters

  beforeEach (done) ->
    ledger.storage.sync = new ledger.storage.MemoryStore('i18n')
    ledger.tasks.TickerTask.instance.getCache = ->
      EUR:
        values: [
          {
            fromBTC:
              value: "250"
          },
          {
            toBTC:
              value: "0.0039"
          },
          {
            toSatoshis:
              value: "368189"
          }
        ]
    ledger.i18n.setFavLangByUI('en')
    .then -> ledger.i18n.setLocaleByUI('en-GB')
    .then -> done()



  it "should converts EUR to Satoshi", (done) ->
    res = converters.currencyToSatoshi(555, 'EUR')
    expect(res).toBe(204344895)
    done()


  it "should converts EUR to Satoshi - decimal number", (done) ->
    res = converters.currencyToSatoshi(555.78, 'EUR')
    expect(res).toBe(204632082)
    done()


  it "should converts Satoshi to EUR", (done) ->
    res = converters.satoshiToCurrency(9999999, 'EUR')
    expect(res).toBe('25.00')
    done()