_.string.escapeRegExp = (string) ->
  string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")

_.string.replace = (string, pattern, substitute) ->
  string.replace new RegExp(_.string.escapeRegExp(pattern), 'g'), substitute