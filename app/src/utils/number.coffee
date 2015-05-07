@ledger.number ?= {}

_.extend @ledger.number,

  intArray2a: (hex) ->
    str = ''
    str += String.fromCharCode(hex[i]) for i in [0..hex.length - 1]
    str

  hex2a: (hex) ->
    str = ''
    str += String.fromCharCode(parseInt(hex.substr(i, 2), 16)) for i in [0..hex.length - 1]
    str

  a2hex: (str) ->
    charset = "0123456789abcdef";
    out = ''
    for i in [0..str.length - 1]
      charCode = str.charCodeAt(i)
      out += (charset[Math.floor(charCode / 16)] + charset[charCode % 16])
    out

  getLocaleDecimalSeparator: (locale) ->
    number = 0.5
    separator = number.toLocaleString(locale).charAt(1)
    hasSeparator = isNaN(parseInt(separator))
    if hasSeparator then separator else ''

  getLocaleThousandSeparator: (locale) ->
    number = 1000
    separator = number.toLocaleString(locale).charAt(1)
    hasSeparator = isNaN(parseInt(separator))
    if hasSeparator then separator else ''