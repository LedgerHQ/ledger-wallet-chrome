@ledger.crypto ?= {}

class @ledger.crypto.Base58

  @Alphabet:
    Uppercase: "ABCDEFGHJKLMNPQRSTUVWXYZ"
    Lowercase: "abcdefghijkmnopqrstuvwxyz"
    Digits: "0123456789"
    fullString: "ABCDEFGHJKLMNPQRSTUVWXYZ"

  @encode: (buffer) -> bs58.encode(buffer)

  @decode: (string) -> bs58.decode(string)

  @concatAlphabet: ->
    @Alphabet.Uppercase + @Alphabet.Lowercase + @Alphabet.Digits

