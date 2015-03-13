
ledger.errors ?= {}

_.extend ledger.errors,
  # Generic errors
  UnknownError: 100
  InvalidArgument: 101
  NotFound: 102
  NetworkError: 103
  AuthenticationFailed: 104

  # Dongle errors
  NotSupportedDongle: 200
  DongleNotBlank: 201
  DongleAlreadyUnlock: 202
  WrongPinCode: 203
  DongleLocked: 204
  UnableToGetBitIdAddress: 205

  # Wallet errors
  NotEnoughFunds: 300
  SignatureError: 301

  DefaultMessages:
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
    205: "Unable to get BitId address"

    300: "Not enough funds"
    301: "Signature error"

  create: (code, title, error) -> code: code, title: title, error: error
  throw: (code, message) -> throw new ledger.StandardError(code, message)

class ledger.StandardError extends Error
  #
  constructor: (@code=100, message=undefined) ->
    super(message || ledger.errors.DefaultMessages[@code])

  name: ->
    _.invert(ledger.errors)[@code]
