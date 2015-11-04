
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
  encryptedDataBytesCounter += data.byteLength
  data

storify = (obj) ->
  cipher.encrypt(JSON.stringify(obj)).then (data) ->
    $loki: obj['$loki']
    data: updateCounter(data)

unstorify = (obj) -> cipher.decrypt(obj.data).then((json) -> JSON.parse(json))

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
  transaction.oncomplete = ->
    d.resolve()
  transaction.onerror = (er) ->
    e er
    d.reject("Save error")
  d.promise

storeChanges = (changes, index = 0, encryptedChanges = []) ->
  Q.fcall ->
    if encryptedDataBytesCounter > MEMORY_WARNING or index >= changes.length
      flushedChanges = encryptedChanges
      encryptedChanges = []
      flushChanges(flushedChanges)
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

iterateThroughCollection = (collectionName, handler = (key, value) -> value) ->
  store = db.transaction(collectionName).objectStore(collectionName)
  d = Q.defer()
  result = []
  store.openCursor().onsuccess = (event) ->
    cursor = event.target.result
    if cursor?
      try
        result = result.concat(handler(cursor.key, cursor.value))
        cursor.continue()
      catch er
        e er
        d.reject(er)
    else
      d.resolve(result)
  d.promise
  ###
    var objectStore = db.transaction("customers").objectStore("customers");

    objectStore.openCursor().onsuccess = function(event) {
      var cursor = event.target.result;
      if (cursor) {
        alert("Name for SSN " + cursor.key + " is " + cursor.value.name);
        cursor.continue();
      }
      else {
        alert("No more entries!");
      }
    };
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
    iterateThroughCollection('__collections').then (collections) ->
      iterate = (index = 0) ->
        return collections if index >= collections.length
        collection = collections[index]
        inflateCollection = (id, object) ->
          (collection.data ||= []).push object
        iterateThroughCollection(collection.name, inflateCollection).then ->
          unstorifyCollection = (index = 0) ->
            return Q() if index >= collection.data.length
            unstorify(collection.data[index]).then (obj) ->
              collection.data[index] = obj
              unstorifyCollection(index + 1)
          unstorifyCollection().then ->
            collection.maxId = collection.data.length
            iterate(index + 1)
      iterate()
    .then (collections) ->
        filename: databaseName,
        collections: collections,
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

  delete: () ->
    do assertDbIsPrepared
    db.close()
    IndexedDb.deleteDatabase(databaseName)
    Q()


  declare: ({collection}) ->
    do assertDbIsPrepared
    d = Q.defer()
    # Put the collection into the collections store
    collection.data = []
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
    queryId =  message.data.queryId
    Q.fcall(EventHandler[message.data?.command], message.data).then (result) =>
      @postMessage(queryId: queryId, result: result)
    .fail (error) =>
      @postMessage(queryId: queryId, error: error)

@onerror = (er) -> e er

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