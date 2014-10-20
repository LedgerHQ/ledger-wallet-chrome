@render = (template, params, callback) =>
  require('../views/' + template, =>
    callback(JST[template](params))
  )