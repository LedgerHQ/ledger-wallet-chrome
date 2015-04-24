@ledger ?= {}
@ledger.utils ?= {}

apduFilter = [
  {test: 'e0220000', length: 0}
  {test: 'd02600001104', length: 0}
  {test: 'e020', length: 4}
]

class ledger.utils.ApduLogger extends ledger.utils.Logger

  _storeLog: (msg, msgType) ->
    if msg.match(/(=>)/)?
      apdu = msg.substr(if msg.match(/(=> [0-9a-f]{14})/)? then 17 else 3)
      result = _.find(apduFilter, ((item) -> apdu.startsWith(item.test)))

      if result?.test?
        msg = _.str.rpad(msg.substr(0, msg.indexOf(result.test) + result.test.length), msg.length, 'x')
        @_obfuscatedApdu = result.length
      else if msg.startsWith('=>') and @_obfuscatedApdu? and @_obfuscatedApdu > 0
        msg = _.str.rpad("=> ", msg.length, 'x')
        @_obfuscatedApdu -= 1
    super msg, msgType