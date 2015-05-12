class @CommonDialogsTicketDialogViewController extends @DialogViewController

  view:
#    body: '#ticket_body'
#    email: '#ticket_email'
#    name: '#ticket_name'
#    subject: '#ticket_subject'
#    tags: '#ticket_tags'
#    logs: '#ticket_isOkToSendLog'
    logsSwitchContainer: "#logs_switch_container"
    logsContainer: "#logs_container"
    tagsSegmentedControlContainer: "#tags_segmented_control_container"
    nameInput: "#name_input"
    subjectInput: "#subject_input"
    messageTextArea: "#message_text_area"
    emailAddressInput: "#email_address_input"
    errorContainer: "#error_container"
    sendButtton: "#send_button"

  onAfterRender: ->
    super
    @view.logsSwitch = new ledger.widgets.Switch(@view.logsSwitchContainer)
    @view.logsSwitch.setOn(true)
    @view.tagsSegmentedControl = new ledger.widgets.SegmentedControl(@view.tagsSegmentedControlContainer, ledger.widgets.SegmentedControl.Styles.Small)
    @_populateTagsSegmentedControl()
    @_updateLogsContainerVisibility()
    @_updateErrorContainerText()
    @_listenEvents()
    _.defer => @view.nameInput.focus()

  sendTicket: ->
    nextError = @_nextErrorLocalizedText()
    @_updateErrorContainerText(nextError)
    if not nextError?
      @_performTicketSend()

  _shouldAttachLogs: ->
    return @view.logsContainer.is(':visible') and @view.logsSwitch.isOn()

  _populateTagsSegmentedControl: ->
    for id in _.keys(ledger.preferences.defaults.Support.tags)
      tag = ledger.preferences.defaults.Support.tags[id]
      @view.tagsSegmentedControl.addAction(t tag.localization)
    @view.tagsSegmentedControl.setSelectedIndex(0)

  _updateLogsContainerVisibility: ->
    # if 'support' is selected
    if @_selectedTag() is ledger.preferences.defaults.Support.tags.support.value and (not ledger.preferences.instance? or ledger.preferences.instance.isLogActive())
      @view.logsContainer.show()
    else
      @view.logsContainer.hide()

  _updateErrorContainerText: (text) ->
    @view.errorContainer.text (if text? then text else '')
    if text? then @view.errorContainer.show() else @view.errorContainer.hide()

  _listenEvents: ->
    @view.tagsSegmentedControl.on 'selection', (event, {index}) =>
      @_updateLogsContainerVisibility()

  _nextErrorLocalizedText: ->
    data = @_datasToSend()
    if data.message == '' or data.subject == '' or data.email == '' or data.name == ''
      return t 'common.errors.fill_all_fields'
    else if ledger.validers.isValidEmailAddress(data.email) is false
      return t 'common.errors.not_a_valid_email'
    return undefined

  _selectedTag: ->
    selectedTagId = _.keys(ledger.preferences.defaults.Support.tags)[@view.tagsSegmentedControl.getSelectedIndex()]
    ledger.preferences.defaults.Support.tags[selectedTagId].value

  _datasToSend: ->
    name: _.str.trim(@view.nameInput.val())
    subject: _.str.trim(@view.subjectInput.val())
    message: _.str.trim(@view.messageTextArea.val())
    email: _.str.trim(@view.emailAddressInput.val())
    tag: @_selectedTag()
    metadata: @_getMetadata()
    zip: null

  _disableInterface: (disable) ->
    if disable
      @view.sendButtton.addClass 'disabled'
    else
      @view.sendButtton.removeClass 'disabled'

  _performTicketSend: ->
    sendBlock = (data) =>
      return if not @isShown()
      ledger.api.GrooveRestClient.singleton().sendTicket data, (success) =>
        return if not @isShown()
        @dismiss =>
          if success
            dialog = new CommonDialogsMessageDialogViewController(kind: "success", title: t("common.help.sent_message"), subtitle: t('common.help.thank_you_message'))
          else
            dialog = new CommonDialogsMessageDialogViewController(kind: "error", title: t("wallet.send.errors.not_sent_message"), subtitle: t('common.errors.error_occurred'))
          dialog.show()

    @_disableInterface(true)

    # get data + logs
    data = @_datasToSend()
    if @_shouldAttachLogs()
      @_getLogs (zip) =>
        return if not @isShown()
        data.zip = zip if zip?
        sendBlock(data)
    else
      sendBlock(data)

#  sendTicket: ->
#    # Get metadata
#    metadata = @_getMetadata()
#    @_getLogs()
#    .then (logs) =>
#      # Set a boolean to pass isOkToSend()
#      @view.logs.val(@logsSwitch.isOn())
#      # form checking UI
#      _.map @view, (value) =>
#        if (value.val?() is '' or value.val?() is null) and not value.next().hasClass('verif')
#          value.after('<p style="color:red" class="verif">The field must be filled!</p>')
#        #if (value.val?() isnt '' or value.val?() isnt null) and value.next().hasClass('verif')
#          #value.next().remove()
#
#      isOktoSend = _.every @view, (value) =>
#        value.val?() isnt '' and value.val?()?
#      l 'isOktoSend', isOktoSend
#
#      if isOktoSend and @_validateEmail()
#        ledger.api.GrooveRestClient.singleton().sendTicket @view.body.val(), @view.email.val(), @view.name.val(), @view.subject.val(), @view.tags.val(), metadata, logs
#      else
#        l 'all fields are required!'
#
#
  _getLogs: (callback) ->
    ledger.utils.Logger.exportLogsToBlob ({blob, name}) =>
      if not blob?
        callback?(null)
        return
      @_zipBlob blob, name + '.csv', (zip) =>
        callback?(zip)

  _zipBlob: (blob, filename, callback) ->
    # use a zip.BlobWriter object to write zipped data into a Blob object
    zip.createWriter new zip.BlobWriter("application/zip"), (zipWriter) ->
      # use a BlobReader object to read the data stored into blob variable
      zipWriter.add filename, new zip.BlobReader(blob), ->
        # close the writer and calls callback function
        zipWriter.close(callback)
    , (e) ->
      callback?(null)

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