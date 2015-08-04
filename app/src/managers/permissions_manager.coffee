ledger.managers ?= {}

class ledger.managers.Permissions extends EventEmitter

  request: (permissions, callback) ->
    if ledger.nwjs?
      return callback?(yes)
    if not permissions?
      callback?(no)
    if _.isString permissions
      permissions = {permissions: [permissions]}
    chrome.permissions.request permissions, (granted) =>
      callback?(granted)

  getAll: (callback) ->
    if ledger.nwjs?
      return callback?([])
    chrome.permissions.getAll (permissions) =>
      callback?(permissions)

  has: (permissions, callback) ->
    if ledger.nwjs?
      return callback?(yes)
    if not permissions?
      callback?(no)
    if _.isString permissions
      permissions = {permissions: [permissions]}
    chrome.permissions.contains permissions, (granted) =>
      callback?(granted)

  remove: (permissions, callback) ->
    if ledger.nwjs?
      return callback?(yes)
    if not permissions?
      callback?(no)
    if _.isString permissions
      permissions = {permissions: [permissions]}
    chrome.permissions.remove permissions, (removed) =>
      callback?(removed)

ledger.managers.permissions = new ledger.managers.Permissions()