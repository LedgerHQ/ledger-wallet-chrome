ledger.wallet ?= {}

class ledger.wallet.Input

  @inputsFromUnspentsOutputs: (unspentOutputs, callback) ->
    addresses = (address for address in unspentOutput.addresses for unspentOutput in unspentOutputs)
    l addresses

