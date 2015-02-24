
ledger.api ?= {}

class AuthenticatedHttpClient extends @HttpClient

  constructor: ->
    @_client = new HttpClient()

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
    @_authenticate().then(_.bind(@_performAuthenticatedCall, @, request, deferred)).fail(_.bind(@_reportFailure, @, request, deferred))

  # Tries to recover from an usafe call (i.e. a call performed without being sure that the current auth token is valid)
  _recoverUnsafeCallFailure: (request, deferred, error) ->
    [jqXHR, textStatus, errorThrown] = error
    if jqXHR.statusCode() is 400
      @_authenticateAndPerfomSafeCall(request, deferred)
    else
      @_reportAuthencationFailure(request, deferred, error)

  # Performs a safe call (i.e. a call performed rigth after an authentication)
  _performSafeCall: (request, deferred) ->
    @_client
    .do(request)
    .done (data, textStatus, jqXHR) => @_reportSuccess(request, deferred, [data, textStatus, jqXHR])
    .fail (jqXHR, textStatus, errorThrown) => @_reportFailure(request, deferred, [jqXHR, textStatus, errorThrown])


  _performUnsafeCall: (request) ->
    deferred = jQuery.Deferred()
    unsafeRequest = _(request).omit('success', 'error', 'complete')
    @_client
      .do(unsafeRequest)
      .done (data, textStatus, jqXHR) -> deferred.resolve([data, textStatus, jqXHR])
      .fail (jqXHR, textStatus, errorThrown) -> deferred.reject([jqXHR, textStatus, errorThrown])
    deferred

  # Properly reports HTTP failure
  _reportFailure: (request, deferred, error) ->
    [jqXHR, textStatus, errorThrown] = error
    deferred.reject(jqXHR, textStatus, errorThrown)
    request?.error(jqXHR, textStatus, errorThrown)
    request?.complete(jqXHR, textStatus)

  _reportSuccess: (request, deferred, success) ->
    [data, statusText, jqXHR] = success
    deferred.resolve(data, statusText, jqXHR)
    request?.success(data, statusText, jqXHR)
    request?.complete(jqXHR, statusText)

  isAuthenticated: -> if @_authToken? then yes else no

  _authenticate: () ->
    return @_deferredAuthentication if @_deferredAuthentication?
    @_deferredAuthentication = jQuery.Deferred()


    @_deferredAuthentication


  @instance: -> @_instance ?= new @

_.extend ledger.api,

  authenticated: -> AuthenticatedHttpClient.instance()