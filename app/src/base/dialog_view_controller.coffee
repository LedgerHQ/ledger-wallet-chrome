# Base view controller class for view controllers able to render
# themselves in a modal dialog.
#
# @event show Emitted when the dialog is done showing
# @event dismiss Emitted when the dialog is dismissed
class @DialogViewController extends ViewController

  # Show the current view controller in a modal dialog
  show: (options = {}) ->
    @_dialog = ledger.dialogs.manager.create()
    @_dialog.push this
    @parentViewController.show()

  identifier: () ->
    @className().replace 'DialogViewController', ''

  # Dismiss the current view controller
  dismiss: () ->
    @parentViewController.dismiss()

  # Called once the dialog has been shown
  onShow: ->
    @emit 'show'

  # Called once the dialog is dismissed
  onDismiss: ->
    @emit 'dismiss'
