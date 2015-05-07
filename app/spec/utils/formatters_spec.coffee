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


  it "should convert bits to Satoshi", ->
    res = formatters.fromMicroBtcToSatoshi(4.89)
    expect(res).toBe('489')
    res = formatters.fromMicroBtcToSatoshi(0.89)
    expect(res).toBe('89')
    res = formatters.fromMicroBtcToSatoshi(0.5555)
    expect(res).toBe('55')
    res = formatters.fromMicroBtcToSatoshi(895621.45)
    expect(res).toBe('89562145')

  it "should convert milli to Satoshi", ->
    res = formatters.fromMilliBtcToSatoshi(4.89)
    expect(res).toBe('489000')
    res = formatters.fromMilliBtcToSatoshi(12399)
    expect(res).toBe('1239900000')
    res = formatters.fromMilliBtcToSatoshi(0.89)
    expect(res).toBe('89000')
    res = formatters.fromMilliBtcToSatoshi(0.555555)
    expect(res).toBe('55555')


  it "should convert BTC to Satoshi", ->
    res = formatters.fromBtcToSatoshi(4.89)
    expect(res).toBe('489000000')
    res = formatters.fromBtcToSatoshi(89562551.45)
    expect(res).toBe('8956255145000000')
    res = formatters.fromBtcToSatoshi(0.45)
    expect(res).toBe('45000000')
    res = formatters.fromBtcToSatoshi(0.555555555)
    expect(res).toBe('55555555')
