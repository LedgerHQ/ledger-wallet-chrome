# A store able to synchronize with a remote crypted store. This store has an extra method in order to order a push or pull
# operations
class @ledger.storage.SyncedStore extends ledger.storage.SecureStore

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt/decrypt the store
  # @param [Function] syncPushHandler A function used to perform push synchronization operations
  # @param [Function] syncPullHandler A function used to perform pull synchronization operations
  constructor: (name, key, @syncPushHandler, @syncPullHandler, @migrationHandler) ->
    super

  pullStore: () ->

  pushStore: () ->

  schedulePushStore: () ->
