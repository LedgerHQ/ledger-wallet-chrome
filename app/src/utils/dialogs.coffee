@ledger.dialogs ?= {}

# Generic controller for displaying a view controller in a modal dialog
#
class @ledger.dialogs.DialogController extends EventEmitter

  constructor: (controller, @options) ->
    @_controller = controller

  # Show the dialog
  show: ->
    @_controller.show this

  onShow: ->
    @_viewController.onShow()
    @emit 'show'

  onDismiss: ->
    @_viewController.onDismiss()
    @emit 'dismiss'

  # Called by the dialogs controller when its time to render the view controller
  # in the given selector
  render: (selector, done) ->
    @_viewController.once 'afterRender', done
    @_viewController.render selector

  handleAction: (actionName, params) -> @_viewController.handleAction(actionName, params)

  push: (viewController) ->
    @_viewController = viewController
    viewController.parentViewController = @
    viewController.onAttach()
    @emit 'push', {sender: @, viewController: viewController}

  pop: ->
    return unless @_viewController?
    viewController = @_viewController
    @_viewController = null
    viewController.onDetach()
    viewController.parentViewController = undefined
    @emit 'pop', {sender: @, viewController: viewController}
    viewController

  # Ask to its DialogsController to dismiss its UI
  dismiss: ->
    @_controller.dismiss this


# Dialogs controller is responsible of managing every modal dialogs of the application.
# It creates and destroys DialogControllers and handle display hierarchy.
class @ledger.dialogs.DialogsController

  _dialogs: []

  initialize: (selector) ->
    @_selector = selector
    @_selector.hide()
    @_selector.css 'visibility', 'visible'
    @_selector.click (e) =>
      @dismissAll() unless e.isDefaultPrevented()

  # Create a new instance of a dialog controller
  # @param options [Hash] Set of options for creating the dialog controller
  create: (options = {}) ->
    dialog = new ledger.dialogs.DialogController(this, options)
    dialog

  # Shpw a dialog
  # @param dialog [ledger.dialogs.DialogController] the dialog to show
  show: (dialog) ->
    dialog._id = _.uniqueId()
    @_selector.append(JST['base/dialog']({dialog_id: dialog._id}))
    @_selector.find("#dialog_#{dialog._id}").on 'click', ((e) -> e.preventDefault())
    if @_dialogs.length == 0
      @_selector.fadeIn(500)
    @_dialogs.push dialog
    dialog.render @_selector.find("#dialog_#{dialog._id}"), =>
      @_selector.find("#dialog_#{dialog._id}").css('visibility', 'visible')
      @_selector.find("#dialog_#{dialog._id}").css('top', window.innerHeight / 2 + 'px')
      @_selector.find("#dialog_#{dialog._id}").css('opacity', '1')
      @_selector.find("#dialog_#{dialog._id}").animate {'top': 0, 'opacity': 1}, 500, 'smooth', ->
          dialog.onShow()

  # Dismiss a dialog
  # @param dialog [ledger.dialogs.DialogController] the dialog to dismiss
  dismiss: (dialog) ->
    @dismissAll()

  dismissAll: () ->
    return if @_dialogs.length == 0
    dialog = @_dialogs[0]
    @_dialogs.splice(0, 1)
    @_selector.fadeOut(300)
    @_selector.find("#dialog_#{dialog._id}").animate {top: window.innerHeight / 2, opacity: 1}, 300,  =>
      @_selector.find("#dialog_#{dialog._id}").remove()
      dialog.onDismiss()

  displayedDialog: () ->
    @_dialogs[0]

@ledger.dialogs.manager = new ledger.dialogs.DialogsController()