class @MainViewController extends @ViewController

  onAfterRender: ->
    @select('[name="previous"]').on 'click', =>
      @parentViewController.pop()