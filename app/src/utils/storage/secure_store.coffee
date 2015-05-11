# Secure version of the ledger.storage.ChromeStore. This store uses AES encryption for storing keys and data
class @ledger.storage.SecureStore extends ledger.storage.ChromeStore

  # @param [String] name The store name
  # @param [String] key The secure key used to encrypt and decrypt data with AES
  constructor: (name, key) ->
    super(name)
    @_aes = new ledger.crypto.AES(key)

  # @see Store.keys
  keys: (cb) ->
    super (encrypted_keys) =>
      cb(_.compact(Try(=> @_aes.decrypt(encrypted_key)).orNull() for encrypted_key in encrypted_keys))

  _preprocessKey: (key) -> super(@_aes.encrypt(key))
  _deprocessKey: (raw_key) -> Try(=> @_aes.decrypt(super(raw_key))).orNull()
  _preprocessValue: (value) -> Try(=> @_aes.encrypt(super(value))).orNull()
  _deprocessValue: (raw_value) -> Try(=> super(@_aes.decrypt(raw_value))).orNull()
