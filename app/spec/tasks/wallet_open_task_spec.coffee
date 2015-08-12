xdescribe "WalletOpenTask", ->

  beforeEach ->
    ledger.tasks.WalletOpenTask.instance.start()

  afterEach ->
    ledger.tasks.Task.resetAllSingletonTasks()

  it "should", ->