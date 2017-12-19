
###
  Put currencies in cache memory
###
class CurrencyCache

  constructor: ->
    @_cache = {}
    @_chromeStore = new ledger.storage.ChromeStore('ticker')

  get: -> @_cache

  set: (currencies) ->
    @_cache = currencies
    @_chromeStore.set {ticker_cache: currencies}

  isCacheEmpty: -> _.isEmpty(@_cache)


###
  Update tickers task
###
class ledger.tasks.FeesComputationTask extends ledger.tasks.Task

  @UpdateRate: 5 * 60 * 1000

  constructor: ->
    super('FeesComputationTask')
    @_client = new ledger.api.FeesRestClient()
    @_store = new ledger.storage.ChromeStore("fees_#{ledger.config.network.ticker}_cache")
    @_fees = {}
    @_store.get ['fees'], (result) =>
      @_fees = _(result['fees'] or {}).extend(@_fees)

  # Create a single instance of TickerTask
  @instance: new @()

  @reset: ->
    @instance.stopIfNeccessary()
    @instance = new @()

  onStart: ->
    super
    @_update(yes)

  onStop: ->
    super

  update: -> @_update(no)

  getFeesForNumberOfBlocks: (numberOfBlock) ->
    @_fees["#{numberOfBlock}"]

  getFeesForLevel: (level) ->
    value = @_fees["#{level.numberOfBlock}"] or level.defaultValue
    new @constructor.Fee(value, level)

  getFeesForLevelId: (levelId) -> @getFeesForLevel(ledger.preferences.fees.getLevelFromId(levelId))

  getFeesForPreferredLevel: -> @getFeesForLevelId(ledger.preferences.instance.getMiningFee())

  _update: (scheduleNext) ->
    return unless @isRunning()
    d = ledger.defer()
    @_client.getEstimatedFees (fees, error) =>
      if fees?
        if Object.keys(fees).length > 0
          @_updateFeesAndSave(fees)
      d.resolve()
      setTimeout((=> @_update(yes)), ledger.tasks.FeesComputationTask.UpdateRate) if scheduleNext
    d.promise

  _updateFeesAndSave: (newFees) ->
    @_fees = newFees
    @_store.set fees: @_fees
    @emit 'fees:updated'

class ledger.tasks.FeesComputationTask.Fee

  constructor: (@value, @level) ->

  isBeyondDefaultValue: -> @value > @level.defaultValue
  isBeyondMaxValue: -> @value > ledger.preferences.fees.MaxValue
