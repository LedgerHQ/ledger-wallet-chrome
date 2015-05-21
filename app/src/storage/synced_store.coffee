
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
  HASHES_CHAIN_MAX_SIZE: 20

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
    @_deferredPull = null
    @_deferredPush = null
    _.defer =>
      @_auxiliaryStore.get ['__last_sync_md5', '__sync_changes'], (item) =>
        @_lastMd5 = item.__last_sync_md5
        @_changes = item['__sync_changes'].concat(@_changes) if item['__sync_changes']?
        @_unlockMethods()
        @throttled_pull()

  pull: ->
    @throttled_pull()
    @_deferredPull?.promise or (@_deferredPull = ledger.defer()).promise

  push: ->
    @debounced_push()
    @_deferredPush?.promise or (@_deferredPush = ledger.defer()).promise

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->
    l "SET", _.clone(items)
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

  keys: (cb) ->
    super (keys) =>
      for key, keyChanges of _(@_changes).groupBy('key')
        if _(keyChanges).last().type is OperationTypes.REMOVE
          keys = _(keys).without(key)
        else if !_(keys).contains(key)
          keys.push key
      cb?(keys)

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
    # Get distant store md5
    # If local md5 and distant md5 are different
      # -> pull the data
      # -> merge data
    @_deferredPull ?= ledger.defer()
    p = @client.get_settings_md5().then (md5) =>
      return yes if @_lastMd5 is md5
      @client.get_settings().then (data) =>
        l 'Received', data
        data = @_decrypt(data)
        l 'Decrypted', data
        @_merge(data).then =>
          @emit 'pulled'
          @_setLastMd5(md5)
    .fail (e) =>
      if e.status is 404
        throw Errors.NoRemoteData
      throw Errors.NetworkError
    l 'Resolve', @_deferredPull
    @_deferredPull.resolve(p)
    @_deferredPull.promise.fin => @_deferredPull = null
    p

  _merge: (remoteData) ->
    # Consistency chain check
    # if common last consistency sha1 index > consistency chain max size * 3/4
    # Invalidate changes and overwrite local storage
    # else
    # Overwrite local storage and keep changes
    @_getAllData().then (localData) =>
      remoteHashes = (remoteData['__hashes'] or []).join(' ')
      localHashes = (localData['__hashes'] or []).join(' ').substr(0, 2 * 64 + 1)
      if remoteHashes.length is 0 or localHashes.length is 0
        # Remote data are not using the new format. Just update the current local storage
        @_setAllData(remoteData)
      else if (remoteHashes.indexOf(localHashes) >= (@HASHES_CHAIN_MAX_SIZE * 3 / 4) * (64 + 1)) or remoteHashes.indexOf(localHashes) is -1
        @_changes = []
        @_setAllData(remoteData)
      else if (localData['__hashes'] or []).join(' ').indexOf((remoteData['__hashes'] or []).join(' ').substr(0, 2 * 64 + 1)) != -1
        # We are up to date do nothing
        ledger.defer().resolve().promise
      else
        [nextCommitHash, nextCommitData] = @_computeCommit(localData, @_changes)
        if _(remoteData['__hashes']).contains(nextCommitData)
          # The hash next commit already exists drop the changes
          @_setAllData(remoteHasheso)
          @_changes = []
        else
          @_setAllData(remoteData)

  # @return A jQuery promise
  _push: ->
    # return if no changes
    # Pull data
    # If no changes
    # Abort
    # Else
    # Update consistency chain
    # Push
    return if @_changes.length is 0
    @_deferredPush ?= ledger.defer()
    hasRemoteData = yes
    unlockMutableOperations = _.noop
    pushedData = null
    p = @_pull().fail (e) =>
      throw Errors.NetworkError if e is Errors.NetworkError
      hasRemoteData = no
    .then =>
      throw Errors.NoChanges if @_changes.length is 0
      # Lock mutable operations during the push
      unlockMutableOperations = _.lock(this, ['set', 'remove', 'clear', '_pull', '_push'])
      # Create the data to send
      @_getAllData()
    .then (data) =>
      # Create commit hash
      [commitHash, pushedData] = @_computeCommit(data, @_changes)
      # Jsonify data
      @_encryptToJson(pushedData)
    .then (data) => if hasRemoteData then @client.put_settings(data) else @client.post_settings(data)
    .then (md5) =>
      @_setLastMd5(md5)
      # Merge changes into store
      @_setAllData(pushedData)
    .then () => @emit 'pushed', this
    .fail (e) =>
      @debounced_push() # Retry later
      throw e
    .fin ->
      do unlockMutableOperations
    @_deferredPush.resolve(p)
    @_deferredPush.promise.fin => @_deferredPush = null
    p

  _applyChanges: (data, changes) ->
    for change in changes
      if change.type is OperationTypes.SET
        data[change.key] = change.value
      else
        data = _.omit(change.key)
    data

  _computeCommit: (data, changes) ->
    data = @_applyChanges(data, changes)
    commitHash = ledger.crypto.SHA256.hashString _(data).toJson()
    data.__hashes = [commitHash].concat(data.__hashes or [])
    [commitHash, data]

  # @return A jQuery promise
  _overwriteStrategy: (items) ->
    d = Q.defer()
    this._raw_set items, _.bind(d.resolve,d)
    d.promise

  # Save lastMd5 in settings
  _setLastMd5: (md5) ->
    @_lastMd5 = md5
    @_auxiliaryStore.set(__last_sync_md5: md5)

  _getAllData: ->
    d = ledger.defer()
    @_super().keys (keys) =>
      l keys
      @_super().get keys, (data) =>
        d.resolve(data)
    d.promise

  _setAllData: (data) ->
    d = ledger.defer()
    @_super().clear =>
      @_super().set data, =>
        d.resolve()
    d.promise

  _saveChanges: (callback = undefined) -> @_auxiliaryStore.set __sync_changes: @_changes, callback
  _clearChanges: (callback = undefined ) ->
    @_changes = []
    @_saveChanges(callback)

  _encryptToJson: (data) ->
    data = _(data).chain().pairs().sort().object().value()
    '{' + (JSON.stringify(@_preprocessKey(key)) + ':' + JSON.stringify(@_preprocessValue(value)) for key, value of data).join(',') + '}'

  _decrypt: (data) ->
    out = {}
    out[@_deprocessKey(key)] = @_deprocessValue(value) for key, value of data
    out

  _super: ->
    return @_super_ if @_super_?
    @_super_ = {}
    for key, value of @constructor.__super__
      @_super_[key] = if _(value).isFunction() then value.bind(this) else value
    @_super_