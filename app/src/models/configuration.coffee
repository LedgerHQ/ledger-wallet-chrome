class @Configuration extends @Model
  do @init

  @_instance: undefined

  @getInstance: (context) ->
    unless @_instance?
      @_instance = @findOrCreate({id: 1}, context)
    @_instance

  setCurrentApplicationVersion: (version) -> @set('__app_version', version).save()

  getCurrentApplicationVersion: () -> @get('__app_version')