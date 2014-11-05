
_.mixin

  # Tests if the instance of an object is a subtype of a given class. (Note that this only works for coffeescript classes)
  # @param [Object] An instance of an object
  # @param [Function] The class to test
  # @return [Boolean] true if the object is a subtype of class otherwise false
  isKindOf: (object, clazz) ->
    while clazz?.constructor?
      return yes if object.constructor == clazz
      clazz = clazz.constructor.__super__
    no

  # Get the name of the given instance (Note that this only works for coffeescript class objects)
  # @return [String] The class name or null if no class name was found
  getClassName: (object) -> object?.constructor?.name

  # Get the class of the given instance (Note that this only works for coffeescript class objects)
  # @return [Function] The object class or null if no class name was found
  getClass: (object) -> object?.constructor