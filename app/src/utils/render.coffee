@render = (template, params, callback) =>
  template = template.substr(1) if _.string.startsWith(template, '/')
  require('../views/' + template, =>
    callback(JST[template](params))
  )