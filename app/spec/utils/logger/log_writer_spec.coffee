describe "Log Writer", ->

  lw = null
  lr = null

  beforeEach (done) ->
    lw = new ledger.utils.LogWriter(2, TEMPORARY)
    lr = new ledger.utils.LogReader(2, TEMPORARY)
    lw.deleteAll(->
      l 'AFTER deleteALL'
      done())


  it "should write in correct order", (done) ->
    for str in [0...50]
      l 'line'
      line = "date lorem ipsum blabla msg outing to bla - test #{str}"
      lw.write line

    lr.read (logs) ->
      l logs
      for log, i in logs
        expect(log).toBe("date lorem ipsum blabla msg outing to bla - test #{i}")
      expect(logs.length).toBe(50)
      done()