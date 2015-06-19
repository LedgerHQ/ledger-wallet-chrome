ledger.bitcoin ||= {}
ledger.bitcoin.Networks =
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