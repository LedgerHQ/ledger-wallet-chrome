# Escapes every regex characters
_.string.escapeRegExp = (string) ->
  string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")

_.string.replace = (string, pattern, substitute) ->
  string.replace new RegExp(_.string.escapeRegExp(pattern), 'g'), substitute

# Parses a URL parameters formated string to a key/value hash of parameters
# @param [String] string The string to parse
# @return [Object] A hash representing the parameters (key -> value)
_.str.parseParamList = (string) ->
  return {} unless string?
  parametersList = string.split(',')
  parameters = {}
  for parameter in parametersList
    pair = parameter.split('=')
    parameters[pair[0]] = pair[1]
  parameters

# Parses an object path to linked list of nodes. A node contains its name, type and index (if available).
# Each node has a link to the next node of the path
# @param [String] string The string to parse formated like this 'node.node[].node.node[12].node' (where 'node' is a node name)
# @return [Object] The root node
_.str.parseObjectPath = (string) ->
  matcher = /([a-z0-9]+)(?:\[([0-9]*)\])?(?:\.|$)/ig
  rootPath = {}
  path = rootPath
  while (matches = matcher.exec string)?
    path.next = {}
    path = path.next
    path.name = matches[1]
    path.type = if matches[2]? then 'array' else 'object'
    path.index = parseInt _.str.clean(matches[2])
  path.next = null
  rootPath.next
