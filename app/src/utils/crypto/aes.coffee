# Wrapper around Gibberish AES Library for encyrpt/decrypt data with AES
@class @ledger.crypto.AES

  constructor: (@key) ->

  # Encrypts the given string using AES-256
  # @param [String] data Data to encrypt
  encrypt: (data) ->  GibberishAES.enc(data, @key)

  # Decrypts the given encrypted data
  # @param [String] encryptedData An encrypted string
  decrypt: (encryptedData) -> GibberishAES.dec(encryptedData, @key)