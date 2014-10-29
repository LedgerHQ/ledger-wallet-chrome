@ledger.storage ?= {}

# Base class for every store. This class should not be used (abstract class).
# Descendant classes should namespace their keys before setting them, in order to allow multiple
# store to work on a unique chrome.storage instance
#
class @ledger.storage.Store

  # Gets one or more items from storage.
  #
  # @param [String] key A single key to get, list of keys to get.
  # @param [Function] cb Callback with storage items. Should look like (item) ->
  getItem: (key, cb) ->

  # Sets a value
  #
  # @param [String] key The key to set
  # @param [Object] value The value to set
  # @param [Function] cb A callback invoked once the insertion is done
  setItem: (key, value, cb) ->

  # Removes one or more items from storage.
  #
  # @param [String] key A single key to get, list of keys to get.
  # @param [Function] cb A callback invoked once the removal is done.
  removeItem: (key, cb) ->
