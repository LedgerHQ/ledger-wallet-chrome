_.mixin

  toJson: (data) ->
    if _(data).isObject() and !_(data).isArray()
      data = _(data).chain().pairs().sort().object().value()
      '{' + (JSON.stringify(key) + ':' + _(value).toJson() for key, value of data).join(',') + '}'
    else
      JSON.stringify(data)