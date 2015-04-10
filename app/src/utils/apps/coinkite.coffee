class @Coinkite

  API_BASE: "https://api.coinkite.com"
  CK_PATH: "0xb11e'/0xffaa001'"

  @factory: (callback) ->
    ledger.storage.sync.get "__apps_coinkite_api_key", (r) =>
      api_key = r.__apps_coinkite_api_key
      ledger.storage.sync.get "__apps_coinkite_api_secret", (r) =>
        secret = r.__apps_coinkite_api_secret
        if typeof secret == "string"
          callback(new Coinkite(api_key, secret))
        else
          callback undefined

  constructor: (api_key, secret) ->
    @apiKey = api_key
    @secret = secret
    @httpClient = new HttpClient(@API_BASE)

  getExtendedPublickey: (callback) ->
    try
      ledger.app.dongle.getExtendedPublicKey @CK_PATH, (key) =>
        @xpub = key._xpub58
        ledger.bitcoin.bitid.signMessage "Coinkite", path: @CK_PATH, pubkey: key._xpub, (signature) =>
          callback?({xpub: @xpub, signature: signature}, null)
    catch error
      callback?(null, error)

  getRequestData: (request, callback) ->
    url = '/v1/co-sign/' + request
    @_setAuthHeaders(url)
    @httpClient
      .do type: 'GET', url: url
      .then (data, statusText, jqXHR) =>
        callback?(data, null)
      .fail (error, statusText) =>
        callback?(null, error.responseJSON.message + ' ' + error.responseJSON.help_msg)
      .done()

  getCosigner: (data, callback) ->
    @cosigner = null
    try
      ledger.app.dongle.getExtendedPublicKey @CK_PATH, (key) =>
        xpub = key._xpub58
        async.eachSeries data.cosigners, ((cosigner, finishedCallback) =>
          check = cosigner.xpubkey_check
          if xpub.indexOf(check, xpub.length - check.length) > 0
            @cosigner = cosigner.CK_refnum
          finishedCallback()
        ), (finished) =>
          callback @cosigner
    catch error
      callback @cosigner

  getCosignData: (request, cosigner, callback) ->
    @request = request
    @cosigner = cosigner
    url = '/v1/co-sign/' + request + '/' + cosigner
    @_setAuthHeaders(url)
    @httpClient
      .do type: 'GET', url: url
      .then (data, statusText, jqXHR) =>
        callback?(data.signing_info, null)
      .fail (error, statusText) =>
        callback?(null, error.responseJSON.message + ' ' + error.responseJSON.help_msg)
      .done()

  getCosignSummary: (request, cosigner, callback) ->
    @request = request
    @cosigner = cosigner
    url = '/v1/co-sign/' + request + '/' + cosigner + '.html'
    @_setAuthHeaders(url)
    @httpClient
      .do type: 'GET', url: url
      .then (data, statusText, jqXHR) =>
        callback?(data, null)
      .fail (error, statusText) =>
        callback?(null, error.responseJSON.message + ' ' + error.responseJSON.help_msg)
      .done()

  checkKeys: (check, callback) ->
    try
      ledger.app.dongle.getExtendedPublicKey @CK_PATH, (key) =>
        xpub = key._xpub58
        callback?(xpub.indexOf(check, xpub.length - check.length) > 0)
    catch error
      callback?(false, error)

  cosignTransaction: (data, callback) ->
    inputs = data.inputs
    scripts = data.redeem_scripts
    tx = data.raw_unsigned_txn
    try
      transaction = Bitcoin.Transaction.deserialize(tx);
      ledger.app.dongle._btchip.signP2SHTransaction_async(inputs, transaction, scripts, @CK_PATH)
      .then (result) =>
        url = '/v1/co-sign/' + @request + '/' + @cosigner + '/sign'
        @_setAuthHeaders(url)
        @httpClient
          .do type: 'PUT', url: url, dataType: 'json', contentType: 'application/json', data: { signatures: result }
          .then (data, statusText, jqXHR) =>
            callback?(data, null)
          .fail (error, statusText) =>
            callback?(null, error.responseJSON.message + ' ' + error.responseJSON.help_msg)
          .done()        
      .fail (error) =>
        callback?(null, error)
    catch error
      callback?(null, error)

  _setAuthHeaders: (endpoint) ->
    endpoint = endpoint.split('?')[0]
    ts = (new Date).toISOString()
    data = endpoint + '|' + ts
    @httpClient.setHttpHeader 'X-CK-Key', @apiKey
    @httpClient.setHttpHeader 'X-CK-Sign', CryptoJS.HmacSHA256(data, @secret).toString()
    @httpClient.setHttpHeader 'X-CK-Timestamp', ts