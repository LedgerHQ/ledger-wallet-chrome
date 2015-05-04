class @CommonDialogsTicketDialogViewController extends @DialogViewController

  view:
    body: '#ticket_body'
    email: '#ticket_email'
    name: '#ticket_name'
    subject: '#ticket_subject'
    tags: '#ticket_tags'
    logs: '#ticket_isOkToSendLog'

  logs: ''

  onAfterRender: ->
    super
    @logsSwitch = new ledger.widgets.Switch(@view.logs)


  sendTicket: ->
    # Get metadata
    metadata = @_getMetadata()
    # If ok to send logs, encode logs to Base64
    logs = ''
    #if @logsSwitch.isOn()


    #logs = btoa logger?.logs()
    ###
    ledger.utils.Logger.logs().then( (v) ->
      l v
      logs = btoa v
      l logs)
    ###

    ###
    if @logsSwitch.isOn()
      ledger.utils.Logger.logs()
      .then (v) ->
        @logs = btoa(v)
    ###


    @_getLogs()
    .then (val) =>

      # Set a boolean to pass isOkToSend()
      @view.logs.val(@logsSwitch.isOn())

      l 'logs', val

      _.map @view, (value) =>
        if value.val?() is ''
          value.after('<p style="color:red">The field must be filled!</p>')

      isOktoSend = _.every @view, (value) =>
        value.val?() isnt '' and value.val?()?
      l 'isOktoSend', isOktoSend

      if isOktoSend and @_validateEmail()
        ledger.api.GrooveRestClient.singleton().sendTicket @view.body.val(), @view.email.val(), @view.name.val(), @view.subject.val(), @view.tags.val(), metadata, @logs
      else
        l 'all fields are required!'



  ###
  _updateSwitchState: ->
    @view.logs.setOn()
  ###

  _getLogs: ->
    d = Q.defer()
    allLogs = ''
    if @logsSwitch.isOn()
      ledger.utils.Logger.logs()
      .then (v) ->
        allLogs = btoa(v)
    d.resolve(allLogs)
    d.promise


  _validateEmail: ->
    email = @view.email
    filter = /^([a-zA-Z0-9_.-])+@(([a-zA-Z0-9-])+.)+([a-zA-Z0-9]{2,4})+$/
    if (filter.test email.val())
      l 'Given email is valid'
      #email.focus
      true
    else
      l 'Please enter a valid email!'
      #email.focus
      false


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