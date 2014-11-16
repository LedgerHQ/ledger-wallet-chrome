ledger.bitcoin ?= {}
ledger.bitcoin.bip39 ?= {}

_.extend ledger.bitcoin.bip39,

  ENTROPY_BIT_LENGTH: 256
  BIT_IN_BYTES: 8
  BYTES_IN_INTEGER: 4

  mnemonicIsValid: (mnemonic) ->
    numberOfWords = @numberOfWordsInMnemonic(mnemonic)
    return no if (numberOfWords % 3 != 0) or (numberOfWords != @mnemonicWordsNumber())
    return no if not @_allWordsInMnemonicAreValid(mnemonic)
    # convert wordlist to words indexes
    words = mnemonic.split(' ')
    wordsIndexes = @_mnemonicArrayToWordsIndexes words
    # generate binary array from words indexes
    binaryArray = @_integersArrayToBinaryArray wordsIndexes, 11
    # extract checksum
    entropyBitLength = @_nearest32Multiple binaryArray.length
    extractedBinaryChecksum = @_lastBitsOfBinaryArray binaryArray, entropyBitLength / 32
    extractedChecksum = @_binaryArrayToInteger extractedBinaryChecksum
    # compute checksum
    binaryEntropy = @_firstBitsOfBinaryArray binaryArray, entropyBitLength
    integersEntropy = @_binaryArrayToIntegersArray binaryEntropy
    hashedIntegersEntropy = sjcl.hash.sha256.hash integersEntropy
    hashedEntropyBinaryArray = @_integersArrayToBinaryArray hashedIntegersEntropy
    computedBinaryChecksum = @_firstBitsOfBinaryArray(hashedEntropyBinaryArray, entropyBitLength / 32)
    computedChecksum = @_binaryArrayToInteger computedBinaryChecksum
    # verify checksum
    return computedChecksum == extractedChecksum

  generateMnemonic: (entropyBitLength = @ENTROPY_BIT_LENGTH) ->
    # generate entropy bytes array
    entropyBytesArray = @_randomEntropyBytesArray(entropyBitLength / @BIT_IN_BYTES)
    # convert it to integers array
    entropyIntegersArray = @_bytesArrayToIntegersArray entropyBytesArray
    # apply sha256 to hash
    hashedEntropyIntegersArray = sjcl.hash.sha256.hash entropyIntegersArray
    # get first x bits of hash
    hashedEntropyBinaryArray = @_integersArrayToBinaryArray hashedEntropyIntegersArray
    checksum = @_firstBitsOfBinaryArray(hashedEntropyBinaryArray, entropyBitLength / 32)
    # compute entropy binary array
    entropyBinaryArray = @_integersArrayToBinaryArray entropyIntegersArray
    # append checksum to entropy
    finalEntropyBinaryArray = @_appendBitsToBinaryArray entropyBinaryArray, checksum
    # extract words indexes
    wordsIndexes = @_binaryArrayToIntegersArray finalEntropyBinaryArray, 11
    # generate wordlist
    wordlist = @_wordsIndexesToMnemonicArray wordsIndexes
    wordlist.join(' ')

  generateSeed: (mnemonic, passphrase = "") ->
    return undefined if !@mnemonicIsValid mnemonic
    hmacSHA512 = (key) ->
      hasher = new sjcl.misc.hmac(key, sjcl.hash.sha512)
      @encrypt = ->
        return hasher.encrypt.apply(hasher, arguments)
      @

    password = mnemonic.normalize('NFKD')
    salt = "mnemonic" + passphrase.normalize('NFKD')
    passwordBits = sjcl.codec.utf8String.toBits(password)
    saltBits = sjcl.codec.utf8String.toBits(salt)
    result = sjcl.misc.pbkdf2(passwordBits, saltBits, 2048, 512, hmacSHA512)
    hashHex = sjcl.codec.hex.fromBits(result)
    return hashHex

  numberOfWordsInMnemonic: (mnemonic) ->
    return 0 if not mnemonic? or mnemonic.length == 0
    count = 0
    words = mnemonic.split ' '
    for word in words
      count++ if word? and word.length > 0
    count

  mnemonicWordsNumber: ->
    return (@ENTROPY_BIT_LENGTH + @ENTROPY_BIT_LENGTH / 32) / 11

  _allWordsInMnemonicAreValid: (mnemonic) ->
    return 0 if not mnemonic? or mnemonic.length == 0
    words = mnemonic.split ' '
    for word in words
      return no if ledger.bitcoin.bip39.wordlist.indexOf(word) == -1
    return yes

  _integersArrayToBinaryArray: (integersArray, integerBitLength = @BYTES_IN_INTEGER * @BIT_IN_BYTES) ->
    binaryArray = []
    for integer in integersArray
      partialBinaryArray = @_integerToBinaryArray integer, integerBitLength
      @_appendBitsToBinaryArray binaryArray, partialBinaryArray
    binaryArray

  _integerToBinaryArray: (integer, integerBitLength = @BYTES_IN_INTEGER * @BIT_IN_BYTES) ->
    binaryArray = []
    for power in [integerBitLength - 1 .. 0]
      val = Math.abs ((integer & (1 << power)) >> power)
      binaryArray.push val
    binaryArray

  _binaryArrayToInteger: (binaryArray) ->
    return 0 if binaryArray.length == 0
    integer = 0
    multiplier = 1
    for i in [binaryArray.length - 1 .. 0]
      if binaryArray[i] == 1
        integer += multiplier
      multiplier *= 2
    integer

  _binaryArrayToIntegersArray: (binaryArray, integerBitLength = @BYTES_IN_INTEGER * @BIT_IN_BYTES) ->
    integersArray = []
    workingArray = binaryArray.slice()
    while workingArray.length > 0
      integersArray.push @_binaryArrayToInteger(@_firstBitsOfBinaryArray(workingArray, integerBitLength))
      workingArray.splice 0, integerBitLength
    integersArray

  _bytesArrayToIntegersArray: (bytesArray) ->
    i = 0
    integerArray = []
    while i < bytesArray.length
      integer = (bytesArray[i] << (@BIT_IN_BYTES * 3)) + (bytesArray[i + 1] << (@BIT_IN_BYTES * 2)) + (bytesArray[i + 2] << (@BIT_IN_BYTES * 1)) + bytesArray[i + 3]
      integerArray.push integer
      i += @BYTES_IN_INTEGER
    integerArray

  _firstBitsOfBinaryArray: (binaryArray, numberOfFirstBits) ->
    binaryArray.slice 0, numberOfFirstBits

  _lastBitsOfBinaryArray: (binaryArray, numberOfLastBits) ->
    binaryArray.slice -numberOfLastBits

  _appendBitsToBinaryArray: (binaryArray, bitsToAppend) ->
    for bit in bitsToAppend
      binaryArray.push bit
    binaryArray

  _wordsIndexesToMnemonicArray: (indexes) ->
    mnemonicArray = []
    for index in indexes
      mnemonicArray.push ledger.bitcoin.bip39.wordlist[index]
    mnemonicArray

  _mnemonicArrayToWordsIndexes: (mnemonicArray) ->
    indexes = []
    for word in mnemonicArray
      indexes.push ledger.bitcoin.bip39.wordlist.indexOf word
    indexes

  _nearest32Multiple: (length) ->
    power = 0
    while (power + 32) <= length
      power += 32
    power

  _randomEntropyBytesArray: (bytesLength) ->
    entropy = new Uint8Array(bytesLength)
    crypto.getRandomValues entropy
    entropy

for key, value of ledger.bitcoin.bip39 when _(value).isFunction()
  ledger.bitcoin.bip39[key] = ledger.bitcoin.bip39[key].bind ledger.bitcoin.bip39