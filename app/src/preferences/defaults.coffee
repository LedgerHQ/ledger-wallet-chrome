ledger.preferences ?= {}

# Declares all usable preferences
# All prefrences below are hardened in this file, but some nodes are loaded lazily at app startup
ledger.preferences.defaults =
  # Call at app startup to load lazy preferences defaults nodes
  init: (callback) ->
    # languages
    ledger.preferences.defaults.Display.languages = ledger.i18n.Languages

    # regions
    regions = []
    ledger.i18n.getAllLocales (locales) =>
      ledger.preferences.defaults.Display.regions = locales
      callback?()

  # display preferences
  Display:
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
    languages: null # lazy
    regions: null # lazy

  # bitcoin preferences
  Bitcoin:
    confirmations:
      one: 1
      two: 2
      three: 3
      four: 4
      five: 5
      six: 6
    fees:
      slow:
        value: '1000'
        localization: 'common.fees.slow'
      normal:
        value: '10000'
        localization: 'common.fees.normal'
      fast:
        value: '20000'
        localization: 'common.fees.fast'
    explorers:
      blockchain:
        name: 'Blockchain.info'
        address: 'https://blockchain.info/tx/%s'
      blockr:
        name: 'Blockr.io'
        address: 'https://btc.blockr.io/tx/info/%s'
      biteasy:
        name: 'Biteasy.com'
        address: 'https://www.biteasy.com/blockchain/transactions/%s'
      insight:
        name: 'Insight.is'
        address: 'https://insight.bitpay.com/tx/%s'