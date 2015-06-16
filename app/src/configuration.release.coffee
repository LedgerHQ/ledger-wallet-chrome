@ledger.env = "prod"
@ledger.isProd = ledger.env == "prod"
@ledger.isDev = ledger.env == "dev"

@ledger.bitcoin.Networks =
  bitcoin:
    name: 'bitcoin'
    ticker: 'btc'
    version:
      regular: 0
      P2SH: 5
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
  testnet:
    name: 'testnet'
    ticker: 'btctest'
    version:
      regular: 111
      P2SH: 196
    bitcoinjs: bitcoin.networks.testnet
    ws_chain: 'testnet3'
  litecoin:
    ticker: 'ltc'
    version:
      regular: 48
      P2SH: 5
    bitcoinjs: bitcoin.networks.litecoin
  litecoin_test:
    ticker: 'ltctest'
    version:
      regular: 111
      P2SH: 196
  dogecoin:
    ticker: 'doge'
    version:
      regular: 30
      P2SH: 22
    bitcoinjs: bitcoin.networks.dogecoin
  dogecoin_test:
    ticker: 'dogetest'
    version:
      regular: 113
      P2SH: 196

@ledger.config ?= {}
_.extend @ledger.config,
  m2fa:
    baseUrl: 'wss://ws.ledgerwallet.com/2fa/channels'
  restClient:
    baseUrl: 'https://api.ledgerwallet.com/'
  syncRestClient:
    pullIntervalDelay: 60000
    pullThrottleDelay: 1000
    pushDebounceDelay: 1000
  defaultLoggingLevel: "NONE"
  defaultLoggerDaysMax: 2
  btcshipDebug: false
  network: @ledger.bitcoin.Networks.testnet

# Btcship logging
@DEBUG = ledger.config.btcshipDebug

@configureApplication = (app) ->
  _.extend @ledger.config,
    defaultLoggingLevel:
      Connected:
        Enabled: ledger.utils.Logger.Levels.ALL
        Disabled: ledger.utils.Logger.Levels.NONE
      Disconnected:
        Enabled: ledger.utils.Logger.Levels.ALL
        Disabled: ledger.utils.Logger.Levels.ALL
