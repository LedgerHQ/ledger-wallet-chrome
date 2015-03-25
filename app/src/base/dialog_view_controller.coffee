# Base view controller class for view controllers able to render
# themselves in a modal dialog.
#
# @event show Emitted when the dialog is done showing
# @event dismiss Emitted when the dialog is dismissed
class @DialogViewController extends ViewController

  # Override in order to make the dialog cancellable or not
  cancellable: yes

  # Show the current view controller in a modal dialog
  show: (options = {}) ->
    @_dialog = ledger.dialogs.manager.create()
    @_dialog.push this
    @parentViewController.show()
    @

  identifier: () ->
    @className().replace 'DialogViewController', ''

  getDialog: () -> @_dialog

  # Dismiss the current view controller
  dismiss: (callback = undefined) ->
    @once 'dismiss', -> callback?()
    @_dialog.dismiss()

  # Called once the dialog has been shown
  onShow: ->
    @emit 'show'

  isShown: ->
    @_dialog?.isShown()

  onDetach: ->
    super
    $("link[id='dialog_view_controller_style_#{@getDialog().getId()}']").remove()

  setControllerStylesheet: () ->
    $("link[id='dialog_view_controller_style_#{@getDialog().getId()}']").remove()
    $("head").append($("<link id='dialog_view_controller_style_#{@getDialog().getId()}' href='../assets/css/#{@cssPath()}.css?#{new Date().getTime()}' rel='stylesheet'>"))
    #$("link[id='dialog_view_controller_style_#{@getDialog().getId()}']").attr('href', '../assets/css/' + @cssPath() + '.css?' + (new Date()).getTime())

  # Called once the dialog is dismissed
  onDismiss: ->
    @emit 'dismiss'
