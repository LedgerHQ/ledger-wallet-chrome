# A store able to synchronize with a remote crypted store. This store has an extra method in order to order a push or pull
# operations
class ledger.storage.SyncedStore extends ledger.storage.SecureStore

  PULL_INTERVAL_DELAY: ledger.config.syncRestClient.pullIntervalDelay || 10000
  PULL_THROTTLE_DELAY: ledger.config.syncRestClient.pullThrottleDelay || 1000
  PUSH_DEBOUNCE_DELAY: ledger.config.syncRestClient.pushDebounceDelay || 1000

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt/decrypt the store
  # @param [Function] syncPushHandler A function used to perform push synchronization operations
  # @param [Function] syncPullHandler A function used to perform pull synchronization operations
  constructor: (name, addr, key) ->
    console.log(name, addr, key)
    super(name, key)
    @mergeStrategy = @_overwriteStrategy
    @client = new ledger.api.SyncRestClient(addr)
    @throttled_pull = _.throttle _.bind(@._pull,@), @PULL_THROTTLE_DELAY
    @debounced_push = _.debounce _.bind(@._push,@), @PUSH_DEBOUNCE_DELAY
    _.defer => @_initConnection()

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

  # @return A jQuery promise
  _pull: ->
    d = jQuery.Deferred()
    @client.get_settings_md5().done( (md5) =>
      if md5 != @lastMd5
        @client.get_settings().fail(_.bind(d.reject,d)).done (items) =>
          @mergeStrategy(items).done =>
            @lastMd5 = md5
            d.resolve(items)
      else
        d.resolve()
    ).fail( (jqXHR) =>
      # Data not synced already
      if jqXHR.status == 404
        this.init(cb, ecb)
      else
        d.reject(jqXHR)
    )
    d.promise()

  # @return A jQuery promise
  _pull2: ->
    @client.get_settings_md5().done( (md5) =>
      if md5 != @lastMd5
        return @client.get_settings().done (items) =>
          return @mergeStrategy(items).done =>
            @lastMd5 = md5
            return items
      else
        return undefined
    ).fail( (jqXHR) =>
      # Data not synced already
      if jqXHR.status == 404
        return this.init()
      else
        return jqXHR
    )

  # @return A jQuery promise
  _push: ->
    d = jQuery.Deferred()
    this._raw_get null, (raw_items) =>
      settings = {}
      for raw_key, raw_value of raw_items
        settings[raw_key] = raw_value if raw_key.match(@_nameRegex)
      @__retryer (ecbr) =>
        @client.put_settings(settings).fail(ecbr).done (md5) =>
          @lastMd5 = md5
          d.resolve(md5)
      , _.bind(d.reject,d)
    , _.bind(d.reject,d)
    d.promise()

  # @return A jQuery promise
  _overwriteStrategy: (items) ->
    d = jQuery.Deferred()
    this._raw_set items, _.bind(d.resolve,d)
    d.promise()

  # Call fct with ecbr as arg and retry it on fail.
  # Wait 1 second before retry first time, double until 64 s then.
  #
  # @param [Function] fct A function invoked with ecbr, a retry on error callback.
  # @param [Function] ecb A callback invoked when retry all fail.
  __retryer: (fct, ecb, wait=1000) ->
    fct (err) ->
      if wait <= 64*1000
        console.warning(err)
        setTimeout => @__retryer(fct, ecb, wait*2)
      else
        console.error(err)
        ecb?(err)

  _initConnection: ->
    @__retryer (ecbr) =>
      @client.get_settings_md5().done( =>
        setInterval(@throttled_pull, @PULL_INTERVAL_DELAY)
      ).fail (jqXHR) =>
        # Data not synced already
        if jqXHR.status == 404
          this._init().fail(ecbr).done =>
            setInterval(@throttled_pull, @PULL_INTERVAL_DELAY)
        else if jqXHR.status == 400
          console.error("BadRequest during SyncedStore initialization:", jqXHR)
        else
          ecbr()

  # @param [Function] cb A callback invoked once init is done. cb()
  # @param [Function] ecb A callback invoked when init fail. Take $.ajax.fail args.
  # @return A jQuery promise
  _init: ->
    d = jQuery.Deferred()
    this._raw_get null, (raw_items) =>
      settings = {}
      for raw_key, raw_value of raw_items
        settings[raw_key] = raw_value if raw_key.match(@_nameRegex)
      @__retryer (ecbr) =>
        @client.post_settings(settings).fail(ecbr).done (md5) =>
          @lastMd5 = md5
          d.resolve(md5)
      , _.bind(d.reject,d)
    , _.bind(d.reject,d)
    d.promise()
