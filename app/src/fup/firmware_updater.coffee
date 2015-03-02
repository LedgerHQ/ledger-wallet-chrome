
ledger.fup ?= {}

###
  FirmwareUpdater is a manager responsible of firmware update related features. It is able to check if firmware updates are
  available for connected dongle, and can start firmware update requests.
###
class ledger.fup.FirmwareUpdater

  instance: new @

  ###
    Checks if a firmware update is available for the given wallet.

    @return [Boolean] True if a firmware update is available, false otherwise.
  ###
  isFirmwareUpdateAvailable: (wallet) -> yes

  ###
    Creates and starts a new firmware update request. Once started the firmware update request will catch all connected
    dongle and dongle related events.

    @return [ledger.fup.FirmwareUpdateRequest] The newly created firmware update request.
    @see ledger.fup.FirmwareUpdateRequest
    @throw If a request is already running
  ###
  requestFirmwareUpdate: ->
    throw "An update request is already running" if @_request?
    @_request = new ledger.fup.FirmwareUpdateRequest(@)
    @_request

  _cancelRequest: (request) -> @_request = null if request is @_request