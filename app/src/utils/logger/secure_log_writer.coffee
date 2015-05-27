
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.SecureLogWriter extends @ledger.utils.LogWriter

  constructor: (daysMax=2, key='secureLog', bitIdAddress='1YnMY5FGugkuzJwdmbue9EtfsAFpQXcZy') ->
    @_bitIdAddress = bitIdAddress
    @_daysMax = daysMax
    @_key = key
    @_aes = new ledger.crypto.AES(@_key)
    super @_daysMax


  write: (msg) ->
    msg = @_aes.encrypt(msg)
    super msg



  ###
   Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
    @_filename = "secure_#{@_bitIdAddress}_#{ moment().format('YYYY_MM_DD') }.log"
