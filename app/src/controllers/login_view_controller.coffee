class @LoginViewController extends @ViewController

  onAfterRender: ->
    self = @
    @select('[name="next"]').on 'click', =>
      do SessionRestClient.instance.signIn