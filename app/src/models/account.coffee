class @Account extends Model
  do @init

  @hasMany operations: 'Operation'

  @fromHDWalletAccount: (hdAccount) ->
    return null unless hdAccount?
    @find(hdAccount.index)

  createTransaction: (amount, fees, callback) ->
    transaction = new ledger.wallet.Transaction()
    transaction.init amount, fees

  ## Balance management

  retrieveBalance: () ->
    ledger.tasks.BalanceTask.get(@getId()).startIfNeccessary()

  ## Operations

  addRawTransaction: (rawTransaction) ->
    @exists (exists) =>
      return unless exists
      @get (account) =>
        l account
        hdAccount = ledger.wallet.HDWallet.instance?.getAccount(@getId())
        return unless hdAccount?



        transaction =
          _id: rawTransaction['hash']
          fees: rawTransaction['fees']
          time: rawTransaction['chain_received_at']
          type: 'reception'
          sender: null
          recipient: null
          confirmations: rawTransaction['confirmations']

        l transaction
