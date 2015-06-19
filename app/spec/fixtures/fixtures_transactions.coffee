ledger.specs.fixtures ?= {}

_.extend ledger.specs.fixtures,

  dongle1_transactions:
    tx1:
      "hash": "8948c83079e83a1e88140a25224bfde4f25e70ded7d51eccb306b7d8729acd38",
      "block_hash": "00000000000000000622ff7c71c105480baf123fe74df549b5a42596fd8bfbcb",
      "block_height": 355383,
      "block_time": "2015-05-07T15:12:02Z",
      "chain_received_at": "2015-05-07T15:02:35.149Z",
      "confirmations": 6087,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "8948c83079e83a1e88140a25224bfde4f25e70ded7d51eccb306b7d8729acd38",
        "output_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_index": 0,
        "value": 1000000,
        "addresses": ["13X9bcSY1UXwAwz6WaScAMFawpeTnPn1VU"],
        "script_signature": "304502210081b31bc113614c25b7cddb11df5d8a982452efe4659413627d09cb1ee145f26a022005eba0b7f8386bfcbd540b4316714af4db9fbe031ea02bd404f6f987f0aca1f001 027337b295641dee05083f80ddd804d05038dd32120f95854ffd2d5f99429bf64c",
        "script_signature_hex": "48304502210081b31bc113614c25b7cddb11df5d8a982452efe4659413627d09cb1ee145f26a022005eba0b7f8386bfcbd540b4316714af4db9fbe031ea02bd404f6f987f0aca1f00121027337b295641dee05083f80ddd804d05038dd32120f95854ffd2d5f99429bf64c",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "8948c83079e83a1e88140a25224bfde4f25e70ded7d51eccb306b7d8729acd38",
        "output_index": 0,
        "value": 990000,
        "addresses": ["1KeXdmtQx47z2Yk1vEmZbFaFeQiPyHnCUQ"],
        "script": "OP_DUP OP_HASH160 cc8b3a08d0a6f72322659a807559ad9b6d8d8ebf OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914cc8b3a08d0a6f72322659a807559ad9b6d8d8ebf88ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": false
      }],
      "fees": 10000,
      "amount": 990000,
      "inputs_length": 1,
      "outputs_length": 1

    tx2:
      "hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
      "block_hash": "00000000000000000c482dd8b8c8fe10972499437f277b6cc1af379abe1e2f4d",
      "block_height": 352137,
      "block_time": "2015-04-14T18:39:50Z",
      "chain_received_at": "2015-04-14T18:26:48.419Z",
      "confirmations": 9333,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_hash": "4096062b63b089fda5c1b02f92a6d690384e1d84a9c87fd0deeb5c1e68aa88fd",
        "output_index": 0,
        "value": 100000,
        "addresses": ["1syUnMSfijBKvYzWgQWB2YbAC2Pm4LUpe"],
        "script_signature": "304402203b219ae251a88f798788356c35b1cf2371544eb99395ac7f769706bd8299a6c202202e8f70158d3174a817723d0aa9855000b76355e5f524de5dea9cf7029db918d301 03b6baa018cf705f0f58e1089106972f3d5287a98594cac2b1befc4f32c770443a",
        "script_signature_hex": "47304402203b219ae251a88f798788356c35b1cf2371544eb99395ac7f769706bd8299a6c202202e8f70158d3174a817723d0aa9855000b76355e5f524de5dea9cf7029db918d3012103b6baa018cf705f0f58e1089106972f3d5287a98594cac2b1befc4f32c770443a",
        "sequence": -1
      }, {
        "transaction_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_hash": "ad435f9c86dfbc13b3accd962439eb2e6d9084da3c6b080b071a7c6fdb483cfe",
        "output_index": 1,
        "value": 100000,
        "addresses": ["1CEWfW8L6tKz4ak2EcwBnZTJwSaYceDEK9"],
        "script_signature": "3044022077d2ac0f1b2cb8a18eda5ca2931726b68880771dadddf766c82c1ea33f2dec0c02203e7a733d35c7d75a34ff16391c30478e1da8066c7a99a7c2910b172dc3ffd1f101 02439f792dc1cb17263eabe5f3aa4d5c2f6ef1eac866761a93d1786a893fd854b1",
        "script_signature_hex": "473044022077d2ac0f1b2cb8a18eda5ca2931726b68880771dadddf766c82c1ea33f2dec0c02203e7a733d35c7d75a34ff16391c30478e1da8066c7a99a7c2910b172dc3ffd1f1012102439f792dc1cb17263eabe5f3aa4d5c2f6ef1eac866761a93d1786a893fd854b1",
        "sequence": -1
      }, {
        "transaction_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_hash": "5c1c3d511da7788d148042d60c92f9837d9c6518b3f83256d429d909f7a082db",
        "output_index": 0,
        "value": 100000,
        "addresses": ["1CEWfW8L6tKz4ak2EcwBnZTJwSaYceDEK9"],
        "script_signature": "304402201c9243364a87a2fe8564ac9024baeafead76a0a3a71983b4cbcc6dbf21f7652102200c0a6b2b92b8a13139345cb6f1a79a4445c0eaa1ccd74ad6f5628053ec5dacf501 02439f792dc1cb17263eabe5f3aa4d5c2f6ef1eac866761a93d1786a893fd854b1",
        "script_signature_hex": "47304402201c9243364a87a2fe8564ac9024baeafead76a0a3a71983b4cbcc6dbf21f7652102200c0a6b2b92b8a13139345cb6f1a79a4445c0eaa1ccd74ad6f5628053ec5dacf5012102439f792dc1cb17263eabe5f3aa4d5c2f6ef1eac866761a93d1786a893fd854b1",
        "sequence": -1
      }, {
        "transaction_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_hash": "4096062b63b089fda5c1b02f92a6d690384e1d84a9c87fd0deeb5c1e68aa88fd",
        "output_index": 1,
        "value": 74082490,
        "addresses": ["1HnL5SP3e4FzbvgkRBtrE32Sk42umX92MK"],
        "script_signature": "30440220777772cf4c2326c45f9b7d95e20132d7a9ee57eb03e679d01cc9435e690bf7f302205d63e99c11aed8d13df8944e8ada9f70129859d4c1911c9f60df13138551723d01 035f49bed8193a7caa919ce280cfa3d34cd10e91ad356a78b8a116fc3c4fabe895",
        "script_signature_hex": "4730440220777772cf4c2326c45f9b7d95e20132d7a9ee57eb03e679d01cc9435e690bf7f302205d63e99c11aed8d13df8944e8ada9f70129859d4c1911c9f60df13138551723d0121035f49bed8193a7caa919ce280cfa3d34cd10e91ad356a78b8a116fc3c4fabe895",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_index": 0,
        "value": 1000000,
        "addresses": ["13X9bcSY1UXwAwz6WaScAMFawpeTnPn1VU"],
        "script": "OP_DUP OP_HASH160 1ba3e81841540c1c0d4b640facdde1fcfa42a559 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a9141ba3e81841540c1c0d4b640facdde1fcfa42a55988ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "8948c83079e83a1e88140a25224bfde4f25e70ded7d51eccb306b7d8729acd38"
      }, {
        "transaction_hash": "f5b25cedce89e212d92eb595a13eafc14a4235c1e5d9c504c6d22ee70ea03629",
        "output_index": 1,
        "value": 73372490,
        "addresses": ["1HFvgjYkWBEQLuXgRkYcY7YvyEhMLnZ7QQ"],
        "script": "OP_DUP OP_HASH160 b254a668e65a94fee1aacf14f5e376fded407f58 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914b254a668e65a94fee1aacf14f5e376fded407f5888ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "3dd600538add737bff3a4916f7de1e61e22ce828c9d2ee3557f62aca0031d2dc"
      }],
      "fees": 10000,
      "amount": 74372490,
      "inputs_length": 4,
      "outputs_length": 2

    tx3:
      "hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
      "block_hash": "00000000000000001088c5e8ebe8daf577fdb80c233ba0f184ba08c0bd9549e3",
      "block_height": 331401,
      "block_time": "2014-11-24T10:55:27Z",
      "chain_received_at": "2014-11-24T10:54:38.862Z",
      "confirmations": 30069,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "40c899026bcac33b82e28a7f8a3d9d624a3abfdc67f32402d95391a4f3070339",
        "output_index": 1,
        "value": 1000000,
        "addresses": ["1LR8aAwQbJRMjSDb9a6yfC9eVfZu5SRY3F"],
        "script_signature": "30450221008d292ae5567b51cf923cf3c448b31fc162863c3a0411b74521fee12f37c643cf022026063e26d1a424fda49f3352b3dfb32bce6e67059d37d1e360fcb4a50559e9dc01 03cb43d62dcb685edcb182738615f64f12d98b8ee35dc4f2df491478ba769ce1c9",
        "script_signature_hex": "4830450221008d292ae5567b51cf923cf3c448b31fc162863c3a0411b74521fee12f37c643cf022026063e26d1a424fda49f3352b3dfb32bce6e67059d37d1e360fcb4a50559e9dc012103cb43d62dcb685edcb182738615f64f12d98b8ee35dc4f2df491478ba769ce1c9",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "ef151f4f72d516efc59c14236d50dd2075f3f01d73516aebc15896b8f34d53bc",
        "output_index": 0,
        "value": 100000,
        "addresses": ["16q3r12wBrcPcEwiQXhiBxaahH8U7JE62q"],
        "script_signature": "304402204a3b283b6e11d8ec42434e26e2580e2a552283bcf52078fc1c30383f25c2589102204869ed9c89b80aaf38031fccfc2d426611f960b95fc7297a9b559c78089ee70a01 0245efaa88dc39dfd5eaa4c567689aa6a5024460e037079a4d223b363bc5cdd729",
        "script_signature_hex": "47304402204a3b283b6e11d8ec42434e26e2580e2a552283bcf52078fc1c30383f25c2589102204869ed9c89b80aaf38031fccfc2d426611f960b95fc7297a9b559c78089ee70a01210245efaa88dc39dfd5eaa4c567689aa6a5024460e037079a4d223b363bc5cdd729",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "b37dd0fa5e62497939367efee9a9cd90383473e798a260e20eb9a37ec05868a6",
        "output_index": 1,
        "value": 8000,
        "addresses": ["1DYvv8T2q2UFv9hQnbLaPZAuQw8mYx3DAD"],
        "script_signature": "3045022100f7fd920e9c49b74c57872b4583f4267db14048879025485f0a2ae97a8a958f4a022034a8dad82c66a4d343861d91f354fb18c741bf00b7b18592aabea4c1e04b115101 02bfd269c86f714f06b7a42acce8d1794520189506c706065de8c5fff905624935",
        "script_signature_hex": "483045022100f7fd920e9c49b74c57872b4583f4267db14048879025485f0a2ae97a8a958f4a022034a8dad82c66a4d343861d91f354fb18c741bf00b7b18592aabea4c1e04b1151012102bfd269c86f714f06b7a42acce8d1794520189506c706065de8c5fff905624935",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "115886c56fff5781bf6a0a1e36330d5f68ac814751bce71e41daf06868fbe446",
        "output_index": 0,
        "value": 9000,
        "addresses": ["1F2arsfX5JEDryBVftmzbVFWaGsJaTVwcg"],
        "script_signature": "3044022051084b7cbc7e83bfdbd3563dadea667ed9bfce4e8ee1d6f7863ff628b7085dfe0220039d28a471abeb6711e3a83acca49eb0b9fc9300a64ac54653ce048e285f326201 029592cad3c41421d83c3926e45ff084b99f0264ece9b2f582527a2cbbe95a00a3",
        "script_signature_hex": "473044022051084b7cbc7e83bfdbd3563dadea667ed9bfce4e8ee1d6f7863ff628b7085dfe0220039d28a471abeb6711e3a83acca49eb0b9fc9300a64ac54653ce048e285f32620121029592cad3c41421d83c3926e45ff084b99f0264ece9b2f582527a2cbbe95a00a3",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "b06df358f0cb8fb16b9a43ec697f538e19525ff947cee495a174715e635813d2",
        "output_index": 0,
        "value": 9000,
        "addresses": ["1PUrJgftNnHvvqVyEsm9DiCDQuZHCn47fQ"],
        "script_signature": "304402204fa4b788543e714e52b6967a6e81921c6b8bb59bdef7a58327ec66a0a05e14ca02201dbd81ec9eb2002ad3d550f05b63cc5b6f88f66253183f173c082cc929d9ee0201 033a73f9c796b4f2cd3d6d34bc33b6c80759829bc1fed4772d09311a3f03f37c31",
        "script_signature_hex": "47304402204fa4b788543e714e52b6967a6e81921c6b8bb59bdef7a58327ec66a0a05e14ca02201dbd81ec9eb2002ad3d550f05b63cc5b6f88f66253183f173c082cc929d9ee020121033a73f9c796b4f2cd3d6d34bc33b6c80759829bc1fed4772d09311a3f03f37c31",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "6d0606dbbb02a089cc2613340b188aacb0a9aba3634dcc916bdc4136c076d701",
        "output_index": 1,
        "value": 93000,
        "addresses": ["17YWeEfgXFnD6PGmm7DK5nVB7PtxsP5nvT"],
        "script_signature": "3045022100f0d2efd1918b2a2a0e810915cf4458b2602707e90108204295a555ac90fa2c11022045e9a17edc65f49c871df293b9221580a72a39c0873c6d3ea3b2127f60d1597701 027e2f335a6e472c65955ac8fca234a1452fa2256ba2e3999d951da7721b0a5eda",
        "script_signature_hex": "483045022100f0d2efd1918b2a2a0e810915cf4458b2602707e90108204295a555ac90fa2c11022045e9a17edc65f49c871df293b9221580a72a39c0873c6d3ea3b2127f60d159770121027e2f335a6e472c65955ac8fca234a1452fa2256ba2e3999d951da7721b0a5eda",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "1de98fbfd053799bcb0c215d28697ef81c4203f4e8d5f416b42317cbd86df6fa",
        "output_index": 1,
        "value": 89000,
        "addresses": ["1Q61WZ6sixTvd8JaH2qimkXAWFBR2MdBwu"],
        "script_signature": "3044022042ff4eff7a01718cdabd4521b0585f2766bdcfa47dbbba93c7b0851b415fa6fc0220418d495bc905c80c8d122382dfd0b932a1e538cb556e73ed548af7f5e7afaebe01 03a42dfcfa0c037216bdeee0d6edd9fc9a9e934a83adcfbfe59f9bb6e27ed46f98",
        "script_signature_hex": "473044022042ff4eff7a01718cdabd4521b0585f2766bdcfa47dbbba93c7b0851b415fa6fc0220418d495bc905c80c8d122382dfd0b932a1e538cb556e73ed548af7f5e7afaebe012103a42dfcfa0c037216bdeee0d6edd9fc9a9e934a83adcfbfe59f9bb6e27ed46f98",
        "sequence": -1
      }, {
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_hash": "c4dbc4ff61d53a06610d0ed2df2e0a7862ce21257146d60f5279ccac0423704e",
        "output_index": 0,
        "value": 70000,
        "addresses": ["18eo3f1pMkpSZH4hRF4bXV9yVSgKasktZo"],
        "script_signature": "30450221008649c8456db87724e28ba188d783f9d42f7568d5591f3bbca285fccf7b1fc4b90220730004e39fed83096f8d1eb3c7cb23cc17b980431dd6906ba76a2593ae639d5501 03e8dc38f6445bc1ec562585d44cc4aeac21174ce60cab8c82694ea1d0add99493",
        "script_signature_hex": "4830450221008649c8456db87724e28ba188d783f9d42f7568d5591f3bbca285fccf7b1fc4b90220730004e39fed83096f8d1eb3c7cb23cc17b980431dd6906ba76a2593ae639d55012103e8dc38f6445bc1ec562585d44cc4aeac21174ce60cab8c82694ea1d0add99493",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0",
        "output_index": 0,
        "value": 1368000,
        "addresses": ["12ESy23b2Dz6ytJ78uq1sgWwBrXAB3fwxv"],
        "script": "OP_DUP OP_HASH160 0d83355e310ff8296d5f5f2ffc420d3ce6cbaca8 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a9140d83355e310ff8296d5f5f2ffc420d3ce6cbaca888ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "80a04db67f0c9fdd3d6d6f1b5196bb0d00c2225f459ccd48fdb8f8de51a6fbbc"
      }],
      "fees": 10000,
      "amount": 1368000,
      "inputs_length": 8,
      "outputs_length": 1

    tx4:
      "hash": "ef151f4f72d516efc59c14236d50dd2075f3f01d73516aebc15896b8f34d53bc",
      "block_hash": "0000000000000000016140827507f55fd68efc1fbd04e1e7644b09dae833143e",
      "block_height": 331004,
      "block_time": "2014-11-21T17:45:36Z",
      "chain_received_at": "2014-11-21T16:46:32.455Z",
      "confirmations": 30466,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "ef151f4f72d516efc59c14236d50dd2075f3f01d73516aebc15896b8f34d53bc",
        "output_hash": "6d0606dbbb02a089cc2613340b188aacb0a9aba3634dcc916bdc4136c076d701",
        "output_index": 0,
        "value": 100000,
        "addresses": ["12ESy23b2Dz6ytJ78uq1sgWwBrXAB3fwxv"],
        "script_signature": "304402206f05fa893e723d17f972ea46e59fbd8aab7a29fc66f9350afca0e32da1dae5cf02207115ed15b448b7a88343e5f44a13bf715c1c130573ac6989800f0010982364fb01 024a320280fd9c6cddce89a245be8cd616e01b7928bb7c8a185a827d11f9db1cde",
        "script_signature_hex": "47304402206f05fa893e723d17f972ea46e59fbd8aab7a29fc66f9350afca0e32da1dae5cf02207115ed15b448b7a88343e5f44a13bf715c1c130573ac6989800f0010982364fb0121024a320280fd9c6cddce89a245be8cd616e01b7928bb7c8a185a827d11f9db1cde",
        "sequence": -1
      }, {
        "transaction_hash": "ef151f4f72d516efc59c14236d50dd2075f3f01d73516aebc15896b8f34d53bc",
        "output_hash": "115886c56fff5781bf6a0a1e36330d5f68ac814751bce71e41daf06868fbe446",
        "output_index": 1,
        "value": 100000,
        "addresses": ["12ESy23b2Dz6ytJ78uq1sgWwBrXAB3fwxv"],
        "script_signature": "3044022021a00a3694f4d8c8c908bca442adfea52ba0b1e27096cd0a26801ac8da3cd9ad022077534570c7a1bb776d3e9d78035c82a4035592cfee938dd746a4e7016344de0701 024a320280fd9c6cddce89a245be8cd616e01b7928bb7c8a185a827d11f9db1cde",
        "script_signature_hex": "473044022021a00a3694f4d8c8c908bca442adfea52ba0b1e27096cd0a26801ac8da3cd9ad022077534570c7a1bb776d3e9d78035c82a4035592cfee938dd746a4e7016344de070121024a320280fd9c6cddce89a245be8cd616e01b7928bb7c8a185a827d11f9db1cde",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "ef151f4f72d516efc59c14236d50dd2075f3f01d73516aebc15896b8f34d53bc",
        "output_index": 0,
        "value": 100000,
        "addresses": ["16q3r12wBrcPcEwiQXhiBxaahH8U7JE62q"],
        "script": "OP_DUP OP_HASH160 3feef847241bba6560fb99688f10a861024451c6 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a9143feef847241bba6560fb99688f10a861024451c688ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0"
      }, {
        "transaction_hash": "ef151f4f72d516efc59c14236d50dd2075f3f01d73516aebc15896b8f34d53bc",
        "output_index": 1,
        "value": 99000,
        "addresses": ["1BCq8tytJhjSyHeNiycZhK6qQdEvPapF8M"],
        "script": "OP_DUP OP_HASH160 6fee03f4346ae13c128f9c1c2c9da80efcee43d5 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a9146fee03f4346ae13c128f9c1c2c9da80efcee43d588ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "04698cbcbf7a29b59f1e93691874fb4c838cd255b3a71eaf78aa937e59e9ad5e"
      }],
      "fees": 1000,
      "amount": 199000,
      "inputs_length": 2,
      "outputs_length": 2

    tx5:
      "hash": "40c899026bcac33b82e28a7f8a3d9d624a3abfdc67f32402d95391a4f3070339",
      "block_hash": "0000000000000000061e8f8d3fe91f2a6780a2b2015a0aa4d922bd9faa382ef5",
      "block_height": 331002,
      "block_time": "2014-11-21T17:33:37Z",
      "chain_received_at": "2014-11-21T16:40:15.481Z",
      "confirmations": 30468,
      "lock_time": 0,
      "inputs": [{
        "transaction_hash": "40c899026bcac33b82e28a7f8a3d9d624a3abfdc67f32402d95391a4f3070339",
        "output_hash": "2d45b6d365a168b50ac89167522d6f435f466abd5a445eaf06cd2f38d484860f",
        "output_index": 1,
        "value": 7199000,
        "addresses": ["16Ab7EbprvQs8cZjH7WwmU89zkWUTVtFji"],
        "script_signature": "304502210089e6cafbb56ec3ef857e55dcd1f4b35e85233e177bf06ec1d00051b4575f68b9022077b83ed811fa1fd80cd5b92c9ab6dda7ae6519c6b069530ef800007f53437c1501 030a2c1ed18dc7ba0ce7916c07181c19e6149fe4948145be5d7a70f193227db0b2",
        "script_signature_hex": "48304502210089e6cafbb56ec3ef857e55dcd1f4b35e85233e177bf06ec1d00051b4575f68b9022077b83ed811fa1fd80cd5b92c9ab6dda7ae6519c6b069530ef800007f53437c150121030a2c1ed18dc7ba0ce7916c07181c19e6149fe4948145be5d7a70f193227db0b2",
        "sequence": -1
      }],
      "outputs": [{
        "transaction_hash": "40c899026bcac33b82e28a7f8a3d9d624a3abfdc67f32402d95391a4f3070339",
        "output_index": 0,
        "value": 6198000,
        "addresses": ["18hE5qZtrf9M3xddFvP7N8TaquDohD5Vpg"],
        "script": "OP_DUP OP_HASH160 546470c0328956a5686ddee9f5d5b7b1012a7e89 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914546470c0328956a5686ddee9f5d5b7b1012a7e8988ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "913713db2cf8c3a7926275d9f89d84f720f6528733befe50245a7a647aa021eb"
      }, {
        "transaction_hash": "40c899026bcac33b82e28a7f8a3d9d624a3abfdc67f32402d95391a4f3070339",
        "output_index": 1,
        "value": 1000000,
        "addresses": ["1LR8aAwQbJRMjSDb9a6yfC9eVfZu5SRY3F"],
        "script": "OP_DUP OP_HASH160 d4fab195ff24f6c222e660789ae956577812b557 OP_EQUALVERIFY OP_CHECKSIG",
        "script_hex": "76a914d4fab195ff24f6c222e660789ae956577812b55788ac",
        "script_type": "pubkeyhash",
        "required_signatures": 1,
        "spent": true,
        "spending_transaction": "e5b8e6a669d9f94ccf666b7b2c242a7773b9cf007de1aae371100059ae3f64e0"
      }],
      "fees": 1000,
      "amount": 7198000,
      "inputs_length": 1,
      "outputs_length": 2
