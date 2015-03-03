class @UpdateSeedViewController extends UpdateViewController

  view:
    seedInput: "#seed_input"

  submitSeed: ->
    try
      @getRequest().setKeyCardSeed(@view.seedInput.val())
      ledger.app.router.go '/update/plug'
    catch er
      switch er
        when ledger.fup.FirmwareUpdateRequest.Errors.InvalidSeedFormat then @onInvalidSeedFormat()
        when ledger.fup.FirmwareUpdateRequest.Errors.InvalidSeedSize then @onInvalidSeedSize()

  onInvalidSeedFormat: ->
    e 'Wrong format'

  onInvalidSeedSize: ->
    e 'Wrong length'