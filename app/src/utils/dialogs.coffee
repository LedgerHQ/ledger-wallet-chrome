@ledger.dialogs ?= {}

# Generic controller for displaying a view controller in a modal dialog
#
class @ledger.dialogs.DialogController extends EventEmitter

  constructor: (controller, @options) ->
    @_controller = controller
    @_shown = no
    @_backStack = []
    @_cancellable = true

  # Show the dialog
  show: ->
    @_controller.show this

  onShow: ->
    @_shown = yes
    @_viewController.onShow()
    @emit 'show'

  isShown: -> @_shown

  setCancellable: (cancellable) -> @_cancellable = cancellable

  isCancellable: -> @_cancellable

  getId: () -> @_id

  onDismiss: ->
    @_viewController.onDetach()
    @_viewController.onDismiss()
    @emit 'dismiss'
    @_shown = no

  # Called by the dialogs controller when its time to render the view controller
  # in the given selector
  render: (selector, done) ->
    @_selector = selector
    @_viewController.once 'afterRender', done
    @_viewController.render selector

  rerender: ->
    @render @_selector if @_selector

  handleAction: (actionName, params) -> @_viewController.handleAction(actionName, params)

  push: (viewController) ->
    if @_viewController?
     @_pushViewController(viewController)
    else
      @_viewController = viewController
      viewController.parentViewController = @
      viewController.onAttach()
      @emit 'push', {sender: @, viewController: viewController}
    @setCancellable(if viewController.cancellable? then viewController.cancellable else yes)
    if @isCancellable()
      @_containerSelector?.addClass("clickable")
    else
      @_containerSelector?.removeClass("clickable")

  _pushViewController: (viewController) ->
    @_viewController?.onDetach()
    @_backStack.push @_viewController if @_viewController?
    @_viewController = viewController
    @_viewController.parentViewController = @
    @_viewController._dialog = @
    @_viewController.onAttach()
    @_viewController.render @_selector
    @emit 'push', {sender: @, viewController: viewController}

  pop: ->
    return unless @_viewController?
    viewController = @_viewController
    @_viewController = null
    viewController.onDetach()
    viewController.parentViewController = undefined
    @emit 'pop', {sender: @, viewController: viewController}
    if @_backStack.length > 0
      @_pushViewController(@_backStack.splice(@_backStack.length - 1, 1)[0])
    viewController

  # Ask to its DialogsController to dismiss its UI
  dismiss: (animated = yes) ->
    @_controller.dismiss this, animated


# Dialogs controller is responsible of managing every modal dialogs of the application.
# It creates and destroys DialogControllers and handle display hierarchy.
class @ledger.dialogs.DialogsController

  _dialogs: []

  initialize: (selector) ->
    @_selector = selector
    @_selector.css('visibility', 'visible') # To remove 'visibility: hidden' in layout.html (prevent clipping)
    @_selector.hide()
    #@_selector.on 'click', (e) =>
      #@dismissAll() unless e.isDefaultPrevented()

  # Create a new instance of a dialog controller
  # @param options [Hash] Set of options for creating the dialog controller
  create: (options = {}) ->
    dialog = new ledger.dialogs.DialogController(this, options)
    dialog

  # Shpw a dialog
  # @param dialog [ledger.dialogs.DialogController] the dialog to show
  show: (dialog) ->

    dialog._level = @_dialogs.length
    dialog._id = _.uniqueId()

    @_selector.show(0, =>  @_selector.addClass('display')) if @_dialogs.length is 0

    @_selector.append(JST['common/dialogs/dialog']({dialog_id: dialog._id}))
    @_selector.find("#dialog_#{dialog._id}").on 'click', ((e) -> e.preventDefault())
    if @_dialogs.length == 0
      @_selector.show()

    dialog._containerSelector = @_selector.find("#dialog_container_#{dialog._id}")
    dialog._containerSelector.addClass("clickable") if dialog.isCancellable()
    container = dialog._containerSelector
    container.addClass('display')
    container.on 'click', (e) =>
      dialog.dismiss() if !e.isDefaultPrevented() and dialog.isCancellable()

    @_dialogs.push dialog
    dialog.render @_selector.find("#dialog_#{dialog._id}"), =>
      dialogSelector = @_selector.find("#dialog_#{dialog._id}")
      dialogSelector.css('visibility', 'visible')
      dialogSelector.css('top', (window.innerHeight + dialogSelector.height()) / 2 + 'px')
      dialogSelector.css('opacity', '1')
      dialogSelector.animate {'top': 0, 'opacity': 1}, 500, 'smooth', ->
          dialog.onShow()

  # Dismiss a dialog
  # @param dialog [ledger.dialogs.DialogController] the dialog to dismiss
  dismiss: (dialog, animated = yes) ->
    return if not dialog.isShown()
    @_dialogs = _.without @_dialogs, dialog
    @_selector.find("#dialog_container_#{dialog._id}").removeClass('display')
    dialogSelector = @_selector.find("#dialog_#{dialog._id}")
    dialogSelector.animate {top:(window.innerHeight) / 2 + dialogSelector.height() * 0.8, opacity: 0.6}, (if animated then 400 else 0),  =>
      @_selector.find("#dialog_container_#{dialog._id}").remove()
      dialog.onDismiss()
      @_selector.hide() if @_dialogs.length is 0

  dismissAll: (animated = yes) ->
    return if @_dialogs.length == 0
    while @_dialogs.length > 0
      @_dialogs[@_dialogs.length - 1].dismiss(animated)

  getAllDialogs: -> @_dialogs

  displayedDialog: () -> @_dialogs[@_dialogs.length - 1]

@ledger.dialogs.manager = new ledger.dialogs.DialogsController()