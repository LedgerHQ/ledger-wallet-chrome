@ledger.wallet ?= {}

_.extend ledger.wallet,

  pathsToAddresses: (paths, callback) ->
    if not ledger.app.wallet? and ledger.app.wallet._state isnt ledger.wallet.States.UNLOCKED
      throw 'Paths to addresses conversion is not accesible if the wallet is not connected and unlocked'

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



