ledger.bitcoin ?= {}
ledger.bitcoin.bip39 ?= {}
Bip39 = ledger.bitcoin.bip39

_.extend ledger.bitcoin.bip39,

  ENTROPY_BIT_LENGTH: 256
  DEFAULT_PHRASE_LENGTH: 24

  # @param [String] mnemonicWords Mnemonic words.
  # @return [Array] Mnemonic words in the phrase.
  isMnemonicPhraseValid: (mnemonicPhrase) ->
    try
      @utils.checkMnemonicPhraseValid(mnemonicPhrase) && true
    catch e
      false

  # @return [String]
  generateEntropy: (entropyBitLength = @ENTROPY_BIT_LENGTH) ->
    entropyBytesArray = new Uint8Array(entropyBitLength / 8)
    crypto.getRandomValues(entropyBytesArray)
    @utils._bytesArrayToHexString(entropyBytesArray)

  # @param [string] entropy A hexadecimal string.
  # @return [string] Mnemonic phrase. Phrase may contains 12 to 24 words depending of entropy length.
  entropyToMnemonicPhrase: (entropy) ->
    throw "Invalid entropy format. Wait a hexadecimal string" if ! entropy.match(/^[0-9a-fA-F]+$/) 
    throw "Invalid entropy length: #{entropy.length*4}" if entropy.length % 8 != 0
    # Compute checksum
    entropyIntegersArray = entropy.match(/[0-9a-fA-F]{8}/g).map (h) -> parseInt(h,16)
    hashedEntropyIntegersArray = sjcl.hash.sha256.hash entropyIntegersArray
    hashedEntropy = hashedEntropyIntegersArray.map((i) => @utils._intToBin(i,32)).join('')
    # 1 checksum bit per 32 bits of entropy.
    binChecksum = hashedEntropy.slice(0,entropyIntegersArray.length)
    binEntropy = entropyIntegersArray.map((i) => @utils._intToBin(i,32)).join('')
    binMnemonic = binEntropy + binChecksum
    throw "Invalid binMnemonic length : #{binMnemonic.length}" if binMnemonic.length % 11 != 0
    mnemonicIndexes = binMnemonic.match(/[01]{11}/g).map (b) -> parseInt(b,2)
    mnemonicWords = mnemonicIndexes.map (idx) => @wordlist[idx]
    mnemonicWords.join(' ')

  # @return [String]
  generateMnemonicPhrase: (phraseLength=@DEFAULT_PHRASE_LENGTH) ->
    entropyBitLength = phraseLength * 32 / 3
    @entropyToMnemonicPhrase(@generateEntropy(entropyBitLength))

  # @param [String] mnemonicWords Mnemonic words.
  # @return [Array] Mnemonic words in the phrase.
  mnemonicPhraseToSeed: (mnemonicPhrase, passphrase="") ->
    @utils.checkMnemonicPhraseValid(mnemonicPhrase)
    hmacSHA512 = (key) ->
      hasher = new sjcl.misc.hmac(key, sjcl.hash.sha512)
      @encrypt = ->
        return hasher.encrypt.apply(hasher, arguments)
      @
    password = mnemonicPhrase.normalize('NFKD')
    salt = "mnemonic" + passphrase.normalize('NFKD')
    passwordBits = sjcl.codec.utf8String.toBits(password)
    saltBits = sjcl.codec.utf8String.toBits(salt)
    result = sjcl.misc.pbkdf2(passwordBits, saltBits, 2048, 512, hmacSHA512)
    hashHex = sjcl.codec.hex.fromBits(result)
    return hashHex

  utils:
    BITS_IN_INTEGER: 8 * 4

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
      Bip39.wordlist.indexOf(mnemonicWord)

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
    mnemonicPhraseWordsLength: (mnemonicPhrase) ->
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

    _bytesArrayToHexString: (bytesArray) ->
      (_.str.lpad(byte.toString(16), 2, '0') for byte in bytesArray).join('')
