class @WalletDashboardIndexViewController extends @ViewController

  onAfterRender: ()->
    l 'render'
    $('#test').on 'click', ->
      l 'Salut'

  test: () ->
    l 'Test'
