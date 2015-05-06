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
    @_getLogs()
    .then (logs) =>
      # Set a boolean to pass isOkToSend()
      @view.logs.val(@logsSwitch.isOn())
      # form checking UI
      _.map @view, (value) =>
        if (value.val?() is '' or value.val?() is null) and not value.next().hasClass('verif')
          value.after('<p style="color:red" class="verif">The field must be filled!</p>')
        #if (value.val?() isnt '' or value.val?() isnt null) and value.next().hasClass('verif')
          #value.next().remove()

      isOktoSend = _.every @view, (value) =>
        value.val?() isnt '' and value.val?()?
      l 'isOktoSend', isOktoSend

      if isOktoSend and @_validateEmail()
        ledger.api.GrooveRestClient.singleton().sendTicket @view.body.val(), @view.email.val(), @view.name.val(), @view.subject.val(), @view.tags.val(), metadata, logs
      else
        l 'all fields are required!'


  _getLogs: ->
    d = Q.defer()
    if @logsSwitch.isOn()
      ledger.utils.Logger.exportLogsToBlob ({blob, name}) =>
        @_zipBlob name + '.csv', blob, (zip) ->
          d.resolve(zip)
    else
      d.resolve(null)
    d.promise


  _zipBlob: (filename, blob, callback) ->
    #use a zip.BlobWriter object to write zipped data into a Blob object
    zip.createWriter new zip.BlobWriter("application/zip"), (zipWriter) ->
      #use a BlobReader object to read the data stored into blob variable
      zipWriter.add filename, new zip.BlobReader(blob), ->
        #close the writer and calls callback function
        zipWriter.close(callback)
    , (e) ->
      l e
      callback


  _validateEmail: ->
    email = @view.email
    filter = /^([a-zA-Z0-9_.-])+@(([a-zA-Z0-9-])+.)+([a-zA-Z0-9]{2,4})+$/
    if (filter.test email.val())
      l 'Given email is valid'
      true
    else
      l 'Please enter a valid email!'
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