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
      l 'Got index', index
      address = if index < PREDEFINED_PUBLIC_ADDRESSES.length then PREDEFINED_PUBLIC_ADDRESSES[index] else PREDEFINED_PUBLIC_ADDRESSES[PREDEFINED_PUBLIC_ADDRESSES.length - 1]
      addresses[path] = address if address?
    else if path.indexOf("44'/0'/0'/1/") isnt -1
      index = parseInt(path.replace("44'/0'/0'/1/", ''))
      address = if index < PREDEFINED_CHANGE_ADDRESSES.length then PREDEFINED_CHANGE_ADDRESSES[index] else PREDEFINED_CHANGE_ADDRESSES[PREDEFINED_CHANGE_ADDRESSES.length - 1]
      addresses[path] = address if address?
  callback?(addresses)

_.extend ledger.wallet,

  pathsToAddresses: (paths, callback) ->

    # Uncomment for debugging with predefined addresses
    # return pathsToPredefinedAddresses(paths, callback)

    @safe()

    addresses = {}
    notFound = []
    _.async.each paths, (path, done, hasNext) ->
      # Hit the cache first
      address = ledger.wallet.HDWallet.instance?.cache?.get(path)
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

  # @return Return true if wallet is plugged and unblocked.
  isPluggedAndUnlocked: () ->
    ledger.app.wallet? && ledger.app.wallet._state == ledger.wallet.States.UNLOCKED

  # @return Return current unblocked wallet or throw error if wallet is not plugged or not unblocked.
  safe: () ->
    throw 'the wallet is not connected and unlocked' unless @isPluggedAndUnlocked()
    return ledger.app.wallet
