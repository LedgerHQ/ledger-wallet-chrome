describe "WalletOpenTask", ->

  beforeEach ->
    ledger.tasks.WalletOpenTask.instance.start()


  it "", ->


  afterEach ->
    ledger.tasks.Task.resetAllSingletonTasks()