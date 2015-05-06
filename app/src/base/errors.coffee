
ledger.errors ?= {}

_.extend ledger.errors,
  StandardError: 0

  # Generic errors
  UnknownError: 100
  InvalidArgument: 101
  NotFound: 102
  NetworkError: 103
  AuthenticationFailed: 104
  InconsistentState: 105
  OperationCanceledError: 106
  PermissionDenied: 107
  TimeoutError: 108

  # Dongle errors
  NotSupportedDongle: 200
  DongleNotBlank: 201
  DongleAlreadyUnlock: 202
  WrongPinCode: 203
  DongleLocked: 204
  BlankDongle: 205
  DongleNotCertified: 206
  CommunicationError: 207

  # Wallet errors
  NotEnoughFunds: 300
  SignatureError: 301
  TransactionNotInitialized: 302
  DustTransaction: 303

  # Firmware update errors
  UnableToRetrieveVersion: 400
  InvalidSeedSize: 401
  InvalidSeedFormat: 402
  FailedToInitOs: 404
  CommunicationError: 405
  UnsupportedFirmware: 406
  ErrorDongleMayHaveASeed: 407
  ErrorDueToCardPersonalization: 408
  HigherVersion: 409

  # M2FA errors
  TransactionCancelled: "secure_screen_cancelled_transaction"
  InvalidResult: "secure_screen_invalid_pin"

  # I/O Errors
  WriteError: 500

  DefaultMessages:
    0: "StandardError"

    100: "Unknow error"
    101: "Invalid argument"
    102: "Not found"
    103: "Network error"
    104: "Authentication failed"

    200: "Not supported dongle"
    201: "Dongle not blank"
    202: "Dongle already unlock"
    203: "Wrong PIN code"
    204: "Dongle locked"
    205: "Blank dongle"
    206: "Dongle not certified"
    207: "Unable to get BitId address"

    300: "Not enough funds"
    301: "Signature error"
    302: "Dust transaction"
  
  # @exemple Initializations
  #   ledger.error.new("an error message")
  #   ledger.error.new(NotFound, "an error message")
  new: (code, msg) -> 
    defaultMessage =  ledger.errors.DefaultMessages[code] or _.str.humanize(_.findKey(ledger.errors, (c) -> c is code))
    [code, msg] = [0, code] if _.str.isBlank defaultMessage
    self = new Error(msg || defaultMessage)
    self.code = code
    self.name = _.invert(ledger.errors)[code]
    self.localizedMessage = -> t(@_i18nId())
    self._i18nId = -> "common.errors.#{_.underscore(@name)}"
    return self

  throw: (code, msg) -> throw @new(code, msg)

  newHttp: (xhr) ->
    self = @new(ledger.errors.NetworkError, xhr.statusText)
    self._xhr = xhr
    self.getXmlHttpRequest = -> @_xhr
    self.getStatusCode = -> @getXmlHttpRequest().status
    self.getStatusText = -> @getXmlHttpRequest().statusText
    self.isDueToNoInternetConnectivity = -> @getStatusCode() is 0
    return self
