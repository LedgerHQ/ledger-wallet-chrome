Object::className = () ->
  if @.constructor?.name?
    return @.constructor.name
  return typeof @