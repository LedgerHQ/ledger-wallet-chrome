class @AppsCoinkiteCosignIndexDialogViewController extends DialogViewController

  view:
    requestInput: '#request_input'
    nextButton: '#next_button'
    errorContainer: '#error_container'

  onShow: ->
    super
    @view.requestInput.focus()

  next: ->
    nextError = @_nextFormError()
    if nextError?
      @view.errorContainer.show()
      @view.errorContainer.text nextError
    else
      @view.errorContainer.hide()    
      dialog = new AppsCoinkiteCosignFetchingDialogViewController request: @_request()
      @getDialog().push dialog

  _request: ->
    _.str.trim(@view.requestInput.val())

  _nextFormError: ->
    if @_request().length != 17
      return t 'apps.coinkite.cosign.errors.invalid_request_ref'
    undefined    