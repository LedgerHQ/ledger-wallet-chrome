# Secure version of the ledger.storage.ChromeStore. This store uses AES encryption for storing keys and data
class @ledger.storage.SecureStore extends ledger.storage.ChromeStore

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt and decrypt data with AES
  constructor: (name, key) ->
    super(name)
    @_aes = new ledger.crypto.AES(key)
    @_hasCalledKeys = no

  # @see Store.keys
  keys: (cb) ->
    super (encrypted_keys) =>
      cb?(_.compact(@__decryptKey(encrypted_key) for encrypted_key in encrypted_keys))

  _preprocessKey: (key) ->
    super(@_aes.encrypt(key))

  _deprocessKey: (raw_key) ->
    key = @__decryptKey(super raw_key)
    key

  _preprocessValue: (value) -> Try(=> @_aes.encrypt(super(value))).orNull()
  _deprocessValue: (raw_value) -> Try(=> super(@_aes.decrypt(raw_value))).orNull()

  __decryptKey: (value) -> (@_decryptCache ||= {})[value] ||= (Try(=> @_aes.decrypt(value)).orNull())