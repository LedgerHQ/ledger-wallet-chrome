
ledger.api ?= {}

class AuthenticatedHttpClient extends @HttpClient

  constructor: (baseUrl) ->
    super(baseUrl)
    @_client = new HttpClient(baseUrl)

  setHttpHeader: (key, value) ->
    @_client.setHttpHeader(key, value)
    @

  jqAjax: (request) ->
    # We must use a jQuery Deferred object else the promise hierarchy becomes messy
    deferred = $.Deferred()

    # Check if we are authenticated
    if @isAuthenticated()
      # Even with an auth token the authenticated call can fail. Catch and authenticate if needed
      @_performUnsafeCall(request).then(_.bind(@_reportSuccess, @, request, deferred)).fail(_.bind(@_recoverUnsafeCallFailure, @, request, deferred))
    else
      # If not authenticated, then grab the authentication promise and perform the call after
      @_authenticateAndPerfomSafeCall(request, deferred)
    deferred

  # Performs an authentication and then a safe call (i.e. a call that cannot fail due to authentication issue)
  _authenticateAndPerfomSafeCall: (request, deferred) ->
    @_authenticate().then(_.bind(@_performSafeCall, @, request, deferred)).fail(_.bind(@_reportFailure, @, request, deferred))

  # Tries to recover from an usafe call (i.e. a call performed without being sure that the current auth token is valid)
  _recoverUnsafeCallFailure: (request, deferred, error) ->
    [jqXHR, textStatus, errorThrown] = error
    if jqXHR.statusCode() is 403
      @_authenticateAndPerfomSafeCall(request, deferred)
    else
      @_reportFailure(request, deferred, error)

  # Performs a safe call (i.e. a call performed rigth after an authentication)
  _performSafeCall: (request, deferred) ->
    @_client.setHttpHeader('X-LedgerWallet-AuthToken', @_authToken) if @_authToken?
    r = _(request).omit('success', 'error', 'complete')
    @_client
    .jqAjax(r)
    .done (data, textStatus, jqXHR) => @_reportSuccess(request, deferred, [data, textStatus, jqXHR])
    .fail (jqXHR, textStatus, errorThrown) => @_reportFailure(request, deferred, [jqXHR, textStatus, errorThrown])


  _performUnsafeCall: (request) ->
    @_client.setHttpHeader('X-LedgerWallet-AuthToken', @_authToken) if @_authToken?
    deferred = jQuery.Deferred()
    unsafeRequest = _(request).omit('success', 'error', 'complete')
    @_client
      .jqAjax(unsafeRequest)
      .done (data, textStatus, jqXHR) -> deferred.resolve([data, textStatus, jqXHR])
      .fail (jqXHR, textStatus, errorThrown) -> deferred.reject([jqXHR, textStatus, errorThrown])
    deferred

  # Properly reports HTTP failure
  _reportFailure: (request, deferred, error) ->
    [jqXHR, textStatus, errorThrown] = error
    deferred.reject(jqXHR, textStatus, errorThrown)
    request?.error?(jqXHR, textStatus, errorThrown)
    request?.complete?(jqXHR, textStatus)

  _reportSuccess: (request, deferred, success) ->
    [data, statusText, jqXHR] = success
    deferred.resolve(data, statusText, jqXHR)
    request?.success?(data, statusText, jqXHR)
    request?.complete?(jqXHR, statusText)

  isAuthenticated: -> if @_authToken? then yes else no

  _authenticate: () ->
    return @_deferredAuthentication if @_deferredAuthentication?
    @_deferredAuthentication = jQuery.Deferred()
    @_performAuthenticate(@_deferredAuthentication)
    @_deferredAuthentication

  _performAuthenticate: (deferred) ->
    bitidAddress = null
    deferred.retryNumber ?= 3
    CompletionClosure.defer(ledger.app.wallet.getBitIdAddress, ledger.app.wallet).jq()
    .fail (error) => deferred.reject([null, "Unable to get bitId address", error])
    .then (address) =>
      bitidAddress = address
      @_client.jqAjax type: "GET", url: "bitid/authenticate/#{bitidAddress}", dataType: 'json'
    .fail (jqXHR, statusText, errorThrown) =>
      if deferred.retryNumber-- > 0 then @_performAuthenticate(deferred) else deferred.reject([jqXHR, statusText, errorThrown])
    .then (data) => CompletionClosure.defer(ledger.app.wallet.signMessageWithBitId, ledger.app.wallet, "0'/0/0xb11e", data['message']).jq()
    .fail () => deferred.reject([null, "Unable to sign message", error])
    .then (signature) => @_client.jqAjax(type: "POST", url: 'bitid/authenticate', data: {address: bitidAddress, signature: signature}, contentType: 'application/json', dataType: 'json')
    .fail () =>  if deferred.retryNumber-- > 0 then @_performAuthenticate(deferred) else deferred.reject([jqXHR, statusText, errorThrown])
    .then (data) =>
      @_authToken = data['token']
      ledger.app.emit 'wallet:authenticated'
      deferred.resolve()

  getAuthToken: (callback = null) ->
    completion = new CompletionClosure(callback)
    if @isAuthenticated()
      completion.success(@_authToken)
    else
      @_authenticate().then(-> completion.success(@_authToken)).fail((ex) -> completion.failure(ex))
    completion.readonly()

  getAuthTokenSync: -> @_authToken


  @instance: (baseUrl = ledger.config.restClient.baseUrl) -> @_instance ?= new @(baseUrl)

_.extend ledger.api,

  authenticated: (baseUrl = ledger.config.restClient.baseUrl) -> AuthenticatedHttpClient.instance(baseUrl)