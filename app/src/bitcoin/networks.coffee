bitcoin.networks.dash =
  magicPrefix: '\x19DarkCoin Signed Message:\n',
  bip32:
    public: 0x02FE52F8,
    private: 0x05358394
  pubKeyHash: 76
  scriptHash: 16

bitcoin.networks.btcgpu =
  magicPrefix: '\x18Bitcoin gold Signed Message:\n'
  bip32:
    public: 0x0488B21E
    private: 0x0488ADE4
  pubKeyHash: 38
  scriptHash: 23

bitcoin.networks.zcash =
  magicPrefix: '\x16Zcash Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 0x1CB8
  scriptHash: 0x1CBD

bitcoin.networks.zencash =
  magicPrefix: '\x18Zencash Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x0488ADE4
  pubKeyHash: 0x2089
  scriptHash: 0x2096

bitcoin.networks.clubcoin =
  magicPrefix: '\x19ClubCoin Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 28
  scriptHash: 85

bitcoin.networks.qtum =
  magicPrefix: '\x15Qtum Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 58
  scriptHash: 50

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

bitcoin.networks.poswallet =
  magicPrefix: '\x1aPoSWallet Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 55
  scriptHash: 85

bitcoin.networks.vertcoin =
  magicPrefix: '\x19Vertcoin Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 71
  scriptHash: 5

bitcoin.networks.stealthcoin =
  magicPrefix: '\x1cStealthCoin Signed Message:\n'
  bip32:
    public: 0x8f624b66,
    private: 0x05358394
  pubKeyHash: 62
  scriptHash: 85

bitcoin.networks.pivx =
  magicPrefix: '\x18DarkNet Signed Message:\n'
  bip32:
    public: 0x022D2533,
    private: 0x05358394
  pubKeyHash: 30
  scriptHash: 13

bitcoin.networks.viacoin =
  magicPrefix: '\x18Viacoin Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x05358394
  pubKeyHash: 71
  scriptHash: 33

bitcoin.networks.hcash =
  magicPrefix: '\x17HShare Signed Message:\n'
  bip32:
    public: 0x0488c21e,
    private: 0x05358394
  pubKeyHash: 40
  scriptHash: 100

bitcoin.networks.digibyte =
  magicPrefix: '\x19DigiByte Signed Message:\n'
  bip32:
    public: 0x0488b21e,
    private: 0x05358394
  pubKeyHash: 30
  scriptHash: 5

bitcoin.networks.ravencoin =
  magicPrefix: '\x16Raven Signed Message:\n'
  bip32:
    public: 0x0488B21E,
    private: 0x0488ADE4
  pubKeyHash: 60
  scriptHash: 122

ledger.bitcoin ||= {}
ledger.bitcoin.Networks =
  bitcoin:
    name: 'bitcoin'
    display_name: 'bitcoin'
    chain: 'Bitcoin'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btc'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '0'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    message: yes

  bitcoin_segwit:
    name: 'bitcoin_segwit'
    display_name: 'bitcoin'
    chain: 'Bitcoin Segwit'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btc'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '0'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    message: yes

  bitcoin_recover:
    name: 'bitcoin_recover'
    display_name: 'bitcoin'
    chain: 'Bitcoin Recovery Tool'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btc'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '145'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    message: yes

  bitcoin_cash_unsplit:
    name: 'bitcoin_cash_unsplit'
    display_name: 'bitcoin'
    chain: 'Bitcoin Cash (Main)'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'abc'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBCH'
      to: 'toBCH'
    bip44_coin_type: '0'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    notCompatible: yes
    greyed: no
    message: yes

  bitcoin_cash_split:
    name: 'bitcoin_cash_split'
    display_name: 'bitcoin'
    chain: 'Bitcoin Cash (Split)'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'abc'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBCH'
      to: 'toBCH'
    bip44_coin_type: '145'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    notCompatible: yes
    greyed: yes
    message: yes

  bitcoin_gold_unsplit:
    name: 'bitcoin_gold_unsplit'
    display_name: 'bitcoin'
    chain: 'Bitcoin gold (Split)'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btg'
    scheme: 'bitcoingold:'
    tickerKey:
      from: 'fromBTG'
      to: 'toBTG'
    bip44_coin_type: '0'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 38
      P2SH: 23
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.btcgpu
    ws_chain: 'btcgpu'
    dust: 5430
    handleFeePerByte: yes
    notCompatible: yes
    message: yes
    hidden: yes

  bitcoin_gold_split:
    name: 'bitcoin_gold_split'
    display_name: 'bitcoin'
    chain: 'Legacy'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btg'
    scheme: 'bitcoingold:'
    tickerKey:
      from: 'fromBTG'
      to: 'toBTG'
    bip44_coin_type: '156'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 38
      P2SH: 23
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.btcgpu
    ws_chain: 'btcgpu'
    dust: 5430
    handleFeePerByte: yes
    notCompatible: yes
    message: yes

  bitcoin_gold_unsplit_segwit:
    name: 'bitcoin_gold_unsplit_segwit'
    display_name: 'bitcoin'
    chain: 'Bitcoin gold (Split/Segwit)'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btg'
    scheme: 'bitcoingold:'
    tickerKey:
      from: 'fromBTG'
      to: 'toBTG'
    bip44_coin_type: '0'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 38
      P2SH: 23
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.btcgpu
    ws_chain: 'btcgpu'
    dust: 5430
    handleFeePerByte: yes
    notCompatible: yes
    message: yes
    hidden: yes

  bitcoin_gold_split_segwit:
    name: 'bitcoin_gold_split_segwit'
    display_name: 'bitcoin'
    chain: 'Segwit'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'btg'
    scheme: 'bitcoingold:'
    tickerKey:
      from: 'fromBTG'
      to: 'toBTG'
    bip44_coin_type: '156'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 38
      P2SH: 23
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.btcgpu
    ws_chain: 'btcgpu'
    dust: 5430
    handleFeePerByte: yes
    notCompatible: yes
    message: yes

  ###bitcoin_uasf:
    name: 'bitcoin_uasf'
    display_name: 'bitcoin'
    chain: 'Bitcoin UASF'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'uasf'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '0'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    greyed: yes
    message: yes

  bitcoin_segwit2x:
    name: 'bitcoin_segwit2x'
    display_name: 'bitcoin'
    chain: 'Bitcoin Segwit2x'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'segwit2x'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '0'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    greyed: yes
    message: yes

  bitcoin_segwit2x_segwit:
    name: 'bitcoin_segwit2x_segwit'
    display_name: 'bitcoin'
    chain: 'Bitcoin Segwit2x'
    bolosAppName: 'Bitcoin'
    plural: 'bitcoins'
    ticker: 'segwit2x'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '0'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 0
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
    dust: 5430
    handleFeePerByte: yes
    greyed: yes
    message: yes  ###

  testnet:
    name: 'testnet'
    plural: 'bitcoins'
    ticker: 'btc_testnet'
    scheme: 'bitcoin:'
    tickerKey:
      from: 'fromBTC'
      to: 'toBTC'
    bip44_coin_type: '1'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 111
      P2SH: 196
      XPUB: 0x043587CF
    bitcoinjs: bitcoin.networks.testnet
    ws_chain: 'testnet3'
    dust: 5430
    handleFeePerByte: yes

  litecoin_old:
    name: 'litecoin'
    display_name: 'litecoin'
    plural: 'litecoins'
    scheme: 'litecoin:'
    bolosAppName: 'Litecoin'
    ticker: 'ltc'
    tickerKey:
      from: 'fromLTC'
      to: 'toLTC'
    bip44_coin_type: '2'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 48
      P2SH: 5
      XPUB: 0x19DA462
    bitcoinjs: bitcoin.networks.litecoin
    dust: 10000
    handleFeePerByte: no

  litecoin:
    name: 'litecoin'
    display_name: 'litecoin'
    chain: 'Legacy'
    plural: 'litecoins'
    scheme: 'litecoin:'
    bolosAppName: 'Litecoin'
    ticker: 'ltc'
    tickerKey:
      from: 'fromLTC'
      to: 'toLTC'
    bip44_coin_type: '2'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 48
      P2SH: 50
      XPUB: 0x19DA462
    bitcoinjs: bitcoin.networks.litecoin
    dust: 10000
    handleFeePerByte: no

  litecoin_segwit:
    name: 'litecoin_segwit'
    display_name: 'litecoin'
    chain: 'Segwit'
    plural: 'litecoins'
    scheme: 'litecoin:'
    bolosAppName: 'Litecoin'
    ticker: 'ltc'
    tickerKey:
      from: 'fromLTC'
      to: 'toLTC'
    bip44_coin_type: '2'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 48
      P2SH: 50
      XPUB: 0x19DA462
    bitcoinjs: bitcoin.networks.litecoin
    dust: 10000
    handleFeePerByte: no

  dogecoin:
    name: 'dogecoin'
    display_name: 'dogecoin'
    plural: 'dogecoins'
    scheme: 'dogecoin:'
    bolosAppName: 'Dogecoin'
    ticker: 'doge'
    tickerKey:
      from: 'fromDOGE'
      to: 'toDOGE'
    bip44_coin_type: '3'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 30
      P2SH: 22
      XPUB: 0x02facafd
    bitcoinjs: bitcoin.networks.dogecoin
    dust: 10000
    handleFeePerByte: no

  dash:
    name: 'dash'
    display_name: 'dash'
    plural: 'dash'
    scheme: 'dash:'
    bolosAppName: 'Dash'
    ticker: 'dash'
    tickerKey:
      from: 'fromDASH'
      to: 'toDASH'
    bip44_coin_type: '5'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 76
      P2SH: 16
      XPUB: 0x02FE52F8
    bitcoinjs: bitcoin.networks.dash
    dust: 10000
    handleFeePerByte: no

  zcash:
    name: 'zcash'
    display_name: 'zcash'
    plural: 'zcash'
    scheme: 'zcash:'
    bolosAppName: 'Zcash'
    ticker: 'zec'
    tickerKey:
      from: 'fromZEC'
      to: 'toZEC'
    bip44_coin_type: '133'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 0x1CB8
      P2SH: 0x1CBD
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.zcash
    dust: 10000
    handleFeePerByte: no

  zencash:
    name: 'zencash'
    display_name: 'zencash'
    plural: 'zencash'
    scheme: 'zencash:'
    bolosAppName: 'ZenCash'
    ticker: 'zen'
    tickerKey:
      from: 'fromZEN'
      to: 'toZEN'
    bip44_coin_type: '121'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 0x2089
      P2SH: 0x2096
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.zencash
    dust: 10000
    handleFeePerByte: no

  clubcoin:
    name: 'clubcoin'
    display_name: 'clubcoin'
    plural: 'clubcoins'
    scheme: 'clubcoin:'
    bolosAppName: 'ClubCoin'
    ticker: 'club'
    tickerKey:
      from: 'fromCLUB'
      to: 'toCLUB'
    bip44_coin_type: '79'
    handleSegwit: no
    isSegwitSupported: no
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
    display_name: 'stratis'
    plural: 'stratis'
    scheme: 'stratis:'
    bolosAppName: 'Stratis'
    ticker: 'strat'
    tickerKey:
      from: 'fromSTRAT'
      to: 'toSTRAT'
    bip44_coin_type: '105'
    handleSegwit: no
    isSegwitSupported: no
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
    display_name: 'peercoin'
    plural: 'peercoins'
    scheme: 'peercoin:'
    bolosAppName: 'Peercoin'
    ticker: 'ppc'
    tickerKey:
      from: 'fromPPC'
      to: 'toPPC'
    bip44_coin_type: '6'
    handleSegwit: no
    isSegwitSupported: no
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
    display_name: 'komodo'
    plural: 'komodos'
    scheme: 'komodo:'
    bolosAppName: 'Komodo'
    ticker: 'kmd'
    tickerKey:
      from: 'fromKMD'
      to: 'toKMD'
    bip44_coin_type: '141'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 60
      P2SH: 85
      XPUB: 0xf9eee48d
    bitcoinjs: bitcoin.networks.komodo
    dust: 10000
    handleFeePerByte: no

  poswallet:
    name: 'poswallet'
    display_name: 'posw'
    plural: 'poswallets'
    scheme: 'poswallet:'
    bolosAppName: 'poswallet'
    ticker: 'posw'
    tickerKey:
      from: 'fromPOSW'
      to: 'toPOSW'
    bip44_coin_type: '47'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 55
      P2SH: 85
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.poswallet
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: yes

  vertcoin:
    name: 'vertcoin'
    chain: 'Vertcoin'
    display_name: 'vertcoin'
    plural: 'vertcoins'
    scheme: 'vertcoin:'
    bolosAppName: 'vertcoin'
    ticker: 'vtc'
    tickerKey:
      from: 'fromVTC'
      to: 'toVTC'
    bip44_coin_type: '128'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 71
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.vertcoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: no

  vertcoin_segwit:
    name: 'vertcoin_segwit'
    chain: 'Vertcoin Segwit'
    display_name: 'vertcoin'
    plural: 'vertcoins'
    scheme: 'vertcoin:'
    bolosAppName: 'vertcoin'
    ticker: 'vtc'
    tickerKey:
      from: 'fromVTC'
      to: 'toVTC'
    bip44_coin_type: '128'
    handleSegwit: yes
    isSegwitSupported: yes
    version:
      regular: 71
      P2SH: 5
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.vertcoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: no

  stealthcoin:
    name: 'stealthcoin'
    display_name: 'stealthcoin'
    plural: 'stealthcoins'
    scheme: 'stealthcoin:'
    bolosAppName: 'stealthcoin'
    ticker: 'xst'
    tickerKey:
      from: 'fromXST'
      to: 'toXST'
    bip44_coin_type: '125'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 62
      P2SH: 85
      XPUB: 0x8f624b66
    bitcoinjs: bitcoin.networks.stealthcoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: yes

  pivx:
    name: 'pivx'
    display_name: 'pivx'
    plural: 'pivx'
    scheme: 'pivx:'
    bolosAppName: 'pivx'
    ticker: 'pivx'
    tickerKey:
      from: 'fromPIVX'
      to: 'toPIVX'
    bip44_coin_type: '77'
    handleSegwit: no
    isSegwitSupported: no
    version:
      regular: 30
      P2SH: 13
      XPUB: 0x022D2533
    bitcoinjs: bitcoin.networks.pivx
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: no

  viacoin:
    name: 'viacoin'
    chain: 'Viacoin'
    display_name: 'viacoin'
    plural: 'viacoins'
    scheme: 'viacoin:'
    bolosAppName: 'viacoin'
    ticker: 'via'
    tickerKey:
      from: 'fromVIA'
      to: 'toVIA'
    bip44_coin_type: '14'
    handleSegwit: no
    isSegwitSupported: yes
    version:
      regular: 71
      P2SH: 33
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.viacoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: no

  viacoin_segwit:
      name: 'viacoin_segwit'
      display_name: 'viacoin'
      chain: 'Viacoin Segwit'
      plural: 'viacoins'
      scheme: 'viacoin:'
      bolosAppName: 'viacoin'
      ticker: 'via'
      tickerKey:
        from: 'fromVIA'
        to: 'toVIA'
      bip44_coin_type: '14'
      handleSegwit: yes
      isSegwitSupported: yes
      version:
        regular: 71
        P2SH: 33
        XPUB: 0x0488B21E
      bitcoinjs: bitcoin.networks.viacoin
      dust: 10000
      handleFeePerByte: no
      areTransactionTimestamped: no

  qtum:
    name: 'qtum'
    display_name: 'qtum'
    plural: 'qtums'
    scheme: 'qtum:'
    bolosAppName: 'qtum'
    ticker: 'qtum'
    tickerKey:
      from: 'fromQTUM'
      to: 'toQTUM'
    bip44_coin_type: '88'
    isSegwitSupported: yes
    version:
      regular: 58
      P2SH: 50
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.qtum
    dust: 10000
    handleFeePerByte: no

  hcash:
    name: 'hcash'
    display_name: 'hcash'
    plural: 'hcash'
    scheme: 'hcash:'
    bolosAppName: 'hcash'
    ticker: 'hsr'
    tickerKey:
      from: 'fromHSR'
      to: 'toHSR'
    bip44_coin_type: '171'
    isSegwitSupported: no
    version:
      regular: 40
      P2SH: 100
      XPUB: 0x0488c21E
    bitcoinjs: bitcoin.networks.hcash
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: yes

  digibyte:
    name: 'digibyte'
    display_name: 'digibyte'
    plural: 'digibytes'
    scheme: 'digibyte:'
    bolosAppName: 'digibyte'
    ticker: 'dgb'
    tickerKey:
      from: 'fromDGB'
      to: 'toDGB'
    bip44_coin_type: '20'
    isSegwitSupported: no
    version:
      regular: 30
      P2SH: 5
      XPUB: 0x0488b21E
    bitcoinjs: bitcoin.networks.digibyte
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: no

  ravencoin:
    name: 'ravencoin'
    display_name: 'ravencoin'
    plural: 'ravencoins'
    scheme: 'ravencoin:'
    bolosAppName: 'ravencoin'
    ticker: 'rvn'
    tickerKey:
      from: 'fromRVN'
      to: 'toRVN'
    bip44_coin_type: '175'
    isSegwitSupported: no
    version:
      regular: 60
      P2SH: 122
      XPUB: 0x0488B21E
    bitcoinjs: bitcoin.networks.ravencoin
    dust: 10000
    handleFeePerByte: no
    areTransactionTimestamped: no
