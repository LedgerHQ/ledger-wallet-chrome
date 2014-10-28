
@ledger ?= {}
@ledger.url =
  parseAsUrl: (str) ->
    parser = document.createElement('a')
    parser.href = str
    parser.params = ->
      params = parser.search.substring(1)
      _.chain(params.split('&')).map (params) ->
        p = params.split '='
        [p[0], decodeURIComponent(p[1])]
      .object().value()
    parser

  createRelativeUrlWithFragmentedUrl: (url, fragmentedUrl) ->
    parsedUrl = ledger.url.parseAsUrl url
    parsedFragmentedUrl = ledger.url.parseAsUrl fragmentedUrl
    pathname = parsedUrl.pathname
    hash = if parsedFragmentedUrl.hash.length > 0 then parsedFragmentedUrl.hash else parsedUrl.hash
    search = if parsedFragmentedUrl.search.length > 0 then parsedFragmentedUrl.search else parsedUrl.search
    pathname + search + hash

  parseAction: (hash) ->
    actionName = _.str.splice(hash, 0, 1)
    matches = (/([a-zA-Z0-9-_-]+)\((.*)\)/i).exec(actionName)
    [__, actionName, parameters] = matches if matches
    parameters = _.parseParamList parameters
    [actionName, parameters]

String::parseAsUrl = () ->
  ledger.url.parseAsUrl(@)