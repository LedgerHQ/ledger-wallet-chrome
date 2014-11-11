ledger.bitcoin ?= {}
ledger.bitcoin.bip39 =

  ENTROPY_BYTES_LENGTH: 32
  MNEMONIC_WORDS_NUMBER: 24

  numberOfWordsInMnemonic: (mnemonic) ->
    return 0 if not mnemonic? or mnemonic.length == 0
    count = 0
    words = mnemonic.split ' '
    for word in words
      count++ if word? and word.length > 0
    count

  mnemonicIsValid: (mnemonic) ->
    return no if @numberOfWordsInMnemonic(mnemonic) != @MNEMONIC_WORDS_NUMBER
    return no if mnemonic[mnemonic.length - 1] != 'a'
    yes

  mnemonicToSeed: (mnemonic) ->
    ""

  seedToMnemonic: (seed) ->


for key, value of ledger.bitcoin.bip39 when _(value).isFunction()
  ledger.bitcoin.bip39[key] = ledger.bitcoin.bip39[key].bind ledger.bitcoin.bip39