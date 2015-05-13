class @CommonDialogsTicketDialogViewController extends ledger.common.DialogViewController

  view:
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
    @view.sendButtton.text(t 'common.sending')

    # get data + logs
    data = @_datasToSend()
    if @_shouldAttachLogs()
      ledger.utils.Logger.exportLogsToZip ({zip}) =>
        return if not @isShown()
        data.zip = zip if zip?
        sendBlock(data)
    else
      sendBlock(data)

  _getMetadata: ->
    # Get OS, version Chrome, version firmware, version chromeApp, etc..
    parser = new UAParser()
    parser.setUA window.navigator.userAgent
    ua = parser.getResult()

    intFirmwareVersion = ledger.app.dongle?.getIntFirmwareVersion()
    hexFirmwareVersion = (intFirmwareVersion)?.toString(16)
    firmwareVersion = ledger.app.dongle?.getStringFirmwareVersion()

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