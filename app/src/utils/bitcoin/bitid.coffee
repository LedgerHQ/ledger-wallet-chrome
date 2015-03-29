ledger.bitcoin ?= {}
ledger.bitcoin.bitid ?= {}

_.extend ledger.bitcoin.bitid,

  DEFAULT_DERIVATION_PATH: "0xb11e'"

  # @param [String] bitit uri
  # @return [String] derivation url
  uriToDerivationUrl: (uri) ->
    derivationUrl = uri.replace("bitid://", "").replace("bitid:", "")
    return derivationUrl.substring(0, derivationUrl.indexOf("?"))

  # @param [String] bitit uri
  # @return [String] derivation path
  uriToDerivationPath: (uri) ->
    derivationUrl = @uriToDerivationUrl(uri)
    return "0'/" + @DEFAULT_DERIVATION_PATH + "/0x" + sha256_digest(derivationUrl).substring(0,8) + "/0"

for key, value of ledger.bitcoin.bitid when _(value).isFunction()
  ledger.bitcoin.bitid[key] = ledger.bitcoin.bitid[key].bind ledger.bitcoin.bitid