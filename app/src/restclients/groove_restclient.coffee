
class ledger.api.GrooveRestClient extends ledger.api.RestClient

  sendTicket: (data, callback = undefined) ->
    @_createTicket data, (ticket, error) =>
      if error?
        callback?(false)
      else
        # if logs are attached
        if data.zip?
          @_attachLogs data, ticket, (response, error) =>
            callback(not error?)
        else
          callback?(true)

  _createTicket: (data, callback = undefined) ->
    # post ticket
    @http().post
      url: "support/ticket",
      data: {
        "body": data.message,
        "email": data.email,
        "name": data.name,
        "subject": data.subject,
        "tags": [data.tag],
        "metadata": data.metadata,
        "has_logs": data.zip?
      }
      onSuccess: (response) => callback?(response)
      onError: @networkErrorCallback(callback)

  _attachLogs: (data, ticket, callback = undefined) ->
    # post file
    @http().postFile
      url: "support/ticket/" + ticket.id,
      data: {
        "logFile": data.zip
      }
      onSuccess: (response) => callback?(response)
      onError: @networkErrorCallback(callback)