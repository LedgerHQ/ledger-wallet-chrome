
class ledger.api.GrooveRestClient extends ledger.api.RestClient

  sendTicket: (body, email, name, subject, tags, metadata, logs, callback=undefined) ->
    @http().post
      url: "support/ticket",
      data: {
        "body": body,
        "email": email,
        "name": name,
        "subject": subject,
        "tags": [tags],
        "metadata": metadata,
        "logs": logs
      }
      onSuccess: (response) ->
        callback?(l response)
      onError: @networkErrorCallback(callback)
