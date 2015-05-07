
@ledger ?= {}
@ledger.url =
  # Parses a url using a '<a>' DOM element. This method returns a DOM Node (the parser) with a method params to
  # to retrieve the parsed search part of the URL.
  # @param [String] str The url string to parse (i.e. 'www.ledger.co')
  # @return [Node] The URL parser with a special method `params`

  # protocol: parser.protocol,
  # host: parser.host,
  # hostname: parser.hostname,
  # port: parser.port,
  # pathname: parser.pathname,
  # search: parser.search,
  # searchObject: searchObject,
  # hash: parser.hash
  parseAsUrl: (str) ->
    parser = document.createElement('a')
    parser.href = str
    parser.params = ->
      return {} if parser.search == ""
      params = parser.search.substring(1)
      _.chain(params.split('&')).map (params) ->
        p = params.split '='
        [decodeURIComponent(p[0]), ledger.url.parseValue(p[1])]
      .object().value()
    parser

  parseValue: (str) ->
    val = decodeURIComponent(str)
    if val is "true"
      true
    else if val is "false"
      false
    else
      val
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

  # Crates a URL given a specific path and parameters. Parameters are URL encoded in the returned string.
  # @param [String] url The URL path
  # @param [Array] params The URL parameters to be encoded
  # @return [String] The newly created URL
  createUrlWithParams: (url, params) ->
    return url if not params? or _.isEmpty(params)
    url = url + '?'
    for name, value of params
      url += encodeURIComponent(name) + '=' + encodeURIComponent(value) + "&"
    url.slice(0, -1)

String::parseAsUrl = () ->
  ledger.url.parseAsUrl(@)