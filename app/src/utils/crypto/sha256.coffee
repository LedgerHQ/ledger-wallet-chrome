@ledger.crypto ?= {}

# Wrapper class around Stanford AES Library for hashing data with SHA-256
class @ledger.crypto.SHA256

  @hashString: (string) -> sjcl.codec.hex.fromBits(sjcl.hash.sha256.hash(string))