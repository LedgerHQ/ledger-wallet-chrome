class @WalletReceiveEnforceIndexDialogViewController extends ledger.common.DialogViewController

  view:
    amountInput: '#amount_input'
    currencyContainer: '#currency_container'
    receiverAddress: "#receiver_address"
    accountsSelect: '#accounts_select'
    colorSquare: '#color_square'
    verifyButton: '#verify_button'
    verifiedView: '#verified'
    notVerifiedView: '#not_verified'

  initialize: ->
    @verified = false

  onAfterRender: ->
    super
    @view.verifiedView.hide()
    # apply params
    if @params.amount?
      @view.amountInput.val @params.amount

    # configure view
    @view.amountInput.focus()
    @view.qrcode = new QRCode "qrcode_frame",
      text: ""
      width: 196
      height: 196
      colorDark : "#000000"
      colorLight : "#ffffff"
      correctLevel : QRCode.CorrectLevel.H
    @view.amountInput.amountInput(ledger.preferences.instance.getBitcoinUnitMaximumDecimalDigitsCount())
    @_updateAccountsSelect()
    @_updateColorSquare()
    @_updateQrCode()
    @_updateReceiverAddress()
    @_listenEvents()


  onShow: ->
    super

  mail: ->
    window.open 'mailto:?body=' + @_receivingAddress()

  print: ->
    window.print()
  
  openSensitive: ->
    window.open t 'application.sensitive_url'

  _listenEvents: ->
    @view.amountInput.on 'keyup', (e) =>
      _.defer => 
        @_updateQrCode()
        @_updateExchangeValue()

  _updateQrCode: () ->
    @view.qrcode.makeCode(@_bitcoinAddressUri());

  _updateExchangeValue: ->
    valueSatoshi = ledger.formatters.fromValueToSatoshi(_.str.trim(@view.amountInput.val() or "0"))
    value = ledger.Amount.fromSatoshi(valueSatoshi)
    if ledger.preferences.instance.isCurrencyActive()
      if value.toString() != @view.currencyContainer.attr('data-countervalue')
        @view.currencyContainer.removeAttr 'data-countervalue'
        @view.currencyContainer.empty()
        @view.currencyContainer.attr 'data-countervalue', value
    else
      @view.currencyContainer.hide()

  _updateReceiverAddress: ->
    @view.receiverAddress.text @_receivingAddress()

  _bitcoinAddressUri: ->
    uri = ledger.config.network.scheme + @_receivingAddress()
    uri += "?amount=#{ledger.formatters.fromSatoshiToBTC(@_selectedAmount()).replace(',', '.').replace(" ", "")}" if @_selectedAmount() isnt "0" and @_selectedAmount() isnt 0
    uri

  _updateAccountsSelect: ->
    accounts = Account.displayableAccounts()
    for account in accounts
      option = $('<option></option>').text(account.name + ' (' + ledger.formatters.formatValue(account.balance) + ')').val(account.index)
      option.attr('selected', true) if @params.account_id? and account.index is +@params.account_id
      @view.accountsSelect.append option

  _updateColorSquare: ->
    @view.colorSquare.css('color', @_selectedAccount().get('color'))

  _selectedAccount: ->
    Account.find(index: parseInt(@view.accountsSelect.val())).first()

  _selectedAmount: ->
    ledger.formatters.fromValueToSatoshi(@view.amountInput.val() or "0")

  _receivingAddress: ->
    @_selectedAccount().getWalletAccount().getCurrentPublicAddress()

  verify: ->
    @verified = true
    @getDialog().setCancellable(false)
    @view.notVerifiedView.hide()
    @view.verifiedView.show()
    return if @_verifyQueue?.inspect().state is "pending"
    @_verifyQueue = ledger.app.dongle.verifyAddressOnScreen(@_selectedAccount().getWalletAccount().getCurrentPublicAddressPath())
    @_verifyQueue.then (result) =>
      @getDialog().setCancellable(true)
      @verified = false
      if _.isEmpty(result)
        alert = new WalletReceiveEnforceAlertDialogViewController({message: t("wallet.receive.enforce.alert"), positiveText: t("wallet.receive.enforce.contact") })
        alert.once 'click:positive', =>
          window.open t 'application.support_url'
          @dismiss()
        alert.once 'click:cancel', =>
          @dismiss()
        alert.show()
      else
        @dismiss()
    .catch (e) => 
      @dismiss()
    return