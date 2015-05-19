
class MockLocalStorage

  originalChromeStore: undefined
  store: {}

  clear: ->
    @store = {}


  get: (key, callback) ->
    callback?(@store[key])


  getBytesInUse: (keys, callback) ->
    size  = 0
    keys  = [keys]
    check = (valToCheck) ->
      if typeof valToCheck isnt 'object'
        l valToCheck
        determine null, valToCheck
      else
        # Extract all values of obj
        for key of valToCheck
          determine null, valToCheck[key]
    determine = (key, val) =>
      value = if val? then val else @store[key]
      l 'value', value
      switch (typeof value)
        when 'boolean' then size += 4
        when 'number' then size += 8
        when 'string' then size += 2 * value.length
        when 'object'
          for k, i of value
            check @store[keys][k]
    for key in keys
      determine key
    callback?()
    return size


  set: (obj, callback) ->
    _.extend @store, obj
    callback?()


  remove: (key, callback) ->
    delete @store[key]
    callback?()


instance = new MockLocalStorage()
ledger.specs.storage ?= {}
ledger.specs.storage.inject = ->
  instance.originalChromeStore = chrome.storage.local
  chrome.storage.local         = instance

ledger.specs.storage.restore = (callback) ->
  chrome.storage.local = instance.originalChromeStore
  callback?()

