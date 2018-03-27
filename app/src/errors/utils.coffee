
ledger.errors ?= {}

_.extend ledger.errors,
  # @exemple Initializations
  #   ledger.error.new("an error message")
  #   ledger.error.new(NotFound, "an error message")
  new: (code, msg, payload) ->
    code = +code if _(code).isNumber()
    errorName = _.findKey(ledger.errors, (c) -> +c is code)
    defaultMessage =  ledger.errors.DefaultMessages[code] or _.str.humanize(errorName)
    [code, msg] = [0, code] if _.str.isBlank defaultMessage
    self = new Error(msg || defaultMessage)
    self.code = ledger.errors[errorName] or code
    self.name = _.invert(ledger.errors)[code]
    self.payload = payload
    self.localizedMessage = -> t(@_i18nId())
    self._i18nId = -> "common.errors.#{_.str.underscored(@name)}"
    return self

  throw: (code, msg) -> throw @new(code, msg)

  newHttp: (xhr) ->
    self = @new(ledger.errors.NetworkError, xhr.statusText)
    self._xhr = xhr
    self.getXmlHttpRequest = -> @_xhr
    self.getStatusCode = -> @getXmlHttpRequest().status
    self.getStatusText = -> @getXmlHttpRequest().statusText
    self.isDueToNoInternetConnectivity = -> @getStatusCode() is 0
    return self

  init: ->
    for k, v of ledger.errors
      if _(v).isNumber()
        ledger.errors[k] = new Number(v)
        ledger.errors[k].intValue = -> +@
        ledger.errors[k].new = (msgOrXhr = undefined) ->
          if !msgOrXhr or _(msgOrXhr).isString()
            ledger.errors.new(+this, msgOrXhr)
          else
            ledger.errors.newHttp(msgOrXhr)
