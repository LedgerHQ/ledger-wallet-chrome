@ledger.wallet ?= {}

_.extend ledger.wallet,

  pathsToAddresses: (paths, callback) ->
    if not ledger.app.wallet? and ledger.app.wallet._state isnt ledger.wallet.States.UNLOCKED
      throw 'Paths to addresses conversion is not accesible if the wallet is not connected and unlocked'

    addresses = {}
    notFound = []
    _.async.each paths, (path, done, hasNext) ->
      # Hit the cache first
      # No result from cache perform the derivation on the chip
      ledger.app.wallet.getPublicAddress path, (publicKey) ->
        if publicKey?
          addresses[path] = publicKey?.bitcoinAddress?.value
        else
          notFound.push path
        unless hasNext
          try
            callback?(addresses, notFound)
          catch error
            e error
        do done
    return