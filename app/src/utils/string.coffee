_.string.escapeRegExp = (string) ->
  string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")

_.string.replace = (string, pattern, substitute) ->
  string.replace new RegExp(_.string.escapeRegExp(pattern), 'g'), substitute

_.parseParamList = (string) ->
  return {} unless string?
  parametersList = string.split(',')
  parameters = {}
  for parameter in parametersList
    pair = parameter.split('=')
    parameters[pair[0]] = pair[1]
  parameters