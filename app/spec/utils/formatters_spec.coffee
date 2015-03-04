describe "formatters", ->

  it "should return 100000000", ->
    expect(ledger.formatters.bitcoin.fromValue(1, 'BTC', -1).toBe(100000000))