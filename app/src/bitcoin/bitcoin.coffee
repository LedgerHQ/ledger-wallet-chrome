
@ledger.bitcoin ?= {}

_.extend ledger.bitcoin,

  # Checks if a bitcoin address is valid or not
  # @param [String] address The bitcoin address to check
  # @return [Boolean] true if the address is valid otherwise no
  verifyAddress: (address) -> ledger.bitcoin.checkAddress(address)

  estimateTransactionSize: (inputsCount, outputsCount) ->
    median = 148 * inputsCount + outputsCount * 34 + 10
    min: median - inputsCount, max: median + inputsCount
