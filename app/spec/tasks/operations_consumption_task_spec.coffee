xdescribe "OperationsConsumptionTask", ->

  beforeEach ->
    ledger.tasks.OperationsConsumptionTask.instance.start()

  xit "should retrieve account operations", ->

  afterEach ->
    ledger.tasks.Task.resetAllSingletonTasks()