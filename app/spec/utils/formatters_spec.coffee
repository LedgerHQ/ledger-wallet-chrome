describe "Unit Formatters -", ->

  formatters = ledger.formatters

  it "should return a String", ->
    res = formatters.formatUnit(1000, 'BTC', -1)
    expect(res).toEqual( jasmine.any(String) )
    res = formatters.fromSatoshiToBTC(1000)
    expect(res).toEqual( jasmine.any(String) )
    res = formatters.fromValue(1000)
    expect(res).toEqual( jasmine.any(String) )
    res = formatters.fromSatoshiToMilliBTC(1000)
    expect(res).toEqual( jasmine.any(String) )
    res = formatters.fromSatoshiToMicroBTC(1000)
    expect(res).toEqual( jasmine.any(String) )


  it "should .0xx have not effect", ->
    expect(formatters.formatUnit(10.00, 'BTC')).toBe('0.0000001')


  it "should converts to BTC", ->
    res = formatters.formatUnit(1000, 'BTC')
    expect(res).toBe('0.00001')
    res = formatters.fromSatoshiToBTC(1000)
    expect(res).toBe('0.00001')


  it "should converts to mBTC", ->
    res = formatters.formatUnit(1000, 'mBTC')
    expect(res).toBe('0.01')
    res = formatters.fromSatoshiToMilliBTC(1000)
    expect(res).toBe('0.01')


  it "should converts to bits/uBTC", ->
    res = formatters.formatUnit(1000, 'bits')
    expect(res).toBe('10')
    res = formatters.fromSatoshiToMicroBTC(1000)
    expect(res).toBe('10')


  it "should round correctly", ->
    res = formatters.formatUnit(9678978, 'BTC', 3)
    expect(res).toBe('0.097')

  it "should test fromValue() with default to BTC", ->
    try
      ledger.preferences.instance.setBtcUnit('BTC')
    catch e
      throw new Error 'App must be initialized ' + e
    res = formatters.fromValue(9678978)
    expect(res).toBe('0.09678978')
    res = formatters.fromValue(9678978, 6)
    expect(res).toBe('0.096790')
    res = formatters.fromValue(967897800, -1)
    expect(res).toBe('9.678978')