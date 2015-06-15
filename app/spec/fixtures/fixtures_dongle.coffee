ledger.specs.fixtures ?= {}

_.extend ledger.specs.fixtures,

  # Please don't make transactions with this seed or you will screw up the tests
  dongles:
    dongle1:
      id: 1
      masterSeed: 'af5920746fad1e40b2a8c7080ee40524a335f129cb374d4c6f82fd6bf3139b17191cb8c38b8e37f4003768b103479947cab1d4f68d908ae520cfe71263b2a0cd'
      mnemonic: 'fox luggage hero item busy harbor dawn veteran bottom antenna rigid upgrade merit cash cigar episode leg multiply fish path tooth cup nation erosion'
      pairingKey: 'a26d9f9187c250beb7be79f9eb8ff249'
      pin: '0000'


    # Empty wallet account
    dongle2:
      id: 2
      masterSeed: '16eb9af19037ea27cb9d493654d612217547cbd995ae0542c47902f683398eb85ae39579b80b839757ae7dee52bbb895eee421aedaded5a14d87072554026186'
      mnemonic: 'forest zebra delay attend prevent lab game secret cattle open degree among cigar wolf wagon catch invest glare tumble unit crumble tower skull tribe'
      pairingKey: 'a26d9f9187c250beb7be79f9eb8ff249'
      pin: '0000'