@render = (template, params, callback) =>
  require('../views/' + template, =>
    callback(@ecoTemplates[template](params))
  )