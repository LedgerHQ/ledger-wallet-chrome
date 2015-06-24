
ledger.bitcoin ?= {}

_.extend ledger.bitcoin,

  decodeTransaction: (hexTransaction) ->
    { Transaction, TransactionIn, TransactionOut } = window.Bitcoin

    # Parse an bytearray of length `size` as an integer
    # Works for numbers up to 32-bit only
    parse_int = (size) -> (bytes) ->
      n = 0
      n += (bytes.shift() & 0xff) << (8 * i) for i in [0...size]
      n
    u8  = (bytes) -> bytes.shift()
    u16 = parse_int 2
    u32 = parse_int 4
    # 64 bit numbers are kept as bytes
    # (bitcoinjs-lib expects them that way)
    u64 = (bytes) -> bytes.splice 0, 8

    # https://en.bitcoin.it/wiki/Protocol_specification#Variable_length_integer
    varint = (bytes) ->
      switch n = u8 bytes
        when 0xfd then u16 bytes
        when 0xfe then u32 bytes
        when 0xff then u64 bytes
        else n

    # https://en.bitcoin.it/wiki/Protocol_specification#Variable_length_string
    varchar = (bytes) -> bytes.splice 0, varint bytes

    bytes = (parseInt(byte, 16) for byte in hexTransaction.match(/\w\w/g))
    bytes = bytes.slice() # clone
    ver = u32 bytes
    throw new Error 'Unsupported version' unless ver is 0x01

    tx = new Transaction

    # Parse inputs
    in_count = varint bytes
    for [0...in_count]
      tx.addInput new TransactionIn
        outpoint:
          hash: base64ArrayBuffer bytes.splice 0, 32
          index: u32 bytes
        script: varchar bytes
        seq: u32 bytes

    # Parse outputs
    out_count = varint bytes
    for [0...out_count]
      tx.addOutput new TransactionOut
        value: u64 bytes
        script: varchar bytes

    tx.lock_time = u32 bytes
    tx

  verifyRawTx: (tx, inputs, amount, fees, recipientAddress, changeAddress) ->
    Try =>
      try
        transaction = ledger.bitcoin.decodeTransaction(tx)
        inputAmount = ledger.Amount.fromSatoshi(0)
        inputAmount = inputAmount.add input.value for input in inputs
        changeAmount = inputAmount.subtract(amount).subtract(fees)
        if changeAmount.gt 0
          changeOutput = _.find transaction.outs, (output) -> output.address.toString() is changeAddress
          throw ledger.errors.new(ledger.errors.ChangeAddressNotFound) unless changeOutput?
          throw ledger.errors.new(ledger.errors.InvalidChangeAmount) unless changeAmount.eq(changeOutput.value)
        recipientOutput = _.find transaction.outs, (output) -> output.address.toString() is recipientAddress
        throw ledger.errors.new(ledger.errors.RecipientAddressNotFound) unless recipientAddress?
        throw ledger.errors.new(ledger.errors.InvalidRecipientAmount) unless amount.eq(recipientOutput.value)
        yes
      catch er
        e er
        throw er


