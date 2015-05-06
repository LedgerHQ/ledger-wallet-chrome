
class ledger.api.GrooveRestClient extends ledger.api.RestClient

  sendTicket: (body, email, name, subject, tags, metadata, logs, callback=undefined) ->
    @http().post
      url: "support/ticket",
      data: {
        "body": body,
        "email": email,
        "name": name,
        "subject": subject,
        "tags": tags,
        "metadata": metadata
      }
      onSuccess: (resp) =>
        if logs?
          @http().postFile
            url: "support/ticket/" + resp.id,
            data: {
              "logFile": logs
            }
      onError: @networkErrorCallback(callback)
