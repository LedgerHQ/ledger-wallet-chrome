
OperationTypes =
  SET: 0
  REMOVE: 1

Errors =
  NoRemoteData: 0
  NetworkError: 1
  NoChanges: 2

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
  # @param [ledger.storage.Store] auxiliaryStore A store used to save ledger.storage.SyncedStored meta data
  constructor: (name, addr, key, auxiliaryStore = ledger.storage.wallet) ->
    super(name, key)
    @mergeStrategy = @_overwriteStrategy
    @client = ledger.api.SyncRestClient.instance(addr)
    @throttled_pull = _.throttle _.bind((-> @._pull()),@), @PULL_THROTTLE_DELAY
    @debounced_push = _.debounce _.bind((-> @._push()),@), @PUSH_DEBOUNCE_DELAY
    @_auxiliaryStore = auxiliaryStore
    @_changes = []
    @_unlockMethods = _.lock(this, ['set', 'get', 'remove', 'clear', '_pull', '_push'])
    _.defer =>
      @_auxiliaryStore.get ['__last_sync_md5', '__sync_changes'], (item) =>
        @lastMd5 = item.__last_sync_md5
        @_changes = item['__sync_changes'].concat(@_changes) if item['__sync_changes']?
        @_unlockMethods()
        @throttled_pull()

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->
    return cb?() unless items?
    @_changes.push {type: OperationTypes.SET, key: key, value: value} for key, value of items
    this.debounced_push()
    _.defer => cb?()

  get: (keys, cb) ->
    values = {}
    handledKeys = []
    for key in keys when (changes = _.where(@_changes, key: key)).length > 0
      values[key] = _(changes).last().value if _(changes).last().type is OperationTypes.SET
      handledKeys.push key
    keys = _(keys).without(handledKeys...)
    super keys, (storeValues) ->
      cb?(_.extend(storeValues, values))

  # Removes one or more items from storage.
  #
  # @param [Array|String] key A single key to get, list of keys to get.
  # @param [Function] cb A callback invoked once the removal is done.
  remove: (keys, cb) ->
    return cb?() unless keys?
    @_changes.push {type: OperationTypes.REMOVE, key: key} for key in keys
    this.debounced_push()
    _.defer => cb?()

  clear: (cb) ->
    super(cb)
    @_changes = {}
    @client.delete_settings()

  # @return A promise
  _pull: ->
    l 'pull'
    # Get distant store md5
    # If local md5 and distant md5 are different
      # -> pull the data
      # -> merge data
    @client.get_settings_md5().then (md5) ->
      l md5
    .fail (e) ->
      if e.status is 404
        throw Errors.NoRemoteData
      throw Errors.NetworkError


  _merge: (data) ->
    # Consistency chain check
      # if common last consistency sha1 index > consistency chain max size * 3/4
        # Invalidate changes and overwrite local storage
      # else
        # Overwrite local storage and keep changes

  # @return A jQuery promise
  _push: ->
    l 'push 0'
    return if @_changes.length is 0
    l 'push 1'
    hasRemoteData = yes
    unlockMutableOperations = _.noop
    pushedData = null
    @_pull().fail (e) =>
      l "Before", e
      throw Errors.NetworkError if e is Errors.NetworkError
      hasRemoteData = no
      l 'Continue'
    .then =>
      l 1, "args", arguments
      throw Errors.NoChanges if @_changes.length is 0
      # Lock mutable operations during the push
      unlockMutableOperations = _.lock(this, ['set', 'remove', 'clear', '_pull', '_push'])
      # Create the data to send
      @_getAllData()
    .then (data) =>
      l 2, arguments, hasRemoteData
      # Create commit hash
      data = @_applyChanges(data, @_changes)
      commitHash = ledger.crypto.SHA256.hashString _(data).toJson()
      data.__hashes = [commitHash].concat(data.__hashes or [])
      pushedData = data
      # Jsonify data
      _(data).toJson()
    .then (data) => if hasRemoteData then @client.put_settings(data) else @client.post_settings(data)
    .then () =>
      # Merge changes into store
      @_setAllData(pushedData)
    .fail () =>
      l arguments
      do unlockMutableOperations
      @debounced_push() # Retry later

    # return if no changes
    # Pull data
    # If no changes
      # Abort
    # Else
      # Update consistency chain
      # Push

  _applyChanges: (data, changes) ->
    for change in changes
      if change.type is OperationTypes.SET
        data[change.key] = change.value
      else
        data = _.omit(change.key)
    data

  # @return A jQuery promise
  _overwriteStrategy: (items) ->
    d = Q.defer()
    this._raw_set items, _.bind(d.resolve,d)
    d.promise

  # Save lastMd5 in settings
  _setLastMd5: (md5) ->
    @lastMd5 = md5
    @_auxiliaryStore.set(__last_sync_md5: md5)

  _getAllData: ->
    d = ledger.defer()
    @_super().keys (keys) =>
      l keys
      @_super().get keys, (data) =>
        l data
        d.resolve(data)
    d.promise

  _setAllData: (data) ->
    d = ledger.defer()
    @_super().clear =>
      @_super().set data, => d.resolve()
    d.promise

  _saveChanges: (callback = undefined) -> @_auxiliaryStore.set __sync_changes: @_changes, callback
  _clearChanges: (callback = undefined ) ->
    @_changes = []
    @_saveChanges(callback)

  _super: ->
    return @_super_ if @_super_?
    @_super_ = {}
    for key, value of @constructor.__super__
      @_super_[key] = if _(value).isFunction() then value.bind(this) else value
    @_super_