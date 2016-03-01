class @Output extends ledger.database.Model
  do @init

  @index 'uid'

  ###
    {
       "output_index": 0,
        "value": 1000000,
        "addresses": [
          "18VLgzpLjLMRB8udaSrs4ha8gwzjzVgHUT"
        ],
        "script_hex": "76a9145224f6a5cbfa97dbe098bd72c1813c60982ff04e88ac"
    }
  ###
  @fromJson: (transactionHash, output, context = ledger.database.contexts.main) ->
    uid = "#{transactionHash}_#{input['output_index']}"
    base =
      uid: uid
      transaction_hash: transactionHash
      value: input['value']
      address: input['addresses'][0]
      script_hex: input['script_hex']
    @findOrCreate(uid: uid, base, context)