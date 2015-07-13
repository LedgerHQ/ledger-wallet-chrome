class @WalletDialogsAddaccountDialogViewController extends ledger.common.DialogViewController

  view:
    colorsSelect: '#colors_select'
    colorSquare: '#color_square'
    errorContainer: '#error_container'
    accountNameInput: '#account_name_input'

  onAfterRender: ->
    super
    ledger.preferences.defaults.Accounts.applyColorsToSelect(@view.colorsSelect)
    @_updateAccountColorSquare()
    @_updateErrorContainerText()
    @_listenEvents()

  onShow: ->
    super
    @view.accountNameInput.focus()

  addAccount: ->
    # check that fields are filled-in
    if @_checkCurrentFormError() is false
      # create account
      account = Account.create(index: ledger.wallet.Wallet.instance.getNextAccountIndex(), name: @_accountName(), color: @view.colorsSelect.val()).save()
      Wallet.instance.add('account', account)
      @dismiss()

  showAccount: (params) ->
    l 'show', params
    @dismiss()

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

  _accountName: ->
    return _.str.trim @view.accountNameInput.val()