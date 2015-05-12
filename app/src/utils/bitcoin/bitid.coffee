ledger.bitcoin ?= {}
ledger.bitcoin.bitid ?= {}

_.extend ledger.bitcoin.bitid,

  # This path do not need a verified PIN to sign messages.
  ROOT_PATH: "0'/0xb11e'"
  CALLBACK_PROXY_URL: "http://www.ledgerwallet.com/api/bitid"

  isValidUri: (uri) ->
    uri.indexOf("bitid") == 0

  _cache: {}

  uriToDerivationUrl: (uri) ->
    url = uri.match(/^bitid:\/\/([^?]+)(?:\?.*)?$/)
    ledger.errors.throw("Invalid BitId URI") unless url?
    url[1]

  ###
  @param [String] uri
  @param [String] address
  @param [String] signature
  @param [Function] success
  @param [Function] error
  @return [Q.Promise]
  ###
  callback: (uri, address, signature) ->
    Q($.ajax(
      type: 'POST',
      url: @CALLBACK_PROXY_URL,
      dataType: 'json',
      data:
        uri: uri,
        address: address,
        signature: signature
    ))

  ###
  @overload getAddress(subpath=undefined, callback=undefined)
    @param [Object] optPath @see getPath
    @param [Function] callback Optional argument
    @return [Q.Promise]

  @overload getAddress(callback)
    @param [Function] callback
    @return [Q.Promise]
  ###
  getAddress: (opts={}, callback=undefined) ->
    [opts, callback] = [{}, opts] if ! callback && typeof opts == 'function'
    path = @getPath(opts)
    return ledger.defer(callback).resolve(@_cache[path]).promise if @_cache[path]?
    ledger.app.dongle.getPublicAddress(path, callback)
    .then (address) =>
      @_cache[path] = address
      address

  ###
  @overload signMessage(message, callback=undefined)
    @param [String] message
    @param [Function] callback Optional argument
    @return [Q.Promise]

  @overload signMessage(message, opts={}, callback=undefined)
    @param [String] message
    @param [Object] optPath @see getPath
    @param [Function] callback Optional argument
    @return [Q.Promise]
  ###
  signMessage: (message, opts={}, callback=undefined) ->
    [opts, callback] = [{}, opts] if ! callback && typeof opts == 'function'
    path = @getPath(opts)
    pubKey = @_cache[path]?.publicKey
    ledger.app.dongle.signMessage(message, path: path, pubKey: pubKey, callback)

  ###
  @overload getPath(opts)
    @param [Object] opts
    @option opts [String, Integer] subpath ex: 0x5fd1
    @return [String]

  @overload getPath(opts)
    @param [Object] opts
    @option opts [String] uri ex: bitid:1btidfR1qF9arjASvKqMooGmnT3mzTZGP
    @return [String]

  @overload getPath(opts)
    @param [Object] opts
    @option opts [String] url ex: 1btidfR1qF9arjASvKqMooGmnT3mzTZGP
    @return [String]

  @overload getPath(opts)
    @param [Object] opts
    @option opts [String] path ex: 0'/0/0xb11e/0x5fd1
    @return [String]
  ###
  getPath: ({subpath, uri, url, path}) ->
    if path?
      path
    if subpath?
      @ROOT_PATH + "/#{subpath}"
    else if uri?
      @getPath(url: @uriToDerivationUrl(uri))
    else if url?
      @getPath(subpath: "0x" + sha256_digest(url).substring(0,8) + "/0")
    else
      @ROOT_PATH

  # @param [Function] callback Optional argument
  # @return [Q.Promise]
  randomAddress: (callback=undefined) ->
    i = sjcl.random.randomWords(1) & 0xffff
    @getAddress(i, callback)

for key, value of ledger.bitcoin.bitid when _(value).isFunction()
  ledger.bitcoin.bitid[key] = ledger.bitcoin.bitid[key].bind ledger.bitcoin.bitid
