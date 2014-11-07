
@ledger ?= {}
@ledger.url =
  # Parses a url using a '<a>' DOM element. This method returns a DOM Node (the parser) with a method params to
  # to retrieve the parsed search part of the URL.
  # @param [String] str The url string to parse (i.e. 'www.ledger.co')
  # @return [Node] The URL parser with a special method `params`
  parseAsUrl: (str) ->
    parser = document.createElement('a')
    parser.href = str
    parser.params = ->
      return {} if parser.search == ""
      params = parser.search.substring(1)
      _.chain(params.split('&')).map (params) ->
        p = params.split '='
        [p[0], decodeURIComponent(p[1])]
      .object().value()
    parser

  #
  createRelativeUrlWithFragmentedUrl: (url, fragmentedUrl) ->
    parsedUrl = ledger.url.parseAsUrl url
    parsedFragmentedUrl = ledger.url.parseAsUrl fragmentedUrl
    pathname = parsedUrl.pathname
    hash = if parsedFragmentedUrl.hash.length > 0 then parsedFragmentedUrl.hash else parsedUrl.hash
    search = if parsedFragmentedUrl.search.length > 0 then parsedFragmentedUrl.search else parsedUrl.search
    pathname + search + hash

  # Parses a URL hash (i.e. '#actionName(param1=ledger)') to a tuple of [actionName, parameters] where `actionName` is the
  # part of the hash before the first parenthesis and parameters is dictionary with parameter names and their values.
  # @param [String] hash The hash part of an URL (i.e. '#actionName(param1=ledger)').
  # @return [Array] A tuple with [actionName, parameters].
  parseAction: (hash) ->
    actionName = _.str.splice(hash, 0, 1)
    matches = (/([a-zA-Z0-9-_-]+)\((.*)\)/i).exec(actionName)
    [__, actionName, parameters] = matches if matches
    parameters = _.str.parseParamList parameters
    [actionName, parameters]

  createUrlWithParams: (url, params) ->
    return url unless params?
    url = url + '?'
    first = yes
    for key, value of params
      continue if not value? or (_(value).isString() and value.length == 0)
      url += '&' if not first
      url += encodeURIComponent(key) + '=' + encodeURIComponent(value)
      first = no
    url

String::parseAsUrl = () ->
  ledger.url.parseAsUrl(@)