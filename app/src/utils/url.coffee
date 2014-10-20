
@ledger ?= {}
@ledger.url =
  parseAsUrl: (str) ->
    parser = document.createElement('a')
    parser.href = str
    parser

  createRelativeUrlWithFragmentedUrl: (url, fragmentedUrl) ->
    parsedUrl = ledger.url.parseAsUrl url
    parsedFragmentedUrl = ledger.url.parseAsUrl fragmentedUrl
    pathname = parsedUrl.pathname
    hash = if parsedFragmentedUrl.hash.length > 0 then parsedFragmentedUrl.hash else parsedUrl.hash
    search = if parsedFragmentedUrl.search.length > 0 then parsedFragmentedUrl.search else parsedUrl.search
    pathname + hash + search



String::parseAsUrl = () ->
  ledger.url.parseAsUrl(@)