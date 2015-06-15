
OperationTypes =
  SET: 0
  REMOVE: 1

Errors =
  NoRemoteData: 0
  NetworkError: 1
  NoChanges: 2

$logger = -> ledger.utils.Logger.getLoggerByTag('SyncedStore')
$info = (args...) -> $logger().info(args...)

# A store able to synchronize with a remote crypted store. This store has an extra method in order to order a push or pull
# operations
# @event pulled Emitted once the store is pulled from the remote API
class ledger.storage.SyncedStore extends ledger.storage.Store

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
    super(name)
    @_secureStore = new ledger.storage.SecureStore(name, key)
    @client = ledger.api.SyncRestClient.instance(addr)
    @_throttled_pull = ledger.utils.promise.throttle _.bind((-> @._pull()),@), @PULL_THROTTLE_DELAY, immediate: yes
    @_debounced_push = ledger.utils.promise.debounce _.bind((-> @._push()),@), @PUSH_DEBOUNCE_DELAY
    @_auxiliaryStore = auxiliaryStore
    @_changes = []
    @_unlockMethods = _.lock(this, ['set', 'get', 'remove', 'clear', 'pull', 'push'])
    @_deferredPull = null
    @_deferredPush = null
    _.defer =>
      @_auxiliaryStore.get ['__last_sync_md5', '__sync_changes'], (item) =>
        @_lastMd5 = item.__last_sync_md5
        @_changes = item['__sync_changes'].concat(@_changes) if item['__sync_changes']?
        $info 'Initialize store: ', md5: @_lastMd5, changes: @_changes, init: item
        @_unlockMethods()
        @pull()
        @push() if @_changes.length > 0

  pull: ->
    l 'Request pull', new Error().stack
    @_throttled_pull()

  push: ->
    l 'Request push', new Error().stack
    @_debounced_push()

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->
    return cb?() unless items?
    @_changes.push {type: OperationTypes.SET, key: key, value: value} for key, value of items
    @_debounced_push()
    @_saveChanges -> cb?()

  get: (keys, cb) ->
    keys = [keys] unless _(keys).isArray()
    values = {}
    handledKeys = []
    for key in keys when (changes = _.where(@_changes, key: key)).length > 0
      values[key] = _(changes).last().value if _(changes).last().type is OperationTypes.SET
      handledKeys.push key
    keys = _(keys).without(handledKeys...)
    @_secureStore.get keys, (storeValues) ->
      cb?(_.extend(storeValues, values))

  keys: (cb) ->
    @_secureStore.keys (keys) =>
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
    @_debounced_push()
    _.defer => cb?()

  clear: (cb) ->
    @_secureStore.clear cb
    @_clearChanges()
    @client.delete_settings()

  # @return A promise
  _pull: ->
    # Get distant store md5
    # If local md5 and distant md5 are different
      # -> pull the data
      # -> merge data
    @client.get_settings_md5().then (md5) =>
      $info 'Remote md5: ', md5, ', local md5', md5
      return yes if @_lastMd5 is md5
      @client.get_settings().then (data) =>
        l "Decrypt", _.clone(data)
        $info 'PULL, before decrypt ', data
        data = Try(=> @_decrypt(data))
        $info 'PULL, after decrypt ', data.getOrElse("Unable to decrypt data")
        return if data.isFailure()
        data = data.getValue()
        $info 'Changes before merge', @_changes
        @_merge(data).then =>
          @_setLastMd5(md5)
          @emit 'pulled'
    .fail (e) =>
      if e.status is 404
        throw Errors.NoRemoteData
      l "Pull failed", e
      throw Errors.NetworkError

  _merge: (remoteData) ->
    # Consistency chain check
    # if common last consistency sha1 index > consistency chain max size * 3/4
    # Invalidate changes and overwrite local storage
    # else
    # Overwrite local storage and keep changes
    @_getAllData().then (localData) =>
      $info 'Data before merge ', localData # TODO: Remove in production
      remoteHashes = (remoteData['__hashes'] or []).join(' ')
      localHashes = (localData['__hashes'] or []).join(' ').substr(0, 2 * 64 + 1)
      if remoteHashes.length is 0 or localHashes.length is 0
        # Remote data are not using the new format. Just update the current local storage
        $info 'Merge scenario 1', remoteHashes, localHashes
        @_setAllData(remoteData)
      else if (remoteHashes.indexOf(localHashes) >= (@HASHES_CHAIN_MAX_SIZE * 3 / 4) * (64 + 1)) or remoteHashes.indexOf(localHashes) is -1
        $info 'Merge scenario 2', remoteHashes, localHashes
        @_clearChanges()
        @_setAllData(remoteData)
      else if (localData['__hashes'] or []).join(' ').indexOf((remoteData['__hashes'] or []).join(' ').substr(0, 2 * 64 + 1)) != -1
        $info 'Merge scenario 3', remoteHashes, localHashes
        # We are up to date do nothing
        @_setAllData(remoteData)
      else
        [nextCommitHash, nextCommitData] = @_computeCommit(localData, @_changes)
        if _(remoteData['__hashes']).contains(nextCommitData)
          $info 'Merge scenario 4', remoteHashes, localHashes, nextCommitHash
          # The hash next commit already exists drop the changes
          @_setAllData(remoteData)
          @_clearChanges()
        else
          $info 'Merge scenario 5', remoteHashes, localHashes
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
    return ledger.defer().reject(Errors.NoChanges).promise if @_changes.length is 0

    hasRemoteData = yes
    unlockMutableOperations = _.noop
    pushedData = null
    @_getAllData()
    .then (data) =>
      throw Errors.NoChanges unless @_areChangesMeaningful(data, @_changes)
    .then () =>
      @pull()
    .fail (e) =>
      throw Errors.NoChanges if e is Errors.NoChanges
      throw Errors.NetworkError if e is Errors.NetworkError
      hasRemoteData = no
    .then =>
      throw Errors.NoChanges if @_changes.length is 0
      # Lock mutable operations during the push
      unlockMutableOperations = _.lock(this, ['set', 'remove', 'clear', 'pull', 'push'])
      # Create the data to send
      @_getAllData()
    .then (data) =>
      # Check if the changes are useful or not by hashing the changes without the last commit
      $info 'Changes to apply', @_changes
      throw Errors.NoChanges unless @_areChangesMeaningful(data, @_changes)
      # Create commit hash
      [commitHash, pushedData] = @_computeCommit(data, @_changes)
      $info 'Push ', commitHash, ' -> ', pushedData, ' Local data ', data, ' Changes ', @_changes
      # Jsonify data
      @_encryptToJson(pushedData)
    .then (data) => if hasRemoteData then @client.put_settings(data) else @client.post_settings(data)
    .then (md5) =>
      @_setLastMd5(md5)
      # Merge changes into store
      $info 'Clear changes and sets', pushedData
      @_clearChanges()
      @_setAllData(pushedData)
    .then () => @emit 'pushed', this
    .then () => do unlockMutableOperations
    .fail (e) =>
      $info 'Push failed due to ', e
      _.defer => do unlockMutableOperations
      if e is Errors.NoChanges
        @_clearChanges()
        return
      $info "Failed push ", e
      @push() # Retry later
      throw e

  _applyChanges: (data, changes) ->
    for change in changes
      if change.type is OperationTypes.SET
        data[change.key] = change.value
      else
        data = _.omit(data, change.key)
    data

  _computeCommit: (data, changes) ->
    data = @_applyChanges(data, changes)
    commitHash = ledger.crypto.SHA256.hashString _(data).toJson()
    data.__hashes = [commitHash].concat(data.__hashes or []).slice(0, @HASHES_CHAIN_MAX_SIZE)
    [commitHash, data]

  _areChangesMeaningful: (data, changes) ->
    if data['__hashes']?.length > 0
      checkData = _.clone(data)
      checkData['__hashes'] = _(checkData['__hashes']).without(checkData['__hashes'][0])
      checkData = _(checkData).omit('__hashes') if checkData['__hashes'].length is 0
      [lastCommitHash, __] = @_computeCommit(checkData, changes)
      return lastCommitHash isnt data['__hashes'][0]
    yes

  # Save lastMd5 in settings
  _setLastMd5: (md5) ->
    @_lastMd5 = md5
    @_auxiliaryStore.set(__last_sync_md5: md5)

  _getAllData: ->
    d = ledger.defer()
    @_secureStore.keys (keys) =>
      @_secureStore.get keys, (data) =>
        d.resolve(data)
    d.promise

  _setAllData: (data) ->
    d = ledger.defer()
    @_secureStore.clear =>
      @_secureStore.set data, =>
        d.resolve()
    d.promise

  _saveChanges: (callback = undefined) -> @_auxiliaryStore.set __sync_changes: @_changes, callback
  _clearChanges: (callback = undefined ) ->
    @_changes = []
    @_saveChanges(callback)

  _encryptToJson: (data) ->
    data = _(data).chain().pairs().sort().object().value()
    '{' + (JSON.stringify(@_secureStore._preprocessKey(key)) + ':' + JSON.stringify(@_secureStore._preprocessValue(value)) for key, value of data).join(',') + '}'

  _decrypt: (data) ->
    out = {}
    out[@_secureStore._deprocessKey(key)] = @_secureStore._deprocessValue(value) for key, value of data
    out