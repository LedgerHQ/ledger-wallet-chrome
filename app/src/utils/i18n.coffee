# Translate a message id to a localized text
#
# @param [String] messageId Unique identifier of the message
# @return [String] localized message
#
@t = (messageId) ->
  chrome.i18n.getMessage(messageId.replace('.', '_'))
