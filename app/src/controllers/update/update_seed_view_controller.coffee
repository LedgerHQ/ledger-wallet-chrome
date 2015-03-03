class @UpdateSeedViewController extends ViewController

  view:
    seedInput: "#seed_input"

  submitSeed: ->
    try
      @params.request.setKeyCardSeed()
    catch er
      switch er
        when ledger.fup.FirmwareUpdateRequest.Errors.InvalidSeedFormat then @onInvalidSeedFormat()
        when ledger.fup.FirmwareUpdateRequest.Errors.InvalidSeedSize then @onInvalidSeedSize()

  onInvalidSeedFormat: ->
    e 'Wrong format'

  onInvalidSeedSize: ->
