
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

  # Dongle errors
  NotSupportedDongle: 200
  DongleNotBlank: 201
  DongleAlreadyUnlock: 202
  WrongPinCode: 203
  DongleLocked: 204
  UnableToGetBitIdAddress: 205
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

  # I/O Errors
  WriteError: 500


  create: (code, title, error) -> code: code, title: title, error: error
  throw: (code, message) -> throw new ledger.StandardError(code, message)

class ledger.StandardError extends Error
  # @exemple Initializations
  #   new ledger.StandardError(ledger.errors.NotFound[, "an error message"])
  constructor: (@code, @message=undefined) ->
    super(@message)

  name: ->
    _.invert(ledger.errors)[@code]
