ledger.specs.fixtures ?= {}

_.extend ledger.specs.fixtures,

  dongle1_transactions:
    tx1:
      "hash": "aa1a80314f077bd2c0e335464f983eef56dfeb0eb65c99464a0e5dbe2c25b7dc",
      "block_hash": "000000000000000006c18384552d198dc53dcdd63964d9887693f684ca0aeeb6",
      "block_height": 330760,
      "block_time": "2014-11-19T20:38:15Z",
      "chain_received_at": "2014-11-19T20:15:46.678Z",
      "confirmations": 30845,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "aa1a80314f077bd2c0e335464f983eef56dfeb0eb65c99464a0e5dbe2c25b7dc",
        "output_hash": "4e23da1b1438939bc4f71bd6d8ec34a99bad83c3a68de6d8e278cdf306b48016",
        "output_index": 0,
        "value": 69000,
        "addresses": ["18SxWu7S3Y4wtZG4eQ8fk8UERN2zko2i7Z"],
        "script_signature": "30440220799ee9f5f644cb34e2da29c48f613146f695b57b96ab6626830aba636965e2c10220076593fc1f9c7bd7efa97fa78bbc0fa5c5f83a6bf26a6b3cdce520339f14d8ac01 0372c277f4e2951ed88978b74f2d0cd400e71972ad40bd78b5b7ed992ed0371906",
        "script_signature_hex": "4730440220799ee9f5f644cb34e2da29c48f613146f695b57b96ab6626830aba636965e2c10220076593fc1f9c7bd7efa97fa78bbc0fa5c5f83a6bf26a6b3cdce520339f14d8ac01210372c277f4e2951ed88978b74f2d0cd400e71972ad40bd78b5b7ed992ed0371906",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "aa1a80314f077bd2c0e335464f983eef56dfeb0eb65c99464a0e5dbe2c25b7dc",
        "output_index": 0,
        "value": 58000,
        "addresses": ["1EPjG6nHiqmMtpXVq9g6YBwaiTw4uEGvZ5"],
        "script": "OP_DUP OP_HASH160 92e61041bc1c23f9195d34888d0f96515f01c348 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a91492e61041bc1c23f9195d34888d0f96515f01c34888ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "f178f5043ba6781f2a88ef1aa3fcbdbfbc1e793982e757ff8957414c134a1691"
      }, {
        "transaction_hash": "aa1a80314f077bd2c0e335464f983eef56dfeb0eb65c99464a0e5dbe2c25b7dc",
        "output_index": 1,
        "value": 10000,
        "addresses": ["1L36ug5kWFLbMysfkAexh9LeicyMAteuEg"],
        "script": "OP_DUP OP_HASH160 d0d0275954563c521297a1d277b4045548639d15 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914d0d0275954563c521297a1d277b4045548639d1588ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "115886c56fff5781bf6a0a1e36330d5f68ac814751bce71e41daf06868fbe446"
      }],
      "fees": 1000,
      "amount": 68000,
      "inputs_length": 1,
      "outputs_length": 2

    tx2:
      "hash": "a863b9a56c40c194c11eb9db9f3ea1f6ab472b02cc57679c50d16b4151c8a6e5",
      "block_hash": "00000000000000000d89f88366661b880e96aba60d083daac990fd21dd97fa5e",
      "block_height": 330757,
      "block_time": "2014-11-19T20:04:46Z",
      "chain_received_at": "2014-11-19T19:53:57.088Z",
      "confirmations": 30848,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "a863b9a56c40c194c11eb9db9f3ea1f6ab472b02cc57679c50d16b4151c8a6e5",
        "output_hash": "9c832719de7460ab4c4da5b276b591b21baf4afcd9aae42fb32c71e772080e73",
        "output_index": 0,
        "value": 100000,
        "addresses": ["1FDJMgjuC7A4HkZt6fx8caFfuLDyp4YS9L"],
        "script_signature": "3045022100ad515b1bc1018817a174e6708eb24dbb24efe42a140b008b0b70d68bc4be46ee022003d9ffd685bac22be1c46a65a061ff8e9ca89663284a6bdcb06ba987e2c2a13301 03c966f445598dc9071a4c7030f940a2aacbcb7c892203886dbc1f77c76b79a134",
        "script_signature_hex": "483045022100ad515b1bc1018817a174e6708eb24dbb24efe42a140b008b0b70d68bc4be46ee022003d9ffd685bac22be1c46a65a061ff8e9ca89663284a6bdcb06ba987e2c2a133012103c966f445598dc9071a4c7030f940a2aacbcb7c892203886dbc1f77c76b79a134",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "a863b9a56c40c194c11eb9db9f3ea1f6ab472b02cc57679c50d16b4151c8a6e5",
        "output_index": 0,
        "value": 89000,
        "addresses": ["1KBTvmpXp3A2zhZrzuVLneEeUZJQ1qMzCF"],
        "script": "OP_DUP OP_HASH160 c76ce6beeb0884c9513bcf779144950f9525f8e9 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914c76ce6beeb0884c9513bcf779144950f9525f8e988ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "d1c90810c08827e26e33a9a7e5a37703d3cb55b155f3c6900f88743fe9e91421"
      }, {
        "transaction_hash": "a863b9a56c40c194c11eb9db9f3ea1f6ab472b02cc57679c50d16b4151c8a6e5",
        "output_index": 1,
        "value": 10000,
        "addresses": ["18tMkbibtxJPQoTPUv8s3mSXqYzEsrbeRb"],
        "script": "OP_DUP OP_HASH160 567f6acc93fe0349b604f45f46b540f55059abbb OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914567f6acc93fe0349b604f45f46b540f55059abbb88ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "b37dd0fa5e62497939367efee9a9cd90383473e798a260e20eb9a37ec05868a6"
      }],
      "fees": 1000,
      "amount": 99000,
      "inputs_length": 1,
      "outputs_length": 2

    tx3:
      "hash": "e43810f91bf8aa66f8558437d532410a0f62f3d3ee45417b6f6335ffcdb6c721",
      "block_hash": "00000000000000000d89f88366661b880e96aba60d083daac990fd21dd97fa5e",
      "block_height": 330757,
      "block_time": "2014-11-19T20:04:46Z",
      "chain_received_at": "2014-11-19T20:01:11.576Z",
      "confirmations": 30848,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "e43810f91bf8aa66f8558437d532410a0f62f3d3ee45417b6f6335ffcdb6c721",
        "output_hash": "0b577adc127339768ca109550d3242e5a6a55367b376748d8f6f2b54cd7057e3",
        "output_index": 0,
        "value": 7437000,
        "addresses": ["1DZRBBjx2L1urJmzpwDoZH51gX2XSgwvk7"],
        "script_signature": "304402202db4e13f0b773a96d107e71ccaf69b44fb9a025ad80d79c4c672ffed573be75f022013f1f04c60393c614ce53d05063d8653db467c37bd0c626eb2ba4a93811ea14501 039d937dbef6142c4177152afad9ed93f81da538b48ba1f05bea87ef8064aff2e1",
        "script_signature_hex": "47304402202db4e13f0b773a96d107e71ccaf69b44fb9a025ad80d79c4c672ffed573be75f022013f1f04c60393c614ce53d05063d8653db467c37bd0c626eb2ba4a93811ea1450121039d937dbef6142c4177152afad9ed93f81da538b48ba1f05bea87ef8064aff2e1",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "e43810f91bf8aa66f8558437d532410a0f62f3d3ee45417b6f6335ffcdb6c721",
        "output_index": 0,
        "value": 10000,
        "addresses": ["1KZB7aFfuZE2skJQPHH56VhSxUpUBjouwQ"],
        "script": "OP_DUP OP_HASH160 cb88045ebe75f5e94633d27dffca389cde381b78 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914cb88045ebe75f5e94633d27dffca389cde381b7888ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "115886c56fff5781bf6a0a1e36330d5f68ac814751bce71e41daf06868fbe446"
      }, {
        "transaction_hash": "e43810f91bf8aa66f8558437d532410a0f62f3d3ee45417b6f6335ffcdb6c721",
        "output_index": 1,
        "value": 7426000,
        "addresses": ["12XgKxQd5ZmeTjZVXiEpsGuoTr745GaHxF"],
        "script": "OP_DUP OP_HASH160 10c56ed9bad6951e36c3d49de11cd29928dc5669 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a91410c56ed9bad6951e36c3d49de11cd29928dc566988ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "41b961f740f2577d8a489dc1ab34ae985e6b0f17e790705e3bc33a7d94dbb248"
      }],
      "fees": 1000,
      "amount": 7436000,
      "inputs_length": 1,
      "outputs_length": 2

    tx4:
      "hash": "4e23da1b1438939bc4f71bd6d8ec34a99bad83c3a68de6d8e278cdf306b48016",
      "block_hash": "00000000000000000d89f88366661b880e96aba60d083daac990fd21dd97fa5e",
      "block_height": 330757,
      "block_time": "2014-11-19T20:04:46Z",
      "chain_received_at": "2014-11-19T19:57:43.888Z",
      "confirmations": 30848,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "4e23da1b1438939bc4f71bd6d8ec34a99bad83c3a68de6d8e278cdf306b48016",
        "output_hash": "e1f49c35c83cabbd7a20895de1d27cc374a4667ea40ccd2e27fe66ec574437b1",
        "output_index": 0,
        "value": 80000,
        "addresses": ["1FDJMgjuC7A4HkZt6fx8caFfuLDyp4YS9L"],
        "script_signature": "3044022011d5413262ea45452f40450da2e534775568f9680e4b342b5d6ae01e1d86a855022019b8a0517b195eeefcaba7f2a2e8c5d6d95e2b00eeca3d6bdd73c9fe0db68cc601 03c966f445598dc9071a4c7030f940a2aacbcb7c892203886dbc1f77c76b79a134",
        "script_signature_hex": "473044022011d5413262ea45452f40450da2e534775568f9680e4b342b5d6ae01e1d86a855022019b8a0517b195eeefcaba7f2a2e8c5d6d95e2b00eeca3d6bdd73c9fe0db68cc6012103c966f445598dc9071a4c7030f940a2aacbcb7c892203886dbc1f77c76b79a134",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "4e23da1b1438939bc4f71bd6d8ec34a99bad83c3a68de6d8e278cdf306b48016",
        "output_index": 0,
        "value": 69000,
        "addresses": ["18SxWu7S3Y4wtZG4eQ8fk8UERN2zko2i7Z"],
        "script": "OP_DUP OP_HASH160 51b19f1c87c6ad9a5eaa45dc48a67c2c63002311 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a91451b19f1c87c6ad9a5eaa45dc48a67c2c6300231188ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "aa1a80314f077bd2c0e335464f983eef56dfeb0eb65c99464a0e5dbe2c25b7dc"
      }, {
        "transaction_hash": "4e23da1b1438939bc4f71bd6d8ec34a99bad83c3a68de6d8e278cdf306b48016",
        "output_index": 1,
        "value": 10000,
        "addresses": ["1GJr9FHZ1pbR4hjhX24M4L1BDUd2QogYYA"],
        "script": "OP_DUP OP_HASH160 a7e9fadcc36932a2d00e821f531584dcf65b917d OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914a7e9fadcc36932a2d00e821f531584dcf65b917d88ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "115886c56fff5781bf6a0a1e36330d5f68ac814751bce71e41daf06868fbe446"
      }],
      "fees": 1000,
      "amount": 79000,
      "inputs_length": 1,
      "outputs_length": 2

    tx5:
      "hash": "0b577adc127339768ca109550d3242e5a6a55367b376748d8f6f2b54cd7057e3",
      "block_hash": "00000000000000001447d39f0d7a400879038d950d88ef4b2c24f4383446b071",
      "block_height": 330738,
      "block_time": "2014-11-19T17:52:51Z",
      "chain_received_at": "2014-11-19T17:19:45.940Z",
      "confirmations": 30867,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "0b577adc127339768ca109550d3242e5a6a55367b376748d8f6f2b54cd7057e3",
        "output_hash": "a87463e2852ef5467a9d87b7a7d1095899d1e5893613d9f62b9d11c27630ef0a",
        "output_index": 1,
        "value": 7538000,
        "addresses": ["13VAufAUHFAZ4tKGUcZtvM5dgzgMcxgX1o"],
        "script_signature": "304402200dc547ac3c674aceba8442480432e36a26eac72f6515a3ce69b9eb8251af2a6802201fb47476886829f76c53e8be8fd096589b220dfbc879bf36b65294444412d66701 0322b82d653b864af6a7a27812c9b719b06b93a73e1c270ab4535843f9f6a04ebc",
        "script_signature_hex": "47304402200dc547ac3c674aceba8442480432e36a26eac72f6515a3ce69b9eb8251af2a6802201fb47476886829f76c53e8be8fd096589b220dfbc879bf36b65294444412d66701210322b82d653b864af6a7a27812c9b719b06b93a73e1c270ab4535843f9f6a04ebc",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "0b577adc127339768ca109550d3242e5a6a55367b376748d8f6f2b54cd7057e3",
        "output_index": 0,
        "value": 7437000,
        "addresses": ["1DZRBBjx2L1urJmzpwDoZH51gX2XSgwvk7"],
        "script": "OP_DUP OP_HASH160 89c3003f16a73b05429269807ad29ed5cb2dd096 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a91489c3003f16a73b05429269807ad29ed5cb2dd09688ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "e43810f91bf8aa66f8558437d532410a0f62f3d3ee45417b6f6335ffcdb6c721"
      }, {
        "transaction_hash": "0b577adc127339768ca109550d3242e5a6a55367b376748d8f6f2b54cd7057e3",
        "output_index": 1,
        "value": 100000,
        "addresses": ["151krzHgfkNoH3XHBzEVi6tSn4db7pVjmR"],
        "script": "OP_DUP OP_HASH160 2c051dfed45971ba30473de4b4e57278bd9f001e OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a9142c051dfed45971ba30473de4b4e57278bd9f001e88ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "74c666f98467acccdf75de2bb1fbd8282c9be8afb25b438ab2d6354d6c689f62"
      }],
      "fees": 1000,
      "amount": 7537000,
      "inputs_length": 1,
      "outputs_length": 2