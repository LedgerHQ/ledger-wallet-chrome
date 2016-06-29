class @Input extends ledger.database.Model
  do @init

  @index 'uid'

  ###
    {
      "output_hash": "a8e499e551c4729ae74bf2136d3e046601e68f09ae30ed187bd772fc375a772e",
      "output_index": 0,
      "input_index": 0,
      "value": 1000000,
      "addresses": [
        "1Jt4tMBHBgiGcVFEDZKAEjqvqWxSUZrJxR"
      ],
      "script_signature": "473044022064dd34233b584ef220049a012294e50c0d05b9b1131843fad89982fc055af6d102202d2d96055859857a96702ebb8167eec2aae3e3269309432943c7f92718efcd8601210387ec9eb50e00c73984917d12610919d945c16ef1f52454306a8757368c004e7b"
  }
  ###
  @fromJson: (input, context = ledger.database.contexts.main) ->
    uid = "#{input['output_hash']}_#{input['output_index']}"
    base =
      uid: uid
      previous_tx: input['output_hash']
      output_index: input['output_index']
      value: input['value']
      address: input['addresses'][0]
      script_signature: input['script_signature']
    @findOrCreate(uid: uid, base, context)