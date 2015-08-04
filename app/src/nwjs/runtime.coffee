return unless global?.require?


((@chrome ||= {}).runtime ||= {}).sendMessage = (extensionId, message, options, responseCallback) ->

