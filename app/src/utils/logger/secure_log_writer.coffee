
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.SecureLogWriter extends @ledger.utils.LogWriter

  constructor: (@_daysMax=2, @key='secureLog') ->
    @_aes = new ledger.crypto.AES(@key)
    super @_daysMax



  write: (msg) ->
    msg = @_aes.encrypt(msg)
    super msg


  ###
   Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
    ledger.bitcoin.bitid.getAddress (address) =>
      bitIdAddress = address.bitcoinAddress.toString(ASCII)
      @_filename = "secure_#{bitIdAddress}_#{ moment().format('YYYY_MM_DD') }.log"