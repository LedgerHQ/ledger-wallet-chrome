var BitcoinExternal = Class.create({

	initialize: function() {

	},

	_almostConvertU32 : function(number) {
		if (number instanceof ByteString) {
			return number;
		}
		return new ByteString(Convert.toHexByte((number >> 24) & 0xff) + Convert.toHexByte((number >> 16) & 0xff) + Convert.toHexByte((number >> 8) & 0xff) + Convert.toHexByte(number & 0xff), HEX);
	},

	createBip32Key : function(seed) {		
		var key = new ByteString("Bitcoin seed", ASCII);
		var sha = new JSUCrypt.hash.SHA512();		
		var hmac = new JSUCrypt.signature.HMAC(sha);
		hmac.init(new JSUCrypt.key.HMACKey(key.toString(HEX)), JSUCrypt.signature.MODE_SIGN);
		var result = hmac.sign(seed.toString(HEX));
		result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);
		return [ result.bytes(0, 32), result.bytes(32, 32) ];		
	},

	derivePrivateBip32Key : function(key, chain, indexBigInt) {
		var domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1");
		var index = indexBigInt.toString(16);
		while (index.length < 8) {
			index = "0" + index;
		}
		var index = new ByteString(index, HEX);
		var data;
		if (indexBigInt.testBit(31)) {
			data = new ByteString("00", HEX).concat(key);
		}
		else {
			data = this.compressPublicKey(this.getPublicKey(key));
		}
		data = data.concat(index);
		var sha = new JSUCrypt.hash.SHA512();		
		var hmac = new JSUCrypt.signature.HMAC(sha);
		hmac.init(new JSUCrypt.key.HMACKey(chain.toString(HEX)), JSUCrypt.signature.MODE_SIGN);
		var result = hmac.sign(data.toString(HEX));
		result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);
		var derivedPrivate = new BigInteger(key.toString(HEX), 16);
		derivedPrivate = derivedPrivate.add(new BigInteger(result.bytes(0, 32).toString(HEX), 16));
		derivedPrivate = derivedPrivate.mod(domain.order);
		return [ new ByteString(derivedPrivate.toString(16), HEX), result.bytes(32, 32) ];		
	},

	derivePublicBip32Key : function(key, chain, indexBigInt) {
		var domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1");
		var index = indexBigInt.toString(16);
		while (index.length < 8) {
			index = "0" + index;
		}
		var index = new ByteString(index, HEX);		
		if (key.byteAt(0) != 0x04) {
			throw "Public key must be uncompressed";
		}
		var publicKey = new JSUCrypt.key.EcFpPublicKey(256, domain, new JSUCrypt.ECFp.AffinePoint(key.bytes(1, 32).toString(HEX), key.bytes(33, 32).toString(HEX)));
		key = this.compressPublicKey(key);		
		if (indexBigInt.testBit(31)) {
			throw "Hardened derivation not possible";
		}
		var data = key.concat(index);
		var sha = new JSUCrypt.hash.SHA512();		
		var hmac = new JSUCrypt.signature.HMAC(sha);
		hmac.init(new JSUCrypt.key.HMACKey(chain.toString(HEX)), JSUCrypt.signature.MODE_SIGN);
		var result = hmac.sign(data.toString(HEX));
		result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);
		var mulFactor = new BigInteger(result.bytes(0,32).toString(HEX), 16);
		var derivedPublicPoint = domain.G.multiply(mulFactor);
		derivedPublicPoint = derivedPublicPoint.add(publicKey.W);
		var derivedPublicKey = new JSUCrypt.key.EcFpPublicKey(256, domain, derivedPublicPoint);
		return [ new ByteString(JSUCrypt.utils.byteArrayToHexStr(derivedPublicKey.W.getUncompressedForm()), HEX), result.bytes(32, 32) ];
	},

	getPublicKey : function(key) {
		var domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1");
		var pair = JSUCrypt.key.generateECFpPair(256, domain, key.toString(HEX));
		var publicKey = pair[0].W.getUncompressedForm();
		return new ByteString(JSUCrypt.utils.byteArrayToHexStr(publicKey), HEX);
	},

	getBitcoinAddressBinary : function(publicKey, version) {
		if (typeof version == "undefined") {
			version = 0x00;
		}
		var sha = new JSUCrypt.hash.SHA256();		
		var ripemd = new JSUCrypt.hash.RIPEMD160();
		var result = sha.finalize(publicKey.toString(HEX));
		result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);
		result = ripemd.finalize(result.toString(HEX));
		result = new ByteString(Convert.toHexByte(version) + JSUCrypt.utils.byteArrayToHexStr(result), HEX);
		var checksum = sha.finalize(result.toString(HEX));
		checksum = new ByteString(JSUCrypt.utils.byteArrayToHexStr(checksum), HEX);				
		checksum = sha.finalize(checksum.toString(HEX));
		checksum = new ByteString(JSUCrypt.utils.byteArrayToHexStr(checksum), HEX);				
		result = result.concat(checksum.bytes(0, 4));
		return result;
	},

	getMultiSigScript : function(keyArray, m) {
		var OP_1 = 0x51;
		var OP_CHECKMULTISIG = 0xAE;
		var n = keyArray.length;
		if (typeof m == "undefined") {
			m = n;
		}
		if (n > 3) {
			throw "Too many keys";
		}
		if ((m <= 0) || (m > n)) {
			throw "Invalid multisignature condition";
		}
		var data = new ByteString(Convert.toHexByte(m - 1 + OP_1), HEX);
		for (var i=0; i<keyArray.length; i++) {
			data = data.concat(new ByteString(Convert.toHexByte(keyArray[i].length), HEX));
			data = data.concat(keyArray[i]);
		}
		data = data.concat(new ByteString(Convert.toHexByte(n - 1 + OP_1), HEX));
		data = data.concat(new ByteString(Convert.toHexByte(OP_CHECKMULTISIG), HEX));
		return data;
	},

	getSignedMessageHash: function(message, prefix) {
		var messageLength;
	    if (message.length < 0xfd) {
      		messageLength = new ByteString(Convert.toHexByte(message.length), HEX);
    	} else 
    	if (message.length <= 0xffff) {
      		messageLength = new ByteString("FD" + Convert.toHexByte(message.length & 0xff) + Convert.toHexByte((message.length >> 8) & 0xff), HEX);
      	}
      	else {
      		throw "Message too long";
      	}

		var sha = new JSUCrypt.hash.SHA256();		

		var messageToSign = new ByteString(prefix, ASCII);
		messageToSign = messageToSign.concat(messageLength).concat(message);
		var result = sha.finalize(messageToSign.toString(HEX));
		result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);
		result = sha.finalize(result.toString(HEX));
		result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);

		return result;
	},

	verifyTransaction: function(transactionPool, transactionParam, privateKeys) {
		privateKeys = undefined;

		var domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1");
		var hashNone = new JSUCrypt.hash.HASHNONE();		

		var sha = new JSUCrypt.hash.SHA256();
		var transaction = this.splitTransaction(transactionParam);
		var inputs = transaction['inputs'];

		var hashedTransactionPool = {};
		for (var i=0; i<transactionPool.length; i++) {
			var hash = sha.finalize(transactionPool[i].toString(HEX));
			hash = new ByteString(JSUCrypt.utils.byteArrayToHexStr(hash), HEX);
			hash = new ByteString(JSUCrypt.utils.byteArrayToHexStr(sha.finalize(hash.toString(HEX))), HEX);
			hashedTransactionPool[hash.toString(HEX).toUpperCase()] = this.splitTransaction(transactionPool[i]);
		}
		
		var targetTransaction = {};				
		targetTransaction['version'] = transaction['version'];
		targetTransaction['inputs'] = [];
		for (var i=0; i<inputs.length; i++) {
			var tmpInput = {};
			tmpInput['script'] = new ByteString("", HEX);
			tmpInput['sequence'] = inputs[i]['sequence'];
			targetTransaction['inputs'].push(tmpInput);
		}
		for (var i=0; i<inputs.length; i++) {
			var prevoutHash = inputs[i]['prevout'].bytes(0, 32);
			var prevoutIndex = inputs[i]['prevout'].bytes(32);
			prevoutIndex = new BigInteger(this.reverseBytestring(prevoutIndex).toString(HEX), 16).intValue();
			var prevTransaction = hashedTransactionPool[prevoutHash.toString(HEX).toUpperCase()];
			if (typeof prevTransaction == "undefined") {
				throw "Missing parent transaction " + prevoutHash.toString(HEX);
			}			
			var prevScript = prevTransaction.outputs[prevoutIndex]['script'];
			targetTransaction['inputs'][i]['script'] = prevScript;
			targetTransaction['inputs'][i]['prevout'] = inputs[i]['prevout'];			
			targetTransaction['inputs'][i]['sequence'] = inputs[i]['sequence'];			
			var data = targetTransaction['version'].concat(this.createVarint(targetTransaction['inputs'].length));
			for (var j=0; j<targetTransaction['inputs'].length; j++) {
				var input = targetTransaction['inputs'][j];
				var inputKey;
				data = data.concat(input['prevout']).concat(this.createVarint(input['script'].length));
				data = data.concat(input['script'].concat(input['sequence']));
        	}
        	data = data.concat(this.createVarint(transaction['outputs'].length));
			for (var j=0; j<transaction['outputs'].length; j++) {
				var output = transaction['outputs'][j];
				data = data.concat(output['amount']);
				data = data.concat(this.createVarint(output['script'].length).concat(output['script']));
			}
			data = data.concat(transaction['locktime']);			
			var inputScript = this.splitInputScript(transaction['inputs'][i]['script']);
			data = data.concat(new ByteString(Convert.toHexByte(inputScript['sigHashType']) + "000000", HEX));			
			var hash = sha.finalize(data.toString(HEX));
			hash = new ByteString(JSUCrypt.utils.byteArrayToHexStr(hash), HEX);

			var publicKey;
			if ((typeof privateKeys == "undefined") || (typeof privateKeys[i] == "undefined")) {
				publicKey = new JSUCrypt.key.EcFpPublicKey(256, domain, new JSUCrypt.ECFp.AffinePoint(inputScript['publicKey'].bytes(1, 32).toString(HEX), inputScript['publicKey'].bytes(33, 32).toString(HEX)));
				var ecsig = new JSUCrypt.signature.ECDSA(sha);
				ecsig.init(publicKey, JSUCrypt.signature.MODE_VERIFY);
				var result = ecsig.verify(hash.toString(HEX), inputScript['signature'].toString(HEX));
				if (!result) {
					throw "Signature validation failed for input " + i;
				}
			}
			else {
				var pair = JSUCrypt.key.generateECFpPair(256, domain, privateKeys[i].toString(HEX));
				var ecsig = new JSUCrypt.signature.ECDSA(sha);
				ecsig.setRandomMethod("RFC6979");
				ecsig.init(pair[1], JSUCrypt.signature.MODE_SIGN);
				var result = ecsig.sign(hash.toString(HEX));
				result = new ByteString(JSUCrypt.utils.byteArrayToHexStr(result), HEX);
				if (!inputScript['signature'].equals(result)) {
					throw "Invalid signature, expected " + result.toString(HEX) + " got " + inputScript['signature'].toString(HEX);
				}
			}
			targetTransaction['inputs'][i]['script'] = new ByteString("", HEX);			
		}		
	},

	getVarint : function(data, offset) {
		if (data.byteAt(offset) < 0xfd) {
			return [ data.byteAt(offset), 1 ];
		}
		if (data.byteAt(offset) == 0xfd) {
			return [ ((data.byteAt(offset + 2) << 8) + data.byteAt(offset + 1)), 3 ];
		}
		if (data.byteAt(offset) == 0xfe) {
			return [ ((data.byteAt(offset + 4) << 24) + (data.byteAt(offset + 3) << 16) + 
				  (data.byteAt(offset + 2) << 8) + data.byteAt(offset + 1)), 5 ];
		}
	},

	reverseBytestring : function(value) {
		var result = "";
		for (var i=0; i<value.length; i++) {
			result = result + Convert.toHexByte(value.byteAt(value.length - 1 - i));
		}
		return new ByteString(result, HEX);
	},

	createVarint : function(value) {
		if (value < 0xfd) {
			return new ByteString(Convert.toHexByte(value), HEX);
		}
		if (value <= 0xffff) {
			return new ByteString("fd" + Convert.toHexByte(value & 0xff) + Convert.toHexByte((value >> 8) & 0xff), HEX);
		}
		return new ByteString("fe" + Convert.toHexByte(value & 0xff) + Convert.toHexByte((value >> 8) & 0xff) + Convert.toHexByte((value >> 16) & 0xff) + Convert.toHexByte((value >> 24) & 0xff));
	},

	splitInputScript: function(script) {
		var offset = 0;
		var result = {};
		result['signature'] = script.bytes(offset + 1, script.byteAt(offset) - 1);
		offset += 1 + script.byteAt(offset);
		result['sigHashType'] = script.byteAt(offset - 1);
		result['publicKey'] = script.bytes(offset + 1, script.byteAt(offset));
		return result;
	},

	splitTransaction: function(transaction) {
		var result = {};
		var inputs = [];
		var outputs = [];
		var offset = 0;
		var version = transaction.bytes(offset, 4);
		offset += 4;
		var varint = this.getVarint(transaction, offset);
		var numberInputs = varint[0];
		offset += varint[1];
		for (var i=0; i<numberInputs; i++) {
			var input = {};
			input['prevout'] = transaction.bytes(offset, 36);
			offset += 36;
			varint = this.getVarint(transaction, offset);
			offset += varint[1];
			input['script'] = transaction.bytes(offset, varint[0]);
			offset += varint[0];
			input['sequence'] = transaction.bytes(offset, 4);
			offset += 4;			
			inputs.push(input);
		}		
		varint = this.getVarint(transaction, offset);
		var numberOutputs = varint[0];
		offset += varint[1];
		for (var i=0; i<numberOutputs; i++) {
			var output = {};
			output['amount'] = transaction.bytes(offset, 8);
			offset += 8;
			varint = this.getVarint(transaction, offset);
			offset += varint[1];
			output['script'] = transaction.bytes(offset, varint[0]);
			offset += varint[0];
			outputs.push(output);
		}
		var locktime = transaction.bytes(offset, 4);
		result['version'] = version;
		result['inputs'] = inputs;
		result['outputs'] = outputs;
		result['locktime'] = locktime;
		return result;
	},

	displayTransactionDebug: function(transaction) {
		alert("version " + transaction['version'].toString(HEX));
		for (var i=0; i<transaction['inputs'].length; i++) {
			var input = transaction['inputs'][i];
			alert("input " + i + " prevout " + input['prevout'].toString(HEX) + " script " + input['script'].toString(HEX) + " sequence " + input['sequence'].toString(HEX)); 
		}
		for (var i=0; i<transaction['outputs'].length; i++) {
			var output = transaction['outputs'][i];
			alert("output " + i + " amount " + output['amount'].toString(HEX) + " script " + output['script'].toString(HEX));
		}
		alert("locktime " + transaction['locktime'].toString(HEX));
	},

	splitAsn1Signature: function(asn1Signature) {
		if ((asn1Signature.byteAt(0) != 0x30) || (asn1Signature.byteAt(2) != 0x02)) {
			throw "Invalid signature format";
		}
		var rLength = asn1Signature.byteAt(3);
		if (asn1Signature.byteAt(4 + rLength) != 0x02) {
			throw "Invalid signature format";			
		}		
		var r = asn1Signature.bytes(4, rLength);
		var s = asn1Signature.bytes(4 + rLength + 2, asn1Signature.byteAt(4 + rLength + 1));
		if (r.length == 33) {
			r = r.bytes(1);
		}
		if (s.length == 33) {
			s = s.bytes(1);
		}
		if ((r.length != 32) || (s.length != 32)) {
			throw "Invalid signature format";			
		}
		return [ r, s ];
	},

	compressPublicKey: function(publicKey) {
		var compressedKeyIndex;
		var compressedKey;
		if (publicKey.byteAt(0) != 0x04) {
			throw "Invalid public key format";
		}		
		if ((publicKey.byteAt(64) & 1) != 0) {
			compressedKeyIndex = 0x03;
		}
		else {
			compressedKeyIndex = 0x02;
		}
		var result = new ByteString(Convert.toHexByte(compressedKeyIndex), HEX).concat(publicKey.bytes(1, 32));
		return result;
	},

	recoverPublicKey: function(asn1Signature, digest, rec) {
		var splitSignature = this.splitAsn1Signature(asn1Signature);
		var recBN = new BigInteger("" + rec, 10);
		var BN2 = new BigInteger("2", 10);
		var BN4 = new BigInteger("4", 10);
		var domain = JSUCrypt.ECFp.getEcDomainByName("secp256k1");		
		var a = domain.curve.a;
		var b = domain.curve.b;
		var p = domain.curve.field;
		var G = domain.G;
		var order = domain.order;
		var r = new BigInteger(splitSignature[0].toString(HEX), 16);
		var s = new BigInteger(splitSignature[1].toString(HEX), 16);

    	var x = r.add(order.multiply(recBN.divide(BN2)));
	    var alpha = x.multiply(x).multiply(x).add(a.multiply(x)).add(b).mod(p);
    	var beta = alpha.modPow(p.add(BigInteger.ONE).divide(BN4), p);
    	var y = beta.subtract(recBN).isEven() ? beta : p.subtract(beta);
    	var R = new JSUCrypt.ECFp.AffinePoint(x, y, domain.curve);
    	var e = new BigInteger(digest.toString(HEX), 16);
    	var minus_e = e.negate().mod(order);
    	var inv_r = r.modInverse(order);
    	var Q = (R.multiply(s).add(G.multiply(minus_e))).multiply(inv_r);
		return new ByteString(JSUCrypt.utils.byteArrayToHexStr(Q.getUncompressedForm()), HEX);
	}

});


