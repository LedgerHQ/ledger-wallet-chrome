# A store able to synchronize with a remote crypted store. This store has an extra method in order to order a push or pull
# operations
# @event pulled Emitted once the store is pulled from the remote API
class ledger.storage.SyncedStore extends ledger.storage.SecureStore

  PULL_INTERVAL_DELAY: ledger.config.syncRestClient.pullIntervalDelay || 10000
  PULL_THROTTLE_DELAY: ledger.config.syncRestClient.pullThrottleDelay || 1000
  PUSH_DEBOUNCE_DELAY: ledger.config.syncRestClient.pushDebounceDelay || 1000

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt/decrypt the store
  # @param [Function] syncPushHandler A function used to perform push synchronization operations
  # @param [Function] syncPullHandler A function used to perform pull synchronization operations
  constructor: (name, addr, key) ->
    super(name, key)
    @mergeStrategy = @_overwriteStrategy
    @client = ledger.api.SyncRestClient.instance(addr)
    @throttled_pull = _.throttle _.bind(@._pull,@), @PULL_THROTTLE_DELAY
    @debounced_push = _.debounce _.bind(@._push,@), @PUSH_DEBOUNCE_DELAY
    _.defer =>
      ledger.storage.wallet.get ['__last_sync_md5'], (item) =>
        @lastMd5 = item.__last_sync_md5
        @_initConnection()

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->
    super items, =>
      this.debounced_push()
      cb?()

  # Removes one or more items from storage.
  #
  # @param [Array|String] key A single key to get, list of keys to get.
  # @param [Function] cb A callback invoked once the removal is done.
  remove: (keys, cb) ->
    super keys, =>
      this.debounced_push()
      cb?()

  clear: (cb) ->
    super(cb)
    @client.delete_settings()

  # @return A promise
  _pull: ->
    @client.get_settings_md5().then( (md5) =>
      return undefined if md5 == @lastMd5
      @client.get_settings().then (items) =>
        @mergeStrategy(items).then =>
          @_setLastMd5(md5)
          @emit('pulled')
          items
    ).catch( (jqXHR) =>
      # Data not synced already
      return this._init() if jqXHR.status == 404
      jqXHR
    )

  # @return A jQuery promise
  _push: ->
    d = Q.defer()
    this._raw_get null, (raw_items) =>
      settings = {}
      for raw_key, raw_value of raw_items
        settings[raw_key] = raw_value if raw_key.match(@_nameRegex)
      @__retryer (ecbr) =>
        @client.put_settings(settings).catch(ecbr).then (md5) =>
          @_setLastMd5(md5)
          d.resolve(md5)
      , _.bind(d.reject,d)
    , _.bind(d.reject,d)
    d.promise

  # @return A jQuery promise
  _overwriteStrategy: (items) ->
    d = Q.defer()
    this._raw_set items, _.bind(d.resolve,d)
    d.promise

  # Call fct with ecbr as arg and retry it on fail.
  # Wait 1 second before retry first time, double until 64 s then.
  #
  # @param [Function] fct A function invoked with ecbr, a retry on error callback.
  # @param [Function] ecb A callback invoked when retry all fail.
  __retryer: (fct, ecb, wait=1000) ->
    fct (err) =>
      if wait <= 64*1000
        setTimeout (=> @__retryer(fct, ecb, wait*2)), wait
      else
        console.error(err)
        ecb?(err)

  _initConnection: ->
    @__retryer (ecbr) =>
      @_pull().then( =>
        setTimeout =>
          @pullTimer = setInterval(@throttled_pull, @PULL_INTERVAL_DELAY)
        , @PULL_INTERVAL_DELAY
      ).catch (jqXHR) =>
        # Data not synced already
        if jqXHR.status == 404
          this._init().catch(ecbr).then =>
            setInterval(@throttled_pull, @PULL_INTERVAL_DELAY)
        else if jqXHR.status == 400
          console.error("BadRequest during SyncedStore initialization:", jqXHR)
        else
          ecbr(jqXHR)
    ledger.app.wallet.once 'state:changed', =>
      clearInterval(@pullTimer) if ledger.app.wallet._state != ledger.wallet.States.UNLOCKED

  # @param [Function] cb A callback invoked once init is done. cb()
  # @param [Function] ecb A callback invoked when init fail. Take $.ajax.fail args.
  # @return A jQuery promise
  _init: ->
    d = Q.defer()
    this._raw_get null, (raw_items) =>
      settings = {}
      for raw_key, raw_value of raw_items
        settings[raw_key] = raw_value if raw_key.match(@_nameRegex)
      @__retryer (ecbr) =>
        @client.post_settings(settings).catch(ecbr).then (md5) =>
          @_setLastMd5(md5)
          d.resolve(md5)
      , _.bind(d.reject,d)
    , _.bind(d.reject,d)
    d.promise

  # Save lastMd5 in settings
  _setLastMd5: (md5) ->
    @lastMd5 = md5
    ledger.storage.wallet.set("__last_sync_md5": md5)
