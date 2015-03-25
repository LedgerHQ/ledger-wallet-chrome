chrome.app.runtime.onLaunched.addListener =>
  chrome.app.window.create 'views/layout.html',
    id: "main_window"
    innerBounds:
      minWidth: 1000,
      minHeight: 640

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse)=>
  if typeof request.request == "string"
    req = request.request
  else
    req = request.request.command
    data = request.request
  console.log req
  switch req
    when 'ping' then sendResponse yes
    when 'launch'
      chrome.app.window.create 'views/layout.html',
        id: "main_window"
        innerBounds:
          minWidth: 1000,
          minHeight: 640
      sendResponse yes
    when 'bitid'
      console.log data.uri
      payload = {
        command: 'bitid',
        uri: data.uri
      }
      chrome.app.window.get("main_window").contentWindow.postMessage payload, "*"
      sendResponse yes