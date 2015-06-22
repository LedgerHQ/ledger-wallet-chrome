describe "TransactionObserverTask", ->

  beforeEach ->
    ledger.tasks.TransactionObserverTask.instance.start()


  it "", ->


  afterEach ->
    ledger.tasks.Task.resetAllSingletonTasks()