
class MockLocalStorage

  originalChromeStore: undefined

  constructor: ->
    @_store = {}

  clear: ->
    @_store = {}


  get: (keys, callback) ->
    keys = [keys] if _(keys).isString()
    if _(keys).isArray()
      callback?(_.pick(@_store, keys))
    else if _(keys).isObject()
      callback?(_.defaults(_.pick(_.keys(keys)), keys))
    else
      callback?(_.clone(@_store))


  getBytesInUse: (keys, callback) ->
    size  = 0
    keys  = [keys]
    check = (valToCheck) ->
      if typeof valToCheck isnt 'object'
        determine null, valToCheck
      else
        # Extract all values of obj
        for key of valToCheck
          determine null, valToCheck[key]
    determine = (key, val) =>
      value = if val? then val else @_store[key]
      switch (typeof value)
        when 'boolean' then size += 4
        when 'number' then size += 8
        when 'string' then size += 2 * value.length
        when 'object'
          for k, i of value
            check @_store[keys][k]
    for key in keys
      determine key
    callback?()
    return size


  set: (obj, callback) ->
    _.extend @_store, obj
    callback?()


  remove: (key, callback) ->
    @_store = _(@_store).omit(key)
    callback?()


instance = new MockLocalStorage()
ledger.specs.storage ?= {}
ledger.specs.storage.inject = ->
  instance.originalChromeStore = chrome.storage.local
  chrome.storage.local         = instance

ledger.specs.storage.restore = (callback) ->
  chrome.storage.local = instance.originalChromeStore
  callback?()

