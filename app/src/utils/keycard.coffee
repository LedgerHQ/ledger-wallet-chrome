ledger.keycard ?= {}

class @ledger.keycard

  @generateKeycardFromSeed: (seed) ->
    throw "Invalid card seed" if seed.length != 32
    key = new JSUCrypt.key.DESKey(seed)
    cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC)
    cipher.init(key, JSUCrypt.cipher.MODE_ENCRYPT)
    data = (Convert.toHexByte(i) for i in [0..0x50]).join('')
    keycard = for i in cipher.update(data)
      [a, b] = (parseInt(n,16) for n in Convert.toHexByte(i).split(''))
      a ^ b
    alphabet1 = new ByteString("ABCDEFGHJKLMNPQRSTUVWXYZ", ASCII)
    alphabet2 = new ByteString("abcdefghijkmnopqrstuvwxyz", ASCII)
    alphabet3 = new ByteString("0123456789", ASCII)
    alphabetContent = [alphabet1, alphabet2, alphabet3]
    result = {}
    for alphabet in alphabetContent
      for i in [0..alphabet.length - 1]
        result[alphabet.bytes(i, 1).toString(ASCII)] = Convert.toHexByte(keycard[alphabet.byteAt(i) - 0x30])[1]
    result