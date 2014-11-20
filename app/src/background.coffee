chrome.app.runtime.onLaunched.addListener =>
  chrome.app.window.create 'views/layout.html',
    id: "main_window"
    innerBounds:
      minWidth: 1000,
      minHeight: 640

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

