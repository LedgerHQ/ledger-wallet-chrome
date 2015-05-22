
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.SecureLogReader extends @ledger.utils.LogReader

  constructor: (@_daysMax=2, @key='secureLog') ->
    @_aes = new ledger.crypto.AES(@key)
    super @_daysMax


  read: (callback) ->
    deciphLines = []
    super (file) =>
      lines = _.compact file.split('\n')
      for line in lines
        try
          deciphLines.push @_aes.decrypt line
        catch e
          l e
      callback? deciphLines


  _isFileOfMine: (name) ->
    regex = /^secure_[0-9a-zA-Z]{25,35}_[\d]{4}_[\d]{2}_[\d]{2}\.log$/
    if name.match(regex)? then true else false


  ###
   Set file name with bitIdAdress and date of the day
  ###
  _setFileName: ->
    ledger.bitcoin.bitid.getAddress (address) =>
      bitIdAddress = address.bitcoinAddress.toString(ASCII)
      @_filename = "secure_#{bitIdAddress}_#{ moment().format('YYYY_MM_DD') }.log"
