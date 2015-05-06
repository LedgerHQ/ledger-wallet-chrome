
ledger.fup ?= {}

FirmwareAvailabilityResult =
  Overwrite: 0
  Update: 1
  Higher: 2


###
  FirmwareUpdater is a manager responsible of firmware update related features. It is able to check if firmware updates are
  available for connected dongle, and can start firmware update requests.
###
class ledger.fup.FirmwareUpdater

  @FirmwareAvailabilityResult: FirmwareAvailabilityResult

  @instance: new @

  constructor: ->
    @_scripts = []

  ###
    Checks if a firmware update is available for the given dongle.

    @return [Boolean] True if a firmware update is available, false otherwise.
  ###
  getFirmwareUpdateAvailability: (dongle, bootloaderMode = no, forceBl = no, callback = undefined) ->
    d = ledger.defer(callback)
    dongle.getRawFirmwareVersion bootloaderMode, forceBl, (version, error) =>
      return d.reject(error) if error?
      @_lastVersion = version
      if ledger.fup.utils.compareVersions(@_lastVersion, ledger.fup.versions.Nano.CurrentVersion.Os).eq()
        d.resolve(result: FirmwareAvailabilityResult.Overwrite, available: no, dongleVersion: version, currentVersion: ledger.fup.versions.Nano.CurrentVersion.Os)
      else if ledger.fup.utils.compareVersions(@_lastVersion, ledger.fup.versions.Nano.CurrentVersion.Os).gt()
        d.resolve(result: FirmwareAvailabilityResult.Higher, available: no, dongleVersion: version, currentVersion: ledger.fup.versions.Nano.CurrentVersion.Os)
      else
        d.resolve(result: FirmwareAvailabilityResult.Update, available: yes, dongleVersion: version, currentVersion: ledger.fup.versions.Nano.CurrentVersion.Os)
    d.promise

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

  _cancelRequest: (request) ->
    @_request = null if request is @_request

  load: (callback) ->
    require ledger.fup.imports, (scripts) =>
      @_scripts = scripts
      ledger.fup.setupUpdates()
      callback?()

  unload: () ->
    ledger.fup.clearUpdates()
    l @_scripts
    for script in @_scripts
      $(script).remove()
