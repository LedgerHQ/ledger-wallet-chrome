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
  _translateKeyToStoreKey: (key) ->
    "#{@_name}_#{key}"

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
  getItem: (key, cb) ->
    keys = []
    keys.push @_getStoreKey(k) for k in key if _.isArray(key)
    keys.push @_getStoreKey(key) if _.isString(key)
    chrome.storage.local.getItem keys, (items) =>
      decryptedItems = []
      decryptedItems.push @_decryptData(data) for data in items
      cp(decryptedItems) if decryptedItems?

  # @see ledger.storage.Store#setItem
  setItem: (key, value, cb) -> chrome.storage.local.setItem @_translateKeyToStoreKey(key), @_encryptData(value), cb
