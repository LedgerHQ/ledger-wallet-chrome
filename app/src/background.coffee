updateAvailable = no

chrome.app.runtime.onLaunched.addListener =>
  chrome.app.window.create 'views/layout.html',
    id: "main_window"
    innerBounds:
      minWidth: 1000,
      minHeight: 640,
    (createdWindow) ->
      createdWindow.onClosed.addListener performUpdateIfPossible

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) =>
  window.externalSendResponse = sendResponse
  if typeof request.request == "string"
    req = request.request
  else if request.request?
    req = request.request.command
    data = request.request
    console.log data
  switch req
    when 'ping' 
      window.externalSendResponse { command: "ping", result: true }
    when 'launch'
      chrome.app.window.create 'views/layout.html',
        id: "main_window"
        innerBounds:
          minWidth: 1000,
          minHeight: 640
      window.externalSendResponse { command: "launch", result: true }
    when 'has_session'
      payload = {
        command: 'has_session'
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
    when 'bitid'
      payload = {
        command: 'bitid',
        uri: data.uri,
        silent: data.silent
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
    when 'send_payment'
      payload = {
        command: 'send_payment',
        address: data.address,
        amount: data.amount
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
    when 'get_xpubkey'
      payload = {
        command: 'get_xpubkey',
        path: data.path
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
    when 'sign_p2sh'
      payload = {
        command: 'sign_p2sh',
        inputs: data.inputs, 
        scripts: data.scripts, 
        outputs_number: data.outputs_number, 
        outputs_script: data.outputs_script, 
        paths: data.paths
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
    when 'coinkite_get_xpubkey'
      payload = {
        command: 'coinkite_get_xpubkey',
        index: data.index
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
    when 'coinkite_sign_json'
      payload = {
        command: 'coinkite_sign_json',
        json: data.json
      }
      if chrome.app.window.get("main_window")?
        chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
  return true

chrome.runtime.onMessage.addListener (request, sender, sendResponse) =>
  if window.externalSendResponse
    window.externalSendResponse request

chrome.runtime.onUpdateAvailable.addListener ->
  updateAvailable = yes
  performUpdateIfPossible()

performUpdateIfPossible = () ->
  setTimeout ->
    if updateAvailable is yes and chrome.app.window.getAll().length == 0
      chrome.runtime.reload()
  , 0