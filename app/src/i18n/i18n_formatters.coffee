_.extend ledger.i18n,

  ###
    Set the locale for Moment.js
  ###
  setMomentLocale: -> moment.locale(@favLocale.memoryValue)


  ###
    Translate a message id to a localized text
    @param [String] messageId Unique identifier of the message
    @return [String] localized message
  ###
  t: (messageId) ->
    messageId = _.string.replace(messageId, '.', '_')
    key = @translations[@favLang.memoryValue][messageId] or @translations['en'][messageId]
    if not key? or not key['message']?
      return messageId
    res = @translations[@favLang.memoryValue][messageId]['message']
    return res if res? and res.length > 0
    return messageId


  ###
    Formats amounts with currency symbol
    @param [String] amount The amount to format
    @param [String] currency The currency
    @return [String] The formatted amount
  ###
  formatAmount: (amount, currency) ->
    locale = _.str.replace(@favLocale.memoryValue, '_', '-')
    if amount?
      testValue = (amount).toLocaleString(locale, {style: "currency", currency: currency, currencyDisplay: "code", minimumFractionDigits: 2})
      value = (amount).toLocaleString(locale, {minimumFractionDigits: 2})
    else
      testValue = (0).toLocaleString(locale, {style: "currency", currency: currency, currencyDisplay: "code", minimumFractionDigits: 2})
      value = '--'
    if _.isNaN(parseInt(testValue.charAt(0))) then value = currency + ' ' + value else value = value + ' ' + currency
    value


  ###
    Formats number
  ###
  formatNumber: (number) -> number.toLocaleString(_.str.replace(@favLocale.memoryValue, '_', '-'), {minimumFractionDigits: 2})


  ###
    Formats date and time
    @param [Date] dateTime The date and time to format
    @return [String] The formatted date and time
  ###
  formatDateTime: (dateTime) -> moment(dateTime).format @t 'common.date_time_format'


  ###
    Formats date
    @param [Date] date The date to format
    @return [String] The formatted date
  ###
  formatDate: (date) -> moment(date).format @t 'common.date_format'


  ###
    Formats time
    @param [Date] time The time to format
    @return [String] The formatted time
  ###
  formatTime: (time) -> moment(time).format @t 'common.time_format'


  ###
    getAllLocales
  ###
  getAllLocales: (callback) -> $.getJSON '../src/i18n/regions.json', (data) -> callback?(data)


@t = ledger.i18n.t.bind(ledger.i18n)
