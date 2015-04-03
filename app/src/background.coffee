updateAvailable = no

chrome.app.runtime.onLaunched.addListener =>
  chrome.app.window.create 'views/layout.html',
    id: "main_window"
    innerBounds:
      minWidth: 1000,
      minHeight: 640,
    (createdWindow) ->
      createdWindow.onClosed.addListener performUpdateIfPossible

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse)=>
  switch request.request
    when 'ping' then sendResponse yes
    when 'launch'
      chrome.app.window.create 'views/layout.html',
        id: "main_window"
        innerBounds:
          minWidth: 1000,
          minHeight: 640
      sendResponse yes

chrome.runtime.onUpdateAvailable.addListener ->
  updateAvailable = yes
  performUpdateIfPossible()

performUpdateIfPossible = () ->
  setTimeout ->
    if updateAvailable is yes and chrome.app.window.getAll().length == 0
      chrome.runtime.reload()
  , 0