describe "Secure Log Writer/Reader", ->

  slw = null
  slr = null

  @_errorHandler = (e) ->
    fail "FileSystem Error. name: #{e.name} // message: #{e.message}"
    l new Error().stack

  beforeEach (done) ->
    ledger.utils.Log.deleteAll TEMPORARY, ->
      slr = new ledger.utils.SecureLogReader('test_key', '1YnMY5FGugkuzJwdmbue9EtfsAFpQXcZy', 2, TEMPORARY)
      slw = new ledger.utils.SecureLogWriter('test_key', '1YnMY5FGugkuzJwdmbue9EtfsAFpQXcZy', 2, TEMPORARY)
      do done

  it "should write secure in correct order", (done) ->
    for str in [0...50]
      line = "date lorem ipsum blabla msg outing to bla - test #{str}"
      slw.write line
    slw.getFlushPromise().then ->
      slr.read (logs) ->
        for log, i in logs
          expect(log).toBe("date lorem ipsum blabla msg outing to bla - test #{i}")
        expect(logs.length).toBe(50)
        done()


  it "should encrypt correctly", (done) ->
    slw.write "date lorem ipsum blabla msg outing to bla - test"
    slw.write "nawak nawak double nawak bitcoin will spread the world !"
    slw.getFlushPromise().then ->
      ledger.utils.Log.getFs(TEMPORARY).then (fs) ->
        dirReader = fs.root.createReader()
        dirReader.readEntries (files) =>
          loopFiles = (index, files) =>
            file = (files || [])[index]
            return done() unless file?
            file.file (file) ->
              reader = new FileReader()
              reader.onloadend = (e) ->
                res = _.compact reader.result.split('\n')
                expect(res[0]).toBe("nm44bNrVL0WTwQE/dUSPEkKhhIEA9mtsYa8l1tbCh6wmXCN57tZ0LK6YMC7V4s0DwPF6w4QBPTeI/lLrO6icfQ==")
                expect(res[1]).toBe("lG47aJGZLlaBzUp2YViPHQ6myI4D7WsnLL4rgtrYmqtoTGph7dZlML3dfGqB89YSyQUMJIBJEYIzZK/y82Y6EbhYLDcVOoYg")
                loopFiles index + 1, files
              reader.readAsText(file)
          loopFiles 0, files
