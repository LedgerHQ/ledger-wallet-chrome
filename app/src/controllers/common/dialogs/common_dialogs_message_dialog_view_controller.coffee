class @CommonDialogsMessageDialogViewController extends @DialogViewController

  ###
    @param kind [String] The message kind [error|success]
    @param title [String] The message title
    @param subtitle [String] The message subtitle
  ###
  constructor: ({kind, title, subtitle}) ->
    kind ?= "success"
    title ?= ""
    subtitle ?= ""
    super
