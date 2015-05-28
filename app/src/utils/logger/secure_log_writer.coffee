
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.SecureLogWriter extends @ledger.utils.LogWriter

  constructor: ( key, bitIdAddress, daysMax = 2, fsmode  = PERSISTENT) ->
    @_bitIdAddress = bitIdAddress
    @_key = key
    @_aes = new ledger.crypto.AES(@_key)
    super @_daysMax, fsmode


  write: (msg) ->
    msg = @_aes.encrypt(msg)
    super msg



  ###
   Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
    @_filename = "secure_#{@_bitIdAddress}_#{ moment().format('YYYY_MM_DD') }.log"
