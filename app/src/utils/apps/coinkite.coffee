class @Coinkite

  API_BASE: "https://api.coinkite.com"
  @CK_PATH: "0xb11e'/0xccc0'"

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
      ledger.app.wallet.getExtendedPublicKey Coinkite.CK_PATH, (key) =>
        @xpub = key._xpub58
        ledger.app.wallet.signMessageWithBitId Coinkite.CK_PATH, "Coinkite", (signature) =>
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
      ledger.app.wallet.getExtendedPublicKey Coinkite.CK_PATH, (key) =>
        xpub = key._xpub58
        async.eachSeries data.cosigners, ((cosigner, finishedCallback) =>
          check = cosigner.xpubkey_check
          if xpub.indexOf(check, xpub.length - check.length) > 0
            @cosigner = cosigner.CK_refnum
          finishedCallback()
        ), (finished) =>
          callback @cosigner, data.has_signed_already[@cosigner]
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
      ledger.app.wallet.getExtendedPublicKey Coinkite.CK_PATH, (key) =>
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
      ledger.app.wallet._lwCard.dongle.signP2SHTransaction_async(inputs, transaction, scripts, Coinkite.CK_PATH)
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

  testDongleCompatibility: (callback) ->
    data = {
      "input_info": [
        {
          "full_sp": "m/0",
          "out_num": 1,
          "sp": "0",
          "txn": "fd11d688a755faa7523c9a42fa54bba32a78db890673a1ba3a63e315914ae8b4"
        }
      ],
      "inputs": [
        [
          "0",
          "214af8788d11cf6e3a8dd2efb00d0c3facb446273dee2cf8023e1fae8b2afcbd"
        ]
      ],
      "raw_unsigned_txn": "0100000001b4e84a9115e3633abaa1730689db782aa3bb54fa429a3c52a7fa55a788d611fd0100000000ffffffff02a0860100000000001976a914069b75ac23920928eda632a20525a027e67d040188ac50c300000000000017a914c70abc77a8bb21997a7a901b7e02d42c0c0bbf558700000000",
      "redeem_scripts": {
        "0": {
          "addr": "3NjjSXDhRtn4yunA7P8DGGTQuyPnbktcs3",
          "redeem": "522102feec7dd82317846908c20c342a02a8e8c17fb327390ce8d6669ef09a9c85904b210308aaece16e0f99b78e4beb30d8b18652af318428d6d64df26f8089010c7079f452ae"
        }
      },
    }
    inputs = data.inputs
    scripts = data.redeem_scripts
    tx = data.raw_unsigned_txn
    try
      transaction = Bitcoin.Transaction.deserialize(tx);
      ledger.app.wallet._lwCard.dongle.signP2SHTransaction_async(inputs, transaction, scripts, Coinkite.CK_PATH)
      .then (result) =>
        callback true
      .fail (error) =>
        callback false
    catch error
      callback false


  _setAuthHeaders: (endpoint) ->
    endpoint = endpoint.split('?')[0]
    ts = (new Date).toISOString()
    data = endpoint + '|' + ts
    @httpClient.setHttpHeader 'X-CK-Key', @apiKey
    @httpClient.setHttpHeader 'X-CK-Sign', CryptoJS.HmacSHA256(data, @secret).toString()
    @httpClient.setHttpHeader 'X-CK-Timestamp', ts