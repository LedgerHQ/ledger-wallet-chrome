class @WalletAccountsIndexViewController extends ledger.common.ActionBarViewController

  actions: [
    {title: 'wallet.accounts.index.actions.add_account', icon: 'fa-plus', url: '#addAccount'}
    {title: 'wallet.accounts.index.actions.manage_tags', icon: 'fa-tag', url: '#manageTags'}
  ]

  onBeforeRender: ->
    super
    @accounts =
      for account in Account.all()
        id: account.get('index'), name: account.get('name')
