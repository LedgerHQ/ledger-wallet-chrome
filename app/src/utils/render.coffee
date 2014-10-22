@render = (template, params, callback) =>
  console.log(template)
  require('../views' + template, =>
    callback(JST[template](params))
  )