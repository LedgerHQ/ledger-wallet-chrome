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
    ledger.wallet.pathsToAddressesStream(paths)
      .stopOnError (err) ->
        callback?([], err)
      .toArray (array) ->
        callback(_.object(array), []) if callback?
    return

  ###
    Derives the given paths and return a stream of path -> address pairs
    @param (Array|Stream)
  ###
  pathsToAddressesStream: (paths) ->
    ledger.dongle.unlocked()
    if _.isEmpty(paths)
      ledger.utils.Logger.getLoggerByTag('WalletUtils').warn("Attempts to derive empty paths ", new Error().stack)
      return highland([])
    ledger.stream(paths).consume (err, path, push, next) ->
      if path is ledger.stream.nil
        push(null, ledger.stream.nil)
      else
        # Hit the cache first
        address = ledger.wallet.Wallet.instance?.cache?.get(path)
        if address?
          push(null, [path, address])
          return do next
        ledger.tasks.AddressDerivationTask.instance.getPublicAddress path, (result, error) ->
          if error?
            push([path])
          else
            push(null, [path, result])
          do next

  checkSetup: (dongle, seed, pin, callback = undefined ) ->
    ledger.defer(callback)
    .resolve do ->
      dongle.lock()
      dongle.unlockWithPinCode(pin)
      .then ->
        node = bitcoin.HDNode.fromSeedHex(seed, ledger.config.network.bitcoinjs)
        address = node.deriveHardened(44).deriveHardened(+ledger.config.network.bip44_coin_type).deriveHardened(0).derive(0).derive(0).getAddress().toString()
        dongle.getPublicAddress("44'/#{ledger.config.network.bip44_coin_type}'/0'/0/0").then (result) ->
          throw new Error("Invalid Seed") if address isnt result.bitcoinAddress.toString(ASCII)
    .promise
