@ledger.wallet ?= {}

PREDEFINED_CHANGE_ADDRESSES = []
PREDEFINED_PUBLIC_ADDRESSES = [
  "1KAkAp8Jxan81z72WzDpS27Az1FXB3tmak"
]

pathsToPredefinedAddresses = (paths, callback) ->
  addresses = {}
  for path in paths
    if path.indexOf("44'/0'/0'/0/") isnt -1
      index = parseInt(path.replace("44'/0'/0'/0/", ''))
      address = if index < PREDEFINED_PUBLIC_ADDRESSES.length then PREDEFINED_PUBLIC_ADDRESSES[index] else PREDEFINED_PUBLIC_ADDRESSES[PREDEFINED_PUBLIC_ADDRESSES.length - 1]
      addresses[path] = address if address?
    else if path.indexOf("44'/0'/0'/1/") isnt -1
      index = parseInt(path.replace("44'/0'/0'/1/", ''))
      address = if index < PREDEFINED_CHANGE_ADDRESSES.length then PREDEFINED_CHANGE_ADDRESSES[index] else PREDEFINED_CHANGE_ADDRESSES[PREDEFINED_CHANGE_ADDRESSES.length - 1]
      addresses[path] = address if address?
  callback?(addresses)

_.extend ledger.wallet,

  pathsToAddresses: (paths, callback = undefined) ->
    # Uncomment for debugging with predefined addresses
    # return pathsToPredefinedAddresses(paths, callback)

    # throw error unless dongle is plugged and unlocked
    ledger.dongle.unlocked()

    if _.isEmpty(paths)
      ledger.utils.Logger.getLoggerByTag('WalletUtils').warn("Attempts to derive empty paths ", new Error().stack)
      return callback?({})

    addresses = {}
    notFound = []
    _.async.each paths, (path, done, hasNext) ->
      # Hit the cache first
      address = ledger.wallet.Wallet.instance?.cache?.get(path)
      if address?
        addresses[path] = address
        callback?(addresses, notFound) unless hasNext is true
        do done
        return

      ledger.tasks.AddressDerivationTask.instance.getPublicAddress path, (result, error) ->
        if error?
          notFound.push path
        else
          addresses[path] = result
        callback?(addresses, notFound) unless hasNext
        do done
        return

    return

  checkSetup: (dongle, seed, pin, callback = undefined ) ->
    ledger.defer(callback)
    .resolve do ->
      dongle.lock()
      dongle.unlockWithPinCode(pin)
      .then ->
        node = bitcoin.HDNode.fromSeedHex(seed, ledger.config.network.bitcoinjs)
        address = node.deriveHardened(44).deriveHardened(0).deriveHardened(0).derive(0).derive(0).pubKey.getAddress().toString()
        dongle.getPublicAddress("44'/0'/0'/0/0").then (result) ->
          throw new Error("Invalid Seed") if address isnt result.bitcoinAddress.toString(ASCII)
    .promise
