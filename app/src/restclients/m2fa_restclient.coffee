
class ledger.api.M2faRestClient extends ledger.api.AuthRestClient

  @instance: new @

  wakeUpSecureScreens: (pairingIds, callback = _.noop) ->
    @http.post url: '2fa/pairings/wake_up', data: {pairing_ids: pairingIds}
    .then callback
    .fail @networkErrorCallback(callback)
    .done()