describe "Log Abstract Class", ->

  beforeEach ->
    log = new ledger.utils.Log()
    log.deleteAll()

  ###
  it "FS should not have log files older than 2 days", ->
    clear = setTimeout (-> new ledger.utils.LogWriter()
      #expect().toBe()

    ), 200
  ###