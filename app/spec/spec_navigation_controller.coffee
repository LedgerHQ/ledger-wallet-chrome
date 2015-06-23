class @SpecNavigationController extends ledger.common.NavigationController

  renderChild: ->
    if window.jasmine?
     super()
    else
      ledger.specs.init().then =>
       super()
      .done()


