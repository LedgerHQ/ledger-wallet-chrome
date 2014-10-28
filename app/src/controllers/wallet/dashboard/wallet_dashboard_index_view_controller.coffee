class @WalletDashboardIndexViewController extends @ViewController

  onAfterRender: ()->
    $('#test').on 'click', ->
      l 'Salut'

  test: () ->
    l 'Test'
