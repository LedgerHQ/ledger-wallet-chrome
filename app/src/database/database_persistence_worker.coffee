
@ledger = {}

try
  importScripts(
    '../utils/logger.js'
    '../../libs/btchip/lib/q.js'
    '../../libs/underscore-min.js'
  )
catch er
  console.error er
  return

IndexedDb = @indexedDB

db = null
databaseName = null
cipher = null
l = console.log.bind(console)
e = console.error.bind(console)

assertDbIsPrepared = ->
  throw new Error("Database not prepared") unless db?

encryptedDataBytesCounter = 0

MEMORY_WARNING = 5 * 1024 * 1024 # 5 Mo

resetCounter = () -> encryptedDataBytesCounter = 0

updateCounter = (data) ->
  encryptedDataBytesCounter += data.length * 8 # Each item represents 4 words of data
  data

storify = (obj) ->
  storifyObject = (obj, keys, index = 0) ->
    return Q(obj) if index >= keys.length
    key = keys[index]
    return storifyObject(obj, keys, index + 1) if key is '$loki'
    value = obj[key]
    storifyValue = (value) ->
      if _.isArray(value)
        storifyArray = (array, index = 0) ->
          return Q(array) if index >= array.length
          storifyValue(array[index]).then (data) ->
            array[index] = data
            storifyArray(array, index + 1)
        storifyArray(value).then (array) ->
          obj[key] = array
      else if _.isObject(value)
        storifyObject(value, _.keys(value)).then (result) ->
          obj[key] = result
      else
        cipher.encrypt(JSON.stringify(value)).then (data) ->
          obj[key] = data
    storifyValue(value).then ->
      storifyObject(obj, keys, index + 1)
  storifyObject(obj, _(obj).keys())


unstorify = (obj) ->
  for key, value of obj
    continue if key is '$loki' # Skip the index
    storifyValue = (value) ->
      _value = _(value)
      if _value.isArray()
        # Iterate
        storifyValue(item) for item, index in value
      else if _value.isObject()
        storify(value)
      else
        JSON.parse(cipher.rawDecrypt(value))
    obj[key] = storifyValue(value)
  obj


flushChanges = (changes) ->
  d = Q.defer()
  transaction = db.transaction(db.objectStoreNames, 'readwrite')
  for change, index in changes
    store = transaction.objectStore(change.name)
    if change.operation is "D"
      # Delete document
      store.delete(change.id)
    else
      # Insert/Update
      store.put change.obj
  transaction.oncomplete = -> d.resolve()
  transaction.onerror = (er) ->
    e er
    d.reject("Save error")
  d.promise

storeChanges = (changes, index = 0, encryptedChanges = []) ->
  return Q() if index >= changes.length
  d = Q.defer()
  Q.fcall ->
    if encryptedDataBytesCounter > MEMORY_WARNING or index >= changes.length
      flushChanges(encryptedChanges)
  .then ->
    return if index >= changes.length
    change = changes[index]
    changes[index] = null
    Q.fcall ->
      if change.operation is 'D'
        change.id = change.obj['$loki']
        change.obj = null
      else
        storify(change.obj).then (cryptedObj) ->
          change.obj = cryptedObj
    .then ->
      storeChanges(changes, index + 1, encryptedChanges.concat(change))
  d.promise


  ###
   transaction = db.transaction(db.objectStoreNames, 'readwrite')
    for change, index in changes
      store = transaction.objectStore(change.name)
      if change.operation is "D"
        # Delete document
        store.delete storify(change.obj['$loki'])
      else
        # Insert/Update
        store.put storify(change.obj)
      l "Warning too much data ", encryptedDataBytesCounter / (1024 * 1024), " #{index} / #{changes.length}" if encryptedDataBytesCounter >= MEMORY_WARNING
    transaction.oncomplete = -> d.resolve()
    transaction.onerror = (er) ->
      e er
      d.reject("Save error")

  ###

EventHandler =

  prepare: ({dbName, password}) ->
    d = Q.defer()
    databaseName = dbName
    cipher = new Cipher(password)
    request = IndexedDb.open(dbName)
    request.onupgradeneeded = (e) ->
      # Nothing to do for now
      db = e.target.result
      unless db.objectStoreNames.contains("__collections")
        db.createObjectStore("__collections", keyPath: 'name')

    request.onsuccess = (e) ->
      db = e.target.result
      d.resolve()

    request.onerror = (e) -> d.reject(e)

    d.promise

  changes: ({changes}) ->
    do assertDbIsPrepared
    do resetCounter
    storeChanges(changes)

  serialize: ({}) ->
    do assertDbIsPrepared
    d = Q.defer()
    l "Serialize"
    serialized = {
      filename: databaseName,
      collections:[],
      databaseVersion: 1.1,
      engineVersion: 1.1,
      autosave: false,
      autosaveInterval: 5000,
      autosaveHandle: null,
      options: {"ENV":"BROWSER"},
      persistenceMethod: "localStorage",
      persistenceAdapter:null,
      events: {
        init: [null],
        "flushChanges":[],
        "close":[],
        "changes":[],
        "warning":[]
      },
      ENV: "CORDOVA"
    }
    d.resolve(serialized)
    l "RESULT ", serialized
    d.promise


  delete: () ->
    do assertDbIsPrepared
    d = Q.defer()
    request = IndexedDb.deleteDatabase(databaseName)
    request.onsuccess = -> d.resolve()
    request.onerror = -> d.reject(new Error("Failed to delete database"))
    d.promise


  declare: ({collection}) ->
    do assertDbIsPrepared
    d = Q.defer()
    # Put the collection into the collections store
    transaction = db.transaction(['__collections'], 'readwrite')
    store = transaction.objectStore('__collections')
    request = store.put collection
    request.onerror = () -> d.reject("Error")

    # Close the database and reopen it with a new database version
    request.onsuccess = ->
      version = db.version + 1
      db.close()
      request = IndexedDb.open(databaseName, version)
      request.onupgradeneeded = (e) ->
        # Nothing to do for now
        db = e.target.result
        unless db.objectStoreNames.contains(collection.name)
          db.createObjectStore(collection.name, keyPath: '$loki')
      request.onsuccess = (e) ->
        db = e.target.result
        d.resolve()
      request.onerror = (e) -> d.reject(e)
    d.promise


queue = Q()

@onmessage = (message) ->
  queue = queue.then =>
    Q.fcall(EventHandler[message.data?.command], message.data).then (result) =>
      @postMessage(queryId: message.data.queryId, result: result)
    .fail (error) =>
      @postMessage(queryId: message.data.queryId, error: error)

class Cipher

  constructor: (key, {algorithm, encoding} = {}) ->
    @_keyPromise = null
    @_encoding = encoding or 'utf-8'
    @_algorithm = algorithm or 'AES-CBC'
    @_key = key
    @_encoder = new TextEncoder(@_encoding)
    @_decoder = new TextDecoder(@_encoding)

  encrypt: (data) ->
    data = @_encode(data)
    @_importKey().then (key) =>
      crypto.subtle.encrypt(name: @_algorithm, iv: @_iv(), key, data)

  decrypt: (data) ->
    @_importKey().then (key) =>
      crypto.subtle.decrypt(name: @_algorithm, iv: @_iv(), key, data)
    .then (data) =>
      @_decode(data)

  _encode: (data) -> @_encoder.encode(data).buffer

  _decode: (data) -> @_decoder.decode(data)

  _importKey: ->
    @_keyPromise ||=
      Q(crypto.subtle.digest(name: 'SHA-256', @_encode(@_key))).then (key) =>
        crypto.subtle.importKey("raw", key, name: @_algorithm, true, ['encrypt', 'decrypt'])

  _iv: -> @__iv ||= new Uint8Array(16)