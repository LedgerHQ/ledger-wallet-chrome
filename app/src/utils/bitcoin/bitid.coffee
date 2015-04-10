ledger.bitcoin ?= {}
ledger.bitcoin.bitid ?= {}

_.extend ledger.bitcoin.bitid,

  DEFAULT_DERIVATION_PATH: "0xb11e'"
  CALLBACK_PROXY_URL: "http://www.ledgerwallet.com/api/bitid"

  isValidUri: (uri) ->
    uri.indexOf("bitid") == 0

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

  callback: (uri, address, signature, success, error) ->
     $.ajax     
       type: 'POST',
       url: ledger.bitcoin.bitid.CALLBACK_PROXY_URL,
       dataType: 'json',
       success: success,
       error: error,
       data:
          uri: uri,
          address: address,
          signature: signature

for key, value of ledger.bitcoin.bitid when _(value).isFunction()
  ledger.bitcoin.bitid[key] = ledger.bitcoin.bitid[key].bind ledger.bitcoin.bitid