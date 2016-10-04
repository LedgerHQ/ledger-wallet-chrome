updateAvailable = no

`
  var apps = [
    {
      name: "Ledger Wallet Ethereum",
      id: "hmlhkialjkaldndjnlcdfdphcgeadkkm"
    }
  ];

  function ensureIsSingleton(callback) {
    var iterate = function (index) {
      if (index >= apps.length) {
        callback(true, null);
      } else {
        var app = apps[index];
        chrome.runtime.sendMessage(app.id, {request: "is_launched"},
            function (response) {
              if (typeof response === "undefined" || !response.result)
                iterate(index + 1);
              else
                callback(false, app);
            });
      }
    };
    iterate(0)
  }

  function startApp(callback) {
    chrome.app.window.create('views/layout.html', {
      id: "main_window",
      innerBounds: {
        minWidth: 1000,
        minHeight: 640
      }
    }, function(createdWindow) {
      return createdWindow.onClosed.addListener(performUpdateIfPossible);
    });
  }

  function displayCantLaunchNotification(app) {
    chrome.notifications.create("cannot_launch", {
      type: "basic",
      title: chrome.i18n.getMessage("application_name"),
      message: chrome.i18n.getMessage("application_singleton_alert_message").replace("{APPLICATION_NAME}", app.name),
      iconUrl: "assets/images/icon-48.png"
    }, function () {});
    chrome.app.window.create('public/mac_close_fix/fix.html', {
      id: "fix1000",
      innerBounds: {
        width: 0,
        height: 0,
        left: 0,
        top: 0,
        minWidth: 0,
        minHeight: 0
      },
      hidden: true,
      frame: "none"
    })
  }

  function tryStartApp() {
    ensureIsSingleton(function (isSingleton, app) {
      console.log(arguments);
      if (isSingleton) {
        startApp();
      } else {
        displayCantLaunchNotification(app)
      }
    })
  }
`

chrome.app.runtime.onLaunched.addListener =>
  tryStartApp()

chrome.runtime.onMessageExternal.addListener (request, sender, sendResponse) =>
  window.externalSendResponse = sendResponse
  if typeof request.request == "string"
    req = request.request
  else if request.request?
    req = request.request.command
    data = request.request
  payload = {}
  switch req
    when 'ping' 
      window.externalSendResponse { command: "ping", result: true }
    when 'is_launched'
      window.externalSendResponse { command: "is_launched", result: (chrome.app.window.getAll().length != 0) }
    when 'launch'
      tryStartApp()
      window.externalSendResponse { command: "launch", result: true }
    when 'has_session'
      payload = {
        command: 'has_session'
      }
    when 'bitid'
      payload = {
        command: 'bitid',
        uri: data.uri,
        silent: data.silent
      }
    when 'get_accounts'
      payload = {
        command: 'get_accounts'
      }
    when 'get_operations'
      payload = {
        command: 'get_operations',
        account_id: data.account_id
      }
    when 'get_new_addresses'
      payload = {
        command: 'get_new_addresses',
        account_id: data.account_id,
        count: data.count
      }
    when 'send_payment'
      payload = {
        command: 'send_payment',
        address: data.address,
        amount: data.amount,
        data: data.data
      }
    when 'get_xpubkey'
      payload = {
        command: 'get_xpubkey',
        path: data.path
      }
    when 'sign_p2sh'
      payload = {
        command: 'sign_p2sh',
        inputs: data.inputs, 
        scripts: data.scripts, 
        outputs_number: data.outputs_number, 
        outputs_script: data.outputs_script, 
        paths: data.paths
      }
    when 'coinkite_get_xpubkey'
      payload = {
        command: 'coinkite_get_xpubkey',
        index: data.index
      }
    when 'coinkite_sign_json'
      payload = {
        command: 'coinkite_sign_json',
        json: data.json
      }
  if payload.command? && chrome.app.window.get("main_window")?
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
