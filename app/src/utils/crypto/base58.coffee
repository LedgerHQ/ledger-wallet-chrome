@ledger.crypto ?= {}

class @ledger.crypto.Base58

  @encode: (buffer) -> bs58.encode(buffer)

  @decode: (string) -> bs58.decode(string)
