describe "Currency converters", ->

  converters = ledger.converters

  beforeEach ->
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


  it "should converts EUR to Satoshi", ->
    res = converters.currencyToSatoshi(555, 'EUR')
    expect(res).toBe(204344895)


  it "should converts EUR to Satoshi - decimal number", ->
    res = converters.currencyToSatoshi(555.78, 'EUR')
    expect(res).toBe(204632082)


  it "should converts Satoshi to EUR", ->
    res = converters.satoshiToCurrency(9999999, 'EUR')
    expect(res).toBe('25.00')