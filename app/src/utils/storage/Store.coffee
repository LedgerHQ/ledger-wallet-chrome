@ledger.storage ?= {}

# Base class for every store. This class should not be used (abstract class).
# Descendant classes should namespace their keys before setting them, in order to allow multiple
# store to work on a unique chrome.storage instance
#
class @ledger.storage.Store extends EventEmitter

  # Gets one or more items from storage.
  #
  # @param [Array|String] key A single key to get or a list of keys to get.
  # @param [Function] cb Callback with storage items. Should look like (item) ->
  get: (keys, cb) ->

  # Stores one or many item
  #
  # @param [Object] items Items to store
  # @param [Function] cb A callback invoked once the insertion is done
  set: (items, cb) ->

  # Removes one or more items from storage.
  #
  # @param [Array|String] key A single key to get, list of keys to get.
  # @param [Function] cb A callback invoked once the removal is done.
  remove: (keys, cb) ->

  # Removes all items from storage.
  #
  # @param [Function] cb A callback invoked once the store is cleared.
  clear: (cb) ->


