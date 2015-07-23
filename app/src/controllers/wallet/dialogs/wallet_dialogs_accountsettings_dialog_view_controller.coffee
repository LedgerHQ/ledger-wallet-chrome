class @WalletDialogsAccountsettingsDialogViewController extends ledger.common.DialogViewController

  view:
    colorsSelect: '#colors_select'
    colorSquare: '#color_square'
    errorContainer: '#error_container'
    accountNameInput: '#account_name_input'
    rootPathLabel: '#root_path_label'

  onAfterRender: ->
    super
    ledger.preferences.defaults.Accounts.applyColorsToSelect @view.colorsSelect, (option) =>
      option.attr('selected', true) if @_getAccount().get('color') == option.val()
    @view.rootPathLabel.text @_getAccount().getWalletAccount().getRootDerivationPath()
    @_updateAccountColorSquare()
    @_updateErrorContainerText()
    @_updateUIAccordingToAccount()
    @_listenEvents()

  onShow: ->
    super
    @view.accountNameInput.focus()

  saveAccount: ->
    # check that fields are filled-in
    if @_checkCurrentFormError() is false
      # save account
      @_getAccount().set('name', @_accountName()).set('color', @view.colorsSelect.val()).save()
      @dismiss()

  hideAccount: ->
    if @_getAccount().isDeletable()
      @_getAccount().delete()
    else
      @_getAccount().set('hidden', yes)

  exportXPub: ->
    (new WalletDialogsXpubDialogViewController(account_id: @_getAccount().get('index'))).show()

  _listenEvents: ->
    @view.colorsSelect.on 'change', @_updateAccountColorSquare

  _checkCurrentFormError: ->
    # get data
    accountName = @_accountName()

    # validate it
    if accountName.length == 0
      # show error
      @_updateErrorContainerText(t('common.errors.fill_all_fields'))
      return true
    else
      @_updateErrorContainerText()
      return false

  _updateAccountColorSquare: ->
    @view.colorSquare.css('color', @view.colorsSelect.val())

  _updateErrorContainerText: (text) ->
    if text?
      @view.errorContainer.text(text)
      @view.errorContainer.show()
    else
      @view.errorContainer.text('')
      @view.errorContainer.hide()

  _updateUIAccordingToAccount: ->
    @view.accountNameInput.val(@_getAccount().get('name'))

  _accountName: ->
    return _.str.trim @view.accountNameInput.val()

  _getAccount: ->
    @_account ||= Account.find(index: @params.account_id).first()