# Secure version of the ledger.storage.ChromeStore. This store uses AES encryption for storing keys and data
class @ledger.storage.SecureStore extends ledger.storage.ChromeStore

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt and decrypt data with AES
  constructor: (name, key) ->
    super
    @_aes = new ledger.crypto.AES(key)

  _encryptKey: (key) -> super @_aes.encrypt(key)

  _decryptKey: (key) -> @_aes.decrypt(super(key))

  _encryptData: (data) -> @_aes.encrypt super(data)

  _decryptData: (data) -> @_aes.decrypt super(data)
