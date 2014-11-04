# A store able to keep persistently data with the chrome storage API
class @ledger.storage.ChromeStore extends ledger.storage.Store

  # @param [String] name The store name (for key mangling)
  constructor: (name) ->
    @_name = name

  # Translate a given key to a store key. This method is private and is only used internally.
  # It may be override by child store class if they need custom key mangling
  # @param [String] key The key you need to translate
  # @return [String] The translated key
  # @private
  _encryptKey: (key) ->
    "#{@_name}_#{key}"

  # Decrypt a given key store to a readable key. This method is private and is only used internally.
  # It may be override by child store class if they need custom key mangling
  # @param [String] value The key you need to decrypt
  # @return [String] The decrypted key
  # @private
  _decryptKey: (key) ->
    key.substr(key.indexOf('_') + 1)

  # Encrypt a given value to a store value. This method is private and is only used internally.
  # It may be override by child store class if they need custom value encryption
  # @param [String] value The readable value you need to encrypt
  # @return [String] The encrypted value
  # @private
  _encryptData: (value) -> value

  # Decrypt a given store value to a readable value. This method is private and is only used internally.
  # It may be override by child store class if they need custom value encryption
  # @param [String] value The value you need to decrypt
  # @return [String] The decrypted value
  # @private
  _decryptData: (value) -> value

  # @see ledger.storage.Store#getItem
  get: (key, cb) ->
    keys = []
    keys.push @_encryptKey(k) for k in key  if _.isArray(key)
    keys.push @_encryptKey(key) if _.isString(key)
    chrome.storage.local.get keys, (items) =>
      decryptedItems = {}
      decryptedItems[@_decryptKey(key)] = @_decryptData(data) for key, data of items
      cb(decryptedItems) if cb?

  # @see ledger.storage.Store#setItem
  set: (item, cb = ->) ->
    obj = {}
    for key, value of item
      obj[@_encryptKey(key)] = @_encryptData(JSON.stringify(value))
    chrome.storage.local.set obj, cb

  remove: (keys, cb) ->
    keys = []
    keys.push @_encryptKey(k) for k in key  if _.isArray(key)
    keys.push @_encryptKey(key) if _.isString(key)
    chrome.storage.local.remove keys, (items) =>
      decryptedItems = {}
      decryptedItems[@_decryptKey(key)] = @_decryptData(data) for key, data of items
      cb(decryptedItems) if cb?

  clear: (keys, cb) ->
    keys = []
    chrome.storage.local.get null, (result) ->
      for k, v in result
        keys.push k if _.str.startsWith(k, @_name)
      chrome.storage.local.remove keys, callback