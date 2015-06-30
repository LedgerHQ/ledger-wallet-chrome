class @WalletAccountsIndexViewController extends ledger.common.ActionBarViewController

  actions: [
    {title: 'wallet.accounts.index.actions.add_account', icon: 'fa-plus', url: '#addAccount'}
    {title: 'wallet.accounts.index.actions.see_all_operations', icon: 'fa-bars', url: '/wallet/accounts/alloperations'}
  ]

  onBeforeRender: ->
    super
    @accounts =
      for account in Account.all()
        id: account.get('index'), name: account.get('name')
