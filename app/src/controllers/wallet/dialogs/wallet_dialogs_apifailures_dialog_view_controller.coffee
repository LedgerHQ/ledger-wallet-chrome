class @WalletDialogsApifailuresDialogViewController extends ledger.common.DialogViewController

  openHelpCenter: ->
    window.open('https://ledger.groovehq.com/knowledge_base/topics/how-to-manage-my-account-if-ledgers-api-is-down')
    @dismiss()