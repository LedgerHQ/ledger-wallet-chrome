ledger.bitcoin ||= {}
ledger.bitcoin.Networks =
  bitcoin:
    name: 'bitcoin'
    ticker: 'btc'
    units:
      bitcoin:
        symbol: 'BTC'
        unit: 8
      milibitcoin:
        symbol: 'mBTC'
        unit: 5
      microbitcoin:
        symbol: 'bits'
        unit: 2
    explorers:
      blockchain:
        name: 'Blockchain.info'
        address: 'https://chain.so/tx//%s'
      blockr:
        name: 'Blockr.io'
        address: 'https://btc.blockr.io/tx/info/%s'
      biteasy:
        name: 'Biteasy.com'
        address: 'https://www.biteasy.com/blockchain/transactions/%s'
      insight:
        name: 'Insight.is'
        address: 'https://insight.bitpay.com/tx/%s'
    bip44_coin_type: '0'
    version:
      regular: 0
      P2SH: 5
    bitcoinjs: bitcoin.networks.bitcoin
    ws_chain: 'bitcoin'

  testnet:
    name: 'testnet'
    ticker: 'btctest'
    units:
      bitcoin:
        symbol: 'BTC'
        unit: 8
      milibitcoin:
        symbol: 'mBTC'
        unit: 5
      microbitcoin:
        symbol: 'bits'
        unit: 2
    explorers:
      sochain:
        name: 'Chain.so'
        address: 'https://chain.so/tx/BTCTEST/%s'
    bip44_coin_type: '1'
    version:
      regular: 111
      P2SH: 196
    bitcoinjs: bitcoin.networks.testnet
    ws_chain: 'testnet3'

  litecoin:
    ticker: 'ltc'
    units:
      bitcoin:
        symbol: 'LTC'
        unit: 8
      milibitcoin:
        symbol: 'mLTC'
        unit: 5
      microbitcoin:
        symbol: 'µLTC'
        unit: 2
    explorers:
      sochain:
        name: 'Chain.so'
        address: 'https://chain.so/tx/LTC/%s'
    bip44_coin_type: '2'
    version:
      regular: 48
      P2SH: 5
    bitcoinjs: bitcoin.networks.litecoin

  litecoin_test:
    ticker: 'ltctest'
    units:
      bitcoin:
        symbol: 'LTC'
        unit: 8
      milibitcoin:
        symbol: 'mLTC'
        unit: 5
      microbitcoin:
        symbol: 'µLTC'
        unit: 2
    explorers:
      sochain:
        name: 'Chain.so'
        address: 'https://chain.so/tx/LTCTEST/%s'
    bip44_coin_type: '1'
    version:
      regular: 111
      P2SH: 196

  dogecoin:
    ticker: 'doge'
    units:
      bitcoin:
        symbol: 'DOGE'
        unit: 8
      milibitcoin:
        symbol: 'mDOGE'
        unit: 5
      microbitcoin:
        symbol: 'µDOGE'
        unit: 2
    explorers:
      sochain:
        name: 'Chain.so'
        address: 'https://chain.so/tx/DOGE/%s'
    bip44_coin_type: '3'
    version:
      regular: 30
      P2SH: 22
    bitcoinjs: bitcoin.networks.dogecoin

  dogecoin_test:
    ticker: 'dogetest'
    units:
      bitcoin:
        symbol: 'DOGE'
        unit: 8
      milibitcoin:
        symbol: 'mDOGE'
        unit: 5
      microbitcoin:
        symbol: 'µDOGE'
        unit: 2
    explorers:
      sochain:
        name: 'Chain.so'
        address: 'https://chain.so/tx/DOGETEST/%s'
    bip44_coin_type: '1'
    version:
      regular: 113
      P2SH: 196