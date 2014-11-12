ledger.bitcoin ?= {}
ledger.bitcoin.bip39 ?= {}

_.extend ledger.bitcoin.bip39,

  ENTROPY_BIT_LENGTH: 256
  MNEMONIC_WORDS_NUMBER: 24
  BIT_IN_BYTES: 8
  BYTES_IN_INTEGER: 4

  numberOfWordsInMnemonic: (mnemonic) ->
    return 0 if not mnemonic? or mnemonic.length == 0
    count = 0
    words = mnemonic.split ' '
    for word in words
      count++ if word? and word.length > 0
    count

  mnemonicIsValid: (mnemonic) ->
    return no

  generateMnemonic: ->
    # generate entropy bytes array
    entropyBytesArray = @_randomEntropyBytesArray(@ENTROPY_BIT_LENGTH / @BIT_IN_BYTES)
    # convert it to integers array
    entropyIntegersArray = @_bytesArrayToIntegersArray entropyBytesArray
    # apply sha256 to hash
    hashedEntropyIntegersArray = sjcl.hash.sha256.hash entropyIntegersArray
    # get first x bits of hash
    hashedEntropyBinaryArray = @_integersArrayToBinaryArray hashedEntropyIntegersArray
    checksum = @_firstBitsOfBinaryArray(hashedEntropyBinaryArray, @ENTROPY_BIT_LENGTH / 32)
    # compute entropy binary array
    entropyBinaryArray = @_integersArrayToBinaryArray entropyIntegersArray
    # append checksum to entropy
    finalEntropyBinaryArray = @_appendBitsToBinaryArray entropyBinaryArray, checksum
    # extract words indexes
    wordsIndexes = @_binaryArrayToIntegers finalEntropyBinaryArray, 11
    # generate wordlist
    wordlist = @_wordsIndexesToMnemonicArray wordsIndexes
    wordlist.join(' ')

  _integersArrayToBinaryArray: (integersArray) ->
    binaryArray = []
    for integer in integersArray
      partialBinaryArray = @_integerToBinaryArray integer
      @_appendBitsToBinaryArray binaryArray, partialBinaryArray
    binaryArray

  _integerToBinaryArray: (integer, integerLength = 32) ->
    binaryArray = []
    for power in [integerLength - 1 .. 0]
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

  _binaryArrayToIntegers: (binaryArray, integerBitLength) ->
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
      integer = (bytesArray[i] << 24) + (bytesArray[i + 1] << 16) + (bytesArray[i + 2] << 8) + bytesArray[i + 3]
      integerArray.push integer
      i += @BYTES_IN_INTEGER
    integerArray

  _firstBitsOfBinaryArray: (binaryArray, numberOfFirstBits) ->
    binaryArray.slice binaryArray, numberOfFirstBits

  _appendBitsToBinaryArray: (binaryArray, bitsToAppend) ->
    for bit in bitsToAppend
      binaryArray.push bit
    binaryArray

  _wordsIndexesToMnemonicArray: (indexes) ->
    mnemonicArray = []
    for index in indexes
      mnemonicArray.push ledger.bitcoin.bip39.wordlist[index]
    mnemonicArray

  _randomEntropyBytesArray: (bytesLength) ->
    entropy = new Uint8Array(bytesLength)
    crypto.getRandomValues entropy
    entropy

for key, value of ledger.bitcoin.bip39 when _(value).isFunction()
  ledger.bitcoin.bip39[key] = ledger.bitcoin.bip39[key].bind ledger.bitcoin.bip39