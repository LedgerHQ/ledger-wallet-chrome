
class ledger.api.M2faRestClient extends ledger.api.RestClient

  @instance: new @

  wakeUpSecureScreens: (pairingIds, callback = _.noop) ->
    @http().authenticated().post
      url: '2fa/pairings/wake_up'
      data: {pairing_ids: pairingIds}
      onSuccess: callback
      onError: @networkErrorCallback(callback)