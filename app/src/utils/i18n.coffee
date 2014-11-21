# Translate a message id to a localized text
#
# @param [String] messageId Unique identifier of the message
# @return [String] localized message
#
@t = (messageId) ->
  message = chrome.i18n.getMessage(_.string.replace(messageId, '.', '_'))
  return message if message? and message.length > 0
  return messageId
