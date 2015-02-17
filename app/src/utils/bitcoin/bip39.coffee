ledger.bitcoin ?= {}
ledger.bitcoin.bip39 ?= {}

_.extend ledger.bitcoin.bip39,

  ENTROPY_BIT_LENGTH: 256
  BIT_IN_BYTES: 8
  BYTES_IN_INTEGER: 4

  # @param [String] mnemonicWords Mnemonic words.
  # @return [Array] Mnemonic words in the phrase.
  isMnemonicPhraseValid: (mnemonicPhrase) ->
    try
      @utils.checkMnemonicPhraseValid(mnemonicPhrase) && true
    catch e
      false

  # @param [String] mnemonicWords Mnemonic words.
  # @return [Array] Mnemonic words in the phrase.
  mnemonicPhraseToSeed: (mnemonicPhrase, passphrase="") ->
    @utils.checkMnemonicPhraseValid(mnemonicPhrase)
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
    entropyIntegersArray = @_bytesArrayToIntegersArray(entropyBytesArray)
    @entropyToMnemonic(entropyBytesArray, entropyBitLength)

  entropyToMnemonic: (entropy, entropyBitLength = @ENTROPY_BIT_LENGTH) ->
    # convert it to integers array
    if typeof entropy == "string"
      entropyIntegersArray = entropy.match(/\w{8}/g).map (h) -> parseInt(h,16)
    else if entropy instanceof Uint8Array
      entropyIntegersArray = @_bytesArrayToIntegersArray(entropy)
    else
      entropyIntegersArray = entropy
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

  utils:
    BITS_IN_INTEGER: 8 * 4

    wordlist: ledger.bitcoin.bip39.wordlist

    # @param [string] entropy A hexadecimal string.
    # @return [string] Mnemonic phrase. Phrase may contains 12 to 24 words depending of entropy length.
    entropyToMnemonicPhrase: (entropy) ->
      throw "Invalid entropy format. Wait a hexadecimal string" if ! entropy.match(/^[0-9a-fA-F]+$/) 
      throw "Invalid entropy length: #{entropy.length*4}" if entropy.length % 8 != 0
      # Compute checksum
      entropyIntegersArray = entropy.match(/[0-9a-fA-F]{8}/g).map (h) -> parseInt(h,16)
      hashedEntropyIntegersArray = sjcl.hash.sha256.hash entropyIntegersArray
      hashedEntropy = hashedEntropyIntegersArray.map((i) => @_intToBin(i,32)).join('')
      # 1 checksum bit per 32 bits of entropy.
      binChecksum = hashedEntropy.slice(0,entropyIntegersArray.length)
      binEntropy = entropyIntegersArray.map((i) => @_intToBin(i,32)).join('')
      binMnemonic = binEntropy + binChecksum
      throw "Invalid binMnemonic length : #{binMnemonic.length}" if binMnemonic.length % 11 != 0
      mnemonicIndexes = binMnemonic.match(/[01]{11}/g).map (b) -> parseInt(b,2)
      mnemonicWords = mnemonicIndexes.map (idx) => @wordlist[idx]
      mnemonicWords.join(' ')

    checkMnemonicPhraseValid: (mnemonicPhrase) ->
      mnemonicWords = @mnemonicWordsFromPhrase(mnemonicPhrase)
      mnemonicIndexes = @mnemonicWordsToIndexes(mnemonicWords)
      if mnemonicIndexes.length % 3 != 0
        throw "Invalid mnemonic length : #{mnemonicIndexes.length}"
      if mnemonicIndexes.indexOf(-1) != -1
        word = mnemonicPhrase.trim().split(' ')[mnemonicIndexes.indexOf(-1)]
        throw "Invalid mnemonic word : #{word}"
      mnemonicBin = @mnemonicIndexesToBin(mnemonicIndexes)
      [binEntropy, binChecksum] = @splitMnemonicBin(mnemonicBin)
      if ! @checkEntropyChecksum(binEntropy, binChecksum)
        throw "Checksum error."
      return true

    # Do not check if mnemonic words are valids.
    # @param [String] mnemonicPhrase A mnemonic phrase.
    # @return [Array] Mnemonic words in the phrase.
    mnemonicWordsFromPhrase: (mnemonicPhrase) ->
      mnemonicPhrase.trim().split(/\ /)

    # @param [String] mnemonicWord
    # @return [Integer] Index of mnemonicWord in wordlist
    mnemonicWordToIndex: (mnemonicWord) ->
      @wordlist.indexOf(mnemonicWord)

    # @param [Array] mnemonicWords
    # @return [Array] Indexes of each mnemonicWord in wordlist
    mnemonicWordsToIndexes: (mnemonicWords) ->
      @mnemonicWordToIndex(mnemonicWord) for mnemonicWord in mnemonicWords

    # @return [Array] Return entropy bits and checksum bits.
    splitMnemonicBin: (mnemonicBin) ->
      # There is a checksum bit for each 33 bits (= 3 mnemonics word) slice.
      [mnemonicBin.slice(0, -(mnemonicBin.length/33)), mnemonicBin.slice(-(mnemonicBin.length/33))]

    checkEntropyChecksum: (entropyBin, checksumBin) ->
      integersEntropy = entropyBin.match(/[01]{32}/g).map (s) -> parseInt(s,2)
      hashedIntegersEntropy = sjcl.hash.sha256.hash integersEntropy
      hashedEntropyBinaryArray = hashedIntegersEntropy.map (s) => @_intToBin(s, @BITS_IN_INTEGER)
      computedChecksumBin = hashedEntropyBinaryArray.join('').slice(0, checksumBin.length)
      return computedChecksumBin == checksumBin

    mnemonicIndexToBin: (mnemonicIndex) ->
      @_intToBin(mnemonicIndex, 11)

    mnemonicIndexesToBin: (mnemonicIndexes) ->
      (@mnemonicIndexToBin(index) for index in mnemonicIndexes).join('')

    # Do not check if mnemonic phrase is valid.
    # @param [String] mnemonicPhrase A mnemonic phrase.
    # @return [Integer] The number of mnemonic word in the phrase.
    mnemonicPhraseLength: (mnemonicPhrase) ->
      @mnemonicWordsFromPhrase().length

    # @param [String] mnemonicWord A mnemonic word.
    # @return [Boolean] Return true if mnemonic word is in wordlist
    isMnemonicWordValid: (mnemonicWord) ->
      @mnemonicWordToIndex(mnemonicWord) != -1

    # Just check if each mnemonic word is valid.
    # Do not check checksum, length, etc.
    # @param [Array] mnemonicWords An array of mnemonic words.
    # @return [Boolean] Return true if each mnemonic word is in wordlist
    isMnemonicWordsValid: (mnemonicWords) ->
      _.every(mnemonicWords, (word) => @isMnemonicWordValid(word))

    _intToBin: (int, binLength) ->
      int += 1 if int < 0
      str = int.toString(2)
      str = str.replace("-","0").replace(/0/g,'a').replace(/1/g,'0').replace(/a/g,'1') if int < 0
      str = (if int < 0 then '1' else '0') + str while str.length < binLength
      str

for key, value of ledger.bitcoin.bip39 when _(value).isFunction()
  ledger.bitcoin.bip39[key] = ledger.bitcoin.bip39[key].bind ledger.bitcoin.bip39