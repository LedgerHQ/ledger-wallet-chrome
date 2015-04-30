class @CommonDialogsTicketDialogViewController extends @DialogViewController

  view:
    body: '#ticket_body'
    email: '#ticket_email'
    name: '#ticket_name'
    subject: '#ticket_subject'
    tags: '#ticket_tags'
    logs: '#ticket_isOkToSendLog'

  onAfterRender: ->
    super
    #_.defer => @sendTicket()
    @view.logs = new ledger.widgets.Switch(@view.logs)



  switchisLog: ->
    setOn()


  sendTicket: ->
    # Get metadata
    metadata = @_getMetadata()
    # If ok to send logs, encode logs to Base64
    if @view.logs.isOn()
      logs = btoa logger?.logs()
    else
      logs = 'I don\'t want to send my logs!'


    #_.each @view, (value) -> return value

    isOktoSend = _.every @view, (value) =>
      value.val?() isnt '' and value.val?()?

    l 'isOktoSend', isOktoSend

    if isOktoSend
      ledger.api.GrooveRestClient.singleton().sendTicket @view.body.val(), @view.email.val(), @view.name.val(), @view.subject.val(), @view.tags.val(), metadata, logs
    else
      l 'all fields are required!'

  _updateSwitchState: ->
    @view.logs.setOn

  _getMetadata: ->
    # Get OS, version Chrome, version firmware, version chromeApp, etc..
    parser = new UAParser()
    parser.setUA window.navigator.userAgent
    ua = parser.getResult()

    intFirmwareVersion = ledger.app.wallet?.getIntFirmwareVersion()
    hexFirmwareVersion = (intFirmwareVersion)?.toString(16)
    firmwareVersion = ledger.app.wallet?.getFirmwareVersion()

    metadata =
      browser:
        name: ua.browser.name
        version: ua.browser.version
        major: ua.browser.major
      os:
        name: ua.os.name
        version: ua.os.version
      cpuArchitecture: ua.cpu.architecture
      device:
        model: ua.device.model
        type: ua.device.type
        vendor: ua.device.vendor
      engine:
        name: ua.engine.name
        version: ua.engine.version
      appVersion: ledger.managers.application.stringVersion()
      firmware:
        version: firmwareVersion
        hexVersion: hexFirmwareVersion
        intVersion: intFirmwareVersion

    JSON.stringify metadata