
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

  # Dongle errors
  NotSupportedDongle: 200
  DongleNotBlank: 201
  DongleAlreadyUnlock: 202
  WrongPinCode: 203
  DongleLocked: 204
  BlankDongle: 205
  DongleNotCertified: 206
  UnableToGetBitIdAddress: 207

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
#   new ledger.StdError("an error message")
#   new ledger.StdError(NotFound, "an error message")
ledger.StdError = (code, msg)->
  defaultMessage = ledger.errors.DefaultMessages[code]
  [code, msg] = [0, code] if defaultMessage == undefined
  self = new Error(msg || defaultMessage)
  self.code = code
  self.name = _.invert(ledger.errors)[code]
  self.__proto__ = ledger.StdError.prototype
  return self
ledger.StdError.prototype.__proto__= Error.prototype

ledger.StdError.prototype.localizedMessage = ->
    t(@_i18nId())

ledger.StdError.prototype._i18nId = ->
    "common.errors.#{_.underscore(@name)}"

ledger.throw = (code, message) => throw ledger.StdError(code, message)
