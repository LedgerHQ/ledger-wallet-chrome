@ledger.wallet ?= {}

PREDEFINED_CHANGE_ADDRESSES = []
PREDEFINED_PUBLIC_ADDRESSES = [
  "1P78Rgr9j2zjXzgSLGrBtrcCMtMXT9Xcph"
  "1N78dYebs1F3mE9HnqEtZJtSiGMcrnwWGa"
  "1LLmKpkcipSY3jbRmbK1E8QPduPEoU7XBE"
  "1CN48KfRbGx2NqY7aEMxxXLNkqGr3Z9pUy"
  "13UYbtyCqStgAJ4zNYyuKdZF8NV3zweLzp"
  "1Np3B317y2vEaU3VweQfCbvBxEoEonPsv1"
  "1MCN7i7GCoLjJNzX7oqCcd2SYhkhwNr6qk"
  "14NDJh45EBVAihEBTuQwpLht3ouyFA6krw"
  "14PKwmc61g26Rsnw1MPi77FYXKTZiJiUDf"
  "15D9MY3bqmTHiiLLQVUWsGYjsu2XxBLsJx"
  "1EDLmH7BBE2apBCvUVp7J9dzZ4RYVHCY4Y"
  "1MrpXW4dUz4FgFhNwkeqHqsWJDn12mPZPe"
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

    # throw error unless dongle is plugged and unlocked
    ledger.dongle.unlocked()

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
