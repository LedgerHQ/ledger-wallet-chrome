ledger.managers ?= {}

class ledger.managers.Permissions extends EventEmitter

  request: (permissions, callback) ->
    if not permissions?
      callback?(no)
    if _.isString permissions
      permissions = {permissions: [permissions]}
    chrome.permissions.request permissions, (granted) =>
      callback?(granted)

  getAll: (callback) ->
    chrome.permissions.getAll (permissions) =>
      callback?(permissions)

  has: (permissions, callback) ->
    if not permissions?
      callback?(no)
    if _.isString permissions
      permissions = {permissions: [permissions]}
    chrome.permissions.contains permissions, (granted) =>
      callback?(granted)

  remove: (permissions, callback) ->
    if not permissions?
      callback?(no)
    if _.isString permissions
      permissions = {permissions: [permissions]}
    chrome.permissions.remove permissions, (removed) =>
      callback?(removed)

ledger.managers.permissions = new ledger.managers.Permissions()