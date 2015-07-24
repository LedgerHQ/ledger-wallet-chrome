ledger.bitcoin ||= {}
ledger.bitcoin.Networks =
  bitcoin:
    name: 'bitcoin'
    ticker: 'btc'
    bip44_coin_type: '0'
    version:
      regular: 0
      P2SH: 5
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'
  testnet:
    name: 'testnet'
    ticker: 'btctest'
    bip44_coin_type: '0'
    version:
      regular: 111
      P2SH: 196
    bitcoinjs: bitcoin.networks.testnet
    ws_chain: 'testnet3'
  litecoin:
    ticker: 'ltc'
    bip44_coin_type: '2'
    version:
      regular: 48
      P2SH: 5
    bitcoinjs: bitcoin.networks.litecoin
  litecoin_test:
    ticker: 'ltctest'
    bip44_coin_type: '1'
    version:
      regular: 111
      P2SH: 196
  dogecoin:
    ticker: 'doge'
    bip44_coin_type: '3'
    version:
      regular: 30
      P2SH: 22
    bitcoinjs: bitcoin.networks.dogecoin
  dogecoin_test:
    ticker: 'dogetest'
    bip44_coin_type: '1'
    version:
      regular: 113
      P2SH: 196