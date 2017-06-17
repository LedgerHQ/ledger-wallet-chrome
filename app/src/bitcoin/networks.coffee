
bitcoin.networks.dash =
  magicPrefix: '\x19DarkCoin Signed Message:\n',
  bip32:
    public: 0x02FE52F8,
    private: 0x05358394
  pubKeyHash: 76
  scriptHash: 16

bitcoin.networks.zcash =
  magicPrefix: '\x16Zcash Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 0x1CB8
  scriptHash: 0x1CBD

bitcoin.networks.clubcoin =
  magicPrefix: '\x19ClubCoin Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 28
  scriptHash: 85

bitcoin.networks.stratis =
  magicPrefix: '\x18Stratis Signed Message:\n'
  bip32:
    public: 0x0488c21e,
    private: 0x05358394
  pubKeyHash: 63
  scriptHash: 125

bitcoin.networks.peercoin =
  magicPrefix: '\x17PPCoin Signed Message:\n'
  bip32:
    public: 0xe6e8e9e5,
    private: 0x05358394
  pubKeyHash: 55
  scriptHash: 117

bitcoin.networks.komodo =
  magicPrefix: '\x17Komodo Signed Message:\n'
  bip32:
    public: 0xf9eee48d,
    private: 0x05358394
  pubKeyHash: 60
  scriptHash: 85

ledger.bitcoin ||= {}
ledger.bitcoin.Networks =
  bitcoin:
    name: 'bitcoin'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btc'
    scheme: 'bitcoin:'
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
    scheme: 'bitcoin:'
    bip44_coin_type: '1'
    version:
      regular: 111
      P2SH: 196
      XPUB: 0x043587CF
    bitcoinjs: bitcoin.networks.testnet
    ws_chain: 'testnet3'
    dust: 5430
    handleFeePerByte: yes

  segnet:
    name: 'segnet'
    plural: 'bitcoins'
    ticker: 'segtest'
    scheme: 'bitcoin:'
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
    scheme: 'litecoin:'
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

  viacoin:
    name: 'viacoin'
    plural: 'viacoins'
    scheme: 'viacoin'
    bolosAppName: 'Viacoin'
    ticker: 'via'
    tickerKey:
      from: 'fromVIA'
      to: 'toVIA'
    bip44_coin_type: '14'
    version:
      regular: 71
      P2SH: 33
      XPUB: 0X0488B21E
    bitcoinjs: bitcoin.networks.litecoin
    dust: 1000
    handleFeePerByte: no

  dogecoin:
    name: 'dogecoin'
    plural: 'dogecoins'
    scheme: 'dogecoin:'
    bolosAppName: 'Dogecoin'
    ticker: 'doge'
    tickerKey:
      from: 'fromDOGE'
      to: 'toDOGE'
    bip44_coin_type: '3'
    version:
      regular: 30
      P2SH: 22
      XPUB: 0x02facafd
    bitcoinjs: bitcoin.networks.dogecoin
    dust: 10000
    handleFeePerByte: no

  dash:
    name: 'dash'
    plural: 'dash'
    scheme: 'dash:'
    bolosAppName: 'Dash'
    ticker: 'dash'
    tickerKey:
      from: 'fromDASH'
      to: 'toDASH'
    bip44_coin_type: '5'
    version:
      regular: 76
      P2SH: 16
      XPUB: 0x02FE52F8
    bitcoinjs: bitcoin.networks.dash
    dust: 10000
    handleFeePerByte: no

  zcash:
    name: 'zcash'
    plural: 'zcash'
    scheme: 'zcash:'
    bolosAppName: 'Zcash'
    ticker: 'zec'
    tickerKey:
      from: 'fromZEC'
      to: 'toZEC'
    bip44_coin_type: '133'
    version:
      regular: 0x1CB8
      P2SH: 0x1CBD
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.zcash
    dust: 10000
    handleFeePerByte: no

  clubcoin:
    name: 'clubcoin'
    plural: 'clubcoins'
    scheme: 'clubcoin:'
    bolosAppName: 'ClubCoin'
    ticker: 'club'
    tickerKey:
      from: 'fromCLUB'
      to: 'toCLUB'
    bip44_coin_type: '79'
    version:
      regular: 28
      P2SH: 85
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.clubcoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: yes

  stratis:
    name: 'stratis'
    plural: 'stratis'
    scheme: 'stratis:'
    bolosAppName: 'Stratis'
    ticker: 'strat'
    tickerKey:
      from: 'fromSTRAT'
      to: 'toSTRAT'
    bip44_coin_type: '105'
    version:
      regular: 63
      P2SH: 125
      XPUB: 0x0488c21e
    bitcoinjs: bitcoin.networks.stratis
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: yes

  peercoin:
    name: 'peercoin'
    plural: 'peercoins'
    scheme: 'peercoin:'
    bolosAppName: 'Peercoin'
    ticker: 'ppc'
    tickerKey:
      from: 'fromPPC'
      to: 'toPPC'
    bip44_coin_type: '6'
    version:
      regular: 55
      P2SH: 117
      XPUB: 0xe6e8e9e5
    bitcoinjs: bitcoin.networks.peercoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: yes

  komodo:
    name: 'komodo'
    plural: 'komodos'
    scheme: 'komodo:'
    bolosAppName: 'Komodo'
    ticker: 'kmd'
    tickerKey:
      from: 'fromKMD'
      to: 'toKMD'
    bip44_coin_type: '141'
    version:
      regular: 60
      P2SH: 85
      XPUB: 0xf9eee48d
    bitcoinjs: bitcoin.networks.komodo
    dust: 10000
    handleFeePerByte: no
