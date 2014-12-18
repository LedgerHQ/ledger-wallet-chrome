# A store able to synchronize with a remote crypted store. This store has an extra method in order to order a push or pull
# operations
class @ledger.storage.SyncedStore extends ledger.storage.SecureStore

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt/decrypt the store
  # @param [Function] syncPushHandler A function used to perform push synchronization operations
  # @param [Function] syncPullHandler A function used to perform pull synchronization operations
  constructor: (name, key) ->
    super name
    @get '__keys', (result) =>
      @_keys = result['__keys']
      @_keys ?= []

    do @pullStore()

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->
    super items, cb
    @perform =>
      hasChanges = no
      for key, value of items
        unless _.contains(@_keys, key)
         hasChanges = yes
         @_keys.push key
      super {'__keys': @_keys}, _.noop if hasChanges
      do @schedulePushStore

  # Removes one or more items from storage.
  #
  # @param [Array|String] key A single key to get, list of keys to get.
  # @param [Function] cb A callback invoked once the removal is done.
  remove: (keys, cb) ->
    super keys, cb
    do @schedulePushStore

  pullStore: () ->


  pushStore: () ->


  schedulePushStore: () ->
    clearTimeout @_scheduledPush if @_scheduledPush?
    @_scheduledPush = setTimeout (=> @pushStore()), 1000

  perform: (callback) ->
    if @_keys?
      do callback
    else
      @once 'synced:initialized', ->
        _.defer callback

