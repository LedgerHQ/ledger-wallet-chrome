
@ledger ?= {}
@ledger.utils ?= {}

class @ledger.utils.SecureLogReader extends @ledger.utils.LogReader

  constructor: (key, bitIdAddress, daysMax=2, fsmode=PERSISTENT) ->
    @_bitIdAddress = bitIdAddress
    @_key = key
    @_aes = new ledger.crypto.AES(@_key)
    super @_daysMax, fsmode


  read: (callback) ->
    deciphLines = []
    super (lines) =>
      for line in lines
        try
          deciphLines.push @_aes.decrypt line
        catch e
          l e
      callback? deciphLines


  _isFileOfMine: (name) ->
    regex = "secure_#{@_bitIdAddress}_[\\d]{4}_[\\d]{2}_[\\d]{2}\\.log"
    name.match new RegExp(regex)