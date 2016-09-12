ledger.bitcoin ||= {}
ledger.bitcoin.Networks =
  bitcoin:
    name: 'bitcoin'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btc'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '0'
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
  testnet:
    name: 'testnet'
    plural: 'bitcoins'
    ticker: 'btctest'
    bip44_coin_type: '1'
    version:
      regular: 111
      P2SH: 196
    bitcoinjs: bitcoin.networks.testnet
    ws_chain: 'testnet3'
    dust: 5430
    handleFeePerByte: yes
  segnet:
    name: 'segnet'
    plural: 'bitcoins'
    ticker: 'segtest'
    bip44_coin_type: '1'
    version:
      regular: 30
      P2SH: 50
      XPUB: 0x053587CF
    bitcoinjs:
      messagePrefix: '\x18Bitcoin Signed Message:\n',
      bip32: {
        public: 0x053587CF,
        private: 0x05358394
      },
      pubKeyHash: 30,
      scriptHash: 50,
      wif: 158,
      dustThreshold: 546
    dust: 5430
    handleFeePerByte: yes
  litecoin:
    name: 'litecoin'
    plural: 'litecoins'
    bolosAppName: 'Litecoin'
    ticker: 'ltc'
    tickerKey:
      from: 'fromLTC'
      to: 'toLTC'
    bip44_coin_type: '2'
    version:
      regular: 48
      P2SH: 5
      XPUB: 0x19DA462
    bitcoinjs: bitcoin.networks.litecoin
    dust: 10000
    handleFeePerByte: no
  litecoin_test:
    name: 'litecoin test'
    ticker: 'ltctest'
    bip44_coin_type: '1'
    version:
      regular: 111
      P2SH: 196
  dogecoin:
    name: 'dogecoin'
    ticker: 'doge'
    bip44_coin_type: '3'
    version:
      regular: 30
      P2SH: 22
    bitcoinjs: bitcoin.networks.dogecoin
  dogecoin_test:
    name: 'dogecoin test'
    ticker: 'dogetest'
    bip44_coin_type: '1'
    version:
      regular: 113
      P2SH: 196