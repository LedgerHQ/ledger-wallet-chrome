_.string.escapeRegExp = (string) ->
  string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")

_.string.replace = (string, pattern, substitute) ->
  string.replace new RegExp(_.string.escapeRegExp(pattern), 'g'), substitute

_.str.parseParamList = (string) ->
  return {} unless string?
  parametersList = string.split(',')
  parameters = {}
  for parameter in parametersList
    pair = parameter.split('=')
    parameters[pair[0]] = pair[1]
  parameters

_.str.parseObjectPath = (string) ->
  matcher = /([a-z0-9]+)(?:\[([0-9]*)\]\.)?\.?/i
  rootPath = {}
  path = rootPath
  while string.length > 0
    matches = matcher.exec string
    if matches?
      path.name = matches[1]
      path.type = if matches[2]? then 'array' else 'object'
      path.index = parseInt _.str.clean(matches[2])
      string = string.substr matches[0].length
      path.next = if string.length > 0 then {} else null
      path = path.next
    else
      string = ''
  rootPath
