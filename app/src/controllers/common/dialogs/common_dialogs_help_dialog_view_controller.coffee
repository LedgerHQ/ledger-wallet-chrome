class @CommonDialogsHelpDialogViewController extends DialogViewController

  browseKnowledge: ->
    window.open t 'application.support_url'
    @dismiss()

  contactSupport: ->
    @getDialog().push new CommonDialogsTicketDialogViewController()