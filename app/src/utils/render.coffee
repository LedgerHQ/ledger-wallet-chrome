helpers =
  url: (url, params) ->
    ledger.url.createUrlWithParams(url, params)

@render = (template, params, callback) =>
  template = template.substr(1) if _.string.startsWith(template, '/')
  if JST?[template]?
    context = _.extend(params, helpers)
    _.defer => callback?(JST[template](context))
  else
    require('../views/' + template, =>
      context = _.extend(params, helpers)
      callback(JST[template](context))
    )