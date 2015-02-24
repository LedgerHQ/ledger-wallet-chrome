
class ledger.api.M2faRestClient extends ledger.api.AuthRestClient

  @instance: new @

  wakeUpSecureScreens: (pairingIds, callback = _.noop) ->
    l 'WAKE UP'
    @http().post
      url: '2fa/pairings/wake_up'
      data: {pairing_ids: pairingIds}
      onSuccess: callback
      onError: @networkErrorCallback(callback)