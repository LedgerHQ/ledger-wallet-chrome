
@ledger.bitcoin ?= {}

_.extend ledger.bitcoin,

  # Checks if a bitcoin address is valid or not
  # @param [String] address The bitcoin address to check
  # @return [Boolean] true if the address is valid otherwise no
  verifyAddress: (address) -> ledger.bitcoin.checkAddress(address)

  estimateTransactionSize: (inputsCount, outputsCount) ->
  	if inputsCount < 0xfd
  		varintLength = 1
  	else if inputsCount < 0xffff
  		varintLength = 3
  	else
  		varintLength = 5
  	if ledger.config.network.handleSegwit
  		minNoWitness = varintLength + 4 + 2 + (59 * inputsCount) + 1 + (31 * outputsCount) + 4
  		maxNoWitness = varintLength + 4 + 2 + (59 * inputsCount) + 1 + (33 * outputsCount) + 4
  		minWitness = varintLength + 4 + 2 + (59 * inputsCount) + 1 + (31 * outputsCount) + 4 + (106 * inputsCount)
  		maxWitness = varintLength + 4 + 2 + (59 * inputsCount) + 1 + (33 * outputsCount) + 4 + (108 * inputsCount)
  		minSize = (minNoWitness * 3 + minWitness) / 4
  		maxSize = (maxNoWitness * 3 + maxWitness) / 4
  	else
  	  minSize = varintLength + 4 + (145 * inputsCount) + 1 + (31 * outputsCount) + 4
  	  maxSize = varintLength + 4 + (147 * inputsCount) + 1 + (33 * outputsCount) + 4
    	
    min: minSize, max: maxSize
