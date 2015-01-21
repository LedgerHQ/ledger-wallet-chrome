# A store able to synchronize with a remote crypted store. This store has an extra method in order to order a push or pull
# operations
class ledger.storage.SyncedStore extends ledger.storage.SecureStore

  PULL_INTERVAL_DELAY: 1000
  PULL_THROTTLE_DELAY: 1000
  PUSH_DEBOUNCE_DELAY: 1000

  # Pull statuses
  UPTODATE:  "uptodate"
  REFRESHED: "refreshed"

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt/decrypt the store
  # @param [Function] syncPushHandler A function used to perform push synchronization operations
  # @param [Function] syncPullHandler A function used to perform pull synchronization operations
  constructor: (name, key) ->
    super(name, key)
    @mergeStrategy = this._overwriteStrategy
    @client = ledger.api.SyncRestClient.singleton()
    @throttled_pull = _.throttle (=> this._pull()), @PULL_THROTTLE_DELAY
    @debounced_push = _.debounce (=> this._push()), @PUSH_DEBOUNCE_DELAY
    _.defer => setInterval(@throttled_pull, @PULL_INTERVAL_DELAY)

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

  # @param [Function] cb A callback invoked once pull is done. cb(status, meta)
  # @param [Function] ecb A callback invoked when pull fail. cb(error)
  # Status may be
  # - UPTODATE  : nothing to do.
  # - REFRESHED : new meta retrieved.
  _pull: (cb, ecb) ->
    @client.get_md5( (md5) =>
      if md5 != @lastMd5
        @client.get_meta( (items) =>
          @mergeStrategy items, =>
            @lastPull_ts = Date.now()
            @lastMd5 = md5
            cb?(@REFRESHED, items)
        , ecb
        )
      else
        cb?(@UPTODATE)
    , ecb)

  # @param [Function] cb A callback invoked once push is done. cb()
  # @param [Function] ecb A callback invoked when push fail. cb(error)
  _push: (cb, ecb) ->
    this._raw_get null, (raw_items) =>
      meta = {}
      for raw_key, raw_value of raw_items
        meta[raw_key] = raw_value if raw_key.match(@_nameRegex)
      __retryer (ecbr) =>
        @client.put_meta(meta, (md5) =>
          @lastMd5 = md5
          cb?()
        , ecbr)
      , ecb

  _overwriteStrategy: (items, cb) ->
    this._raw_set(items, cb)

  # Call fct with ecbr as arg and retry it on fail.
  # Wait 1 second before retry first time, double until 64 s then.
  #
  # @param [Function] fct A function invoked with ecbr, a retry on error callback.
  # @param [Function] ecb A callback invoked when retry all fail. cb(error:String)
  __retryer: (fct, ecb, wait=1000) ->
    fct (err) ->
      if wait <= 64*1000
        console.warning(err)
        setTimeout => @__retryer(fct, ecb, wait*2)
      else
        console.error(err)
        ecb?(err)
