/*
 ************************************************************************
 Copyright (c) 2014 UBINITY SAS

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 *************************************************************************
 */

var BTChip = Class.create({

    /**
     * @class Communication with Bitcoin application over a {@link Card}
     * @param {Object} @Card implementing the Bitcoin application
     * @constructs
     */
    initialize: function (card) {
        if (!(card instanceof Card)) {
            throw "Invalid card";
        }
        this.card = card;
        this.deprecatedFirmwareVersion = false;
        this.untrustedHashTransactionInputFinalizeFull = false;
    },

    setCompressedPublicKeys: function (compressedPublicKeys) {
        this.compressedPublicKeys = compressedPublicKeys;
    },

    setUntrustedHashTransactionInputFinalizeFull: function () {
        this.untrustedHashTransactionInputFinalizeFull = true;
    },

    setDeprecatedFirmwareVersion: function () {
        this.deprecatedFirmwareVersion = true;
        this.deprecatedBIP32Derivation = true;
    },

    setDeprecatedBIP32Derivation: function () {
        this.deprecatedBIP32Derivation = true;
    },

    setDeprecatedSetupKeymap: function () {
        this.deprecatedSetupKeymap = true;
    },

    _almostConvertU32: function (number, hdFlag) {
        if (number instanceof ByteString) {
            return number;
        }
        return new ByteString(Convert.toHexByte(((number >> 24) & 0xff) | (hdFlag ? 0x80 : 0x00)) + Convert.toHexByte((number >> 16) & 0xff) + Convert.toHexByte((number >> 8) & 0xff) + Convert.toHexByte(number & 0xff), HEX);
    },

    parseBIP32Path: function (path) {
        var result = [];
        var components = path.split("/");
        for (var i = 0; i < components.length; i++) {
            var hdFlag = 0;
            var component = components[i];
            if (component.charAt(component.length - 1) == '\'') {
                hdFlag = 1;
                component = component.substring(0, component.length - 1);
            }
            result.push(this._almostConvertU32(component, hdFlag));
        }
        return result;
    },

    setupNew_async: function (modeMask, featuresMask, version, versionP2sh, pin, wipePin, keymapEncoding, restoreSeed, bip32SeedOrEntropy, wrappingKey) {
        var deprecatedSetupKeymap = this.deprecatedSetupKeymap
        var dongle = this;
        if (typeof modeMask == "undefined") {
            modeMask = BTChip.MODE_WALLET;
        }
        if (typeof featuresMask == "undefined") {
            featuresMask = 0x00;
        }
        if (typeof pin == "undefined") {
            pin = new ByteString("00000000", ASCII);
        }
        if (typeof keymapEncoding == "undefined") {
            keymapEncoding = BTChip.QWERTY_KEYMAP_NEW;
        }
        var data = Convert.toHexByte(modeMask);
        data += Convert.toHexByte(featuresMask);
        data += Convert.toHexByte(version);
        data += Convert.toHexByte(versionP2sh);
        data += Convert.toHexByte(pin.length) + pin.toString(HEX);
        if (typeof wipePin == "undefined") {
            data += "00";
        }
        else {
            data += Convert.toHexByte(wipePin.length) + wipePin.toString(HEX);
        }
        if (this.deprecatedSetupKeymap) {
            data += keymapEncoding.toString(HEX);
            data += Convert.toHexByte(restoreSeed ? 0x01 : 0x00);
            if (typeof bip32SeedOrEntropy == "undefined") {
                for (var i = 0; i < 32; i++) {
                    data += "00";
                }
            }
            else {
                if (bip32SeedOrEntropy.length != 32) {
                    throw "Invalid seed length";
                }
                data += bip32SeedOrEntropy.toString(HEX);
            }
        }
        else {
            if (restoreSeed) {
                if ((bip32SeedOrEntropy.length < 32) || (bip32SeedOrEntropy.length > 64)) {
                    throw "Invalid seed length";
                }
                data += Convert.toHexByte(bip32SeedOrEntropy.length);
                data += bip32SeedOrEntropy.toString(HEX);
            }
            else {
                data += "00";
            }
        }
        if (typeof wrappingKey == "undefined") {
            data += "00";
        }
        else {
            data += Convert.toHexByte(wrappingKey.length) + wrappingKey.toString(HEX);
        }

        return this.card.sendApdu_async(0xe0, 0x20, 0x00, 0x00, new ByteString(data, HEX), [0x9000]).then(function (result) {
            var offset = 1;
            var resultList = {};
            resultList['trustedInputKey'] = result.bytes(offset, 16);
            offset += 16;
            resultList['keyWrappingKey'] = result.bytes(offset, 16);
            if (deprecatedSetupKeymap) {
                return resultList;
            }
            else {
                return dongle.card.sendApdu_async(0xe0, 0x28, 0x00, 0x00, keymapEncoding, [0x9000]).then(function (result) {
                    return resultList;
                });
            }
        });
    },

    setup_forwardAsync: function (modeMask, featuresMask, version, versionP2sh, pubkeyLength, pubKey, passwordBlob, bip32seed, wrappingKey, keymapEncoding) {
        var dongle = this;
        var deprecatedSetupKeymap = this.deprecatedSetupKeymap
        if (typeof modeMask == "undefined") {
            modeMask = 0x05;
        }

        var data = Convert.toHexByte(modeMask);
        data += Convert.toHexByte(featuresMask);
        data += Convert.toHexByte(version);
        data += Convert.toHexByte(versionP2sh);
        data = data.concat(pubkeyLength);
        data = data.concat(pubKey);
        data = data.concat(passwordBlob);
        data += Convert.toHexByte(bip32seed);
        data += Convert.toHexByte(wrappingKey);

        return this.card.sendApdu_async(0xe0, 0x20, 0x80, 0x00, new ByteString(data, HEX), [0x9000]).then(function (result) {
            var offset = 1;
            var resultList = {};
            resultList['trustedInputKey'] = result.bytes(offset, 16);
            offset += 16;
            resultList['keyWrappingKey'] = result.bytes(offset, 16);
            if (deprecatedSetupKeymap) {
                return resultList;
            }
            else {
                return dongle.card.sendApdu_async(0xe0, 0x28, 0x00, 0x00, keymapEncoding, [0x9000]).then(function (result) {
                    return resultList;
                });
            }
        });
    },

    setup_async: function (modeMask, version, versionP2sh, pin, wipePin, keymapEncodings, restoreSeed, bip32SeedOrEntropy, wrappingKey) {
        if (typeof modeMask == "undefined") {
            modeMask = 0x01;
        }
        if (typeof pin == "undefined") {
            pin = new ByteString("00000000", ASCII);
        }
        if (typeof keymapEncodings == "undefined") {
            keymapEncodings = [BTChip.QWERTY_KEYMAP];
        }
        var data = Convert.toHexByte(modeMask);
        data += Convert.toHexByte(version);
        data += Convert.toHexByte(versionP2sh);
        data += Convert.toHexByte(pin.length) + pin.toString(HEX);
        if (typeof wipePin == "undefined") {
            data += "00";
        }
        else {
            data += Convert.toHexByte(wipePin.length) + wipePin.toString(HEX);
        }
        data += Convert.toHexByte(keymapEncodings.length);
        for (var i = 0; i < keymapEncodings.length; i++) {
            data += keymapEncodings[i].toString(HEX);
        }
        data += Convert.toHexByte(restoreSeed ? 0x01 : 0x00);
        if (typeof bip32SeedOrEntropy == "undefined") {
            for (var i = 0; i < 32; i++) {
                data += "00";
            }
        }
        else {
            if (bip32SeedOrEntropy.length != 32) {
                throw "Invalid seed length";
            }
            data += bip32SeedOrEntropy.toString(HEX);
        }
        if (typeof wrappingKey == "undefined") {
            data += "00";
        }
        else {
            data += Convert.toHexByte(wrappingKey.length) + wrappingKey.toString(HEX);
        }
        //alert(data);
        return this.card.sendApdu_async(0xe0, 0x20, 0x00, 0x00, new ByteString(data, HEX), [0x9000]).then(function (result) {
            var offset = 0;
            var resultList = {};
            resultList['random'] = result.bytes(offset, 32);
            offset += 32;
            resultList['bip32seed'] = result.bytes(offset, 32);
            offset += 32;
            resultList['hotpKey'] = result.bytes(offset, 48);
            offset += 48;
            resultList['trustedInputKey'] = result.bytes(offset, 16);
            offset += 16;
            resultList['keyWrappingKey'] = result.bytes(offset, 16);
            return resultList;
        });
    },

    /* AJOUT NESS */
    setup_keycardAsync: function (keyBlock) {
        var dongle = this;
        keyBlock = new ByteString(keyBlock, HEX);

        return this.card.sendApdu_async(0xD0, 0x26, 0x00, 0x00, keyBlock, [0x9000]).then(function (result) {
            var offset = 1;
            var resultList = {};
            resultList['trustedInputKey'] = result.bytes(offset, 16);
            offset += 16;
            resultList['keyWrappingKey'] = result.bytes(offset, 16);
            return resultList;
        });
    },
    /* FIN AJOUT NESS */

    setupNew_async: function(modeMask, featuresMask, version, versionP2sh, pin, wipePin, keymapEncoding, restoreSeed, bip32SeedOrEntropy, wrappingKey, bip39Generate, bip39Restore) {
        var deprecatedSetupKeymap = this.deprecatedSetupKeymap;
        var dongle = this;
        if (typeof modeMask == "undefined") {
            modeMask = BTChip.MODE_WALLET;
        }
        if (typeof featuresMask == "undefined") {
            featuresMask = 0x00;
        }
        if (typeof pin == "undefined") {
            pin = new ByteString("00000000", ASCII);
        }
        if (typeof keymapEncoding == "undefined") {
            keymapEncoding = BTChip.QWERTY_KEYMAP_NEW;
        }
        var data = Convert.toHexByte(modeMask);
        data += Convert.toHexByte(featuresMask);
        data += Convert.toHexByte(version);
        data += Convert.toHexByte(versionP2sh);
        data += Convert.toHexByte(pin.length) + pin.toString(HEX);
        if (typeof wipePin == "undefined") {
            data += "00";
        }
        else {
            data += Convert.toHexByte(wipePin.length) + wipePin.toString(HEX);
        }
        if (this.deprecatedSetupKeymap) {
            data += keymapEncoding.toString(HEX);
            data += Convert.toHexByte(restoreSeed ? 0x01 : 0x00);
            if (typeof bip32SeedOrEntropy == "undefined") {
                for (var i=0; i<32; i++) {
                    data += "00";
                }
            }
            else {
                if (bip32SeedOrEntropy.length != 32) {
                    throw "Invalid seed length";
                }
                data += bip32SeedOrEntropy.toString(HEX);
            }
        }
        else {

            if (restoreSeed || bip39Generate || bip39Restore) {
                if (restoreSeed) {
                    if ((bip32SeedOrEntropy.length < 32) || (bip32SeedOrEntropy.length > 64)) {
                        throw "Invalid seed length";
                    }
                }
                if (bip39Generate) {
                    if (bip32SeedOrEntropy.length != 32) {
                        throw "Invalid entropy length";
                    }
                }
                if (bip39Restore) {
                    if (bip32SeedOrEntropy.length != 48) {
                        throw "Invalid encoded BIP 39 mnemonic length"
                    }
                }
                data += Convert.toHexByte(bip32SeedOrEntropy.length);
                data += bip32SeedOrEntropy.toString(HEX);
            }
            else {
                data += "00"
            }
        }
        if (typeof wrappingKey == "undefined") {
            data += "00";
        }
        else {
            data += Convert.toHexByte(wrappingKey.length) + wrappingKey.toString(HEX);
        }

        var p2 = 0x00;
        if (bip39Generate) {
            p2 = 0x02;
        }
        if (bip39Restore) {
            p2 = 0x03;
        }

        return this.card.sendApdu_async(0xe0, 0x20, 0x00, p2, new ByteString(data, HEX), [0x9000]).then(function(result) {

            var seedFlag = result.byteAt(0);
            var offset = 1;
            var resultList = {};
            resultList['seedFlag'] = seedFlag;
            if ((modeMask & BTChip.MODE_DEVELOPER) != 0) {
                resultList['trustedInputKey'] = result.bytes(offset, 16);
                offset += 16;
                resultList['keyWrappingKey'] = result.bytes(offset, 16);
                offset += 16;
            }
            if (seedFlag == 0x02) {
                resultList['swappedMnemonic'] = result.bytes(offset, 48);
                offset += 48;
                resultList['encryptedDeviceEntropy'] = result.bytes(offset, 32);
                offset += 32;
            }
            if (deprecatedSetupKeymap || bip39Generate) {
                return resultList;
            }
            else {
                return dongle.card.sendApdu_async(0xe0, 0x28, 0x00, 0x00, keymapEncoding, [0x9000]).then(function(result) {
                    return resultList;
                });
            }
        });
    },

    setupFinalizeBip39_async: function() {
        return this.card.sendApdu_async(0xe0, 0x20, 0xfe, 0x00, new ByteString("00", HEX), [0x9000]);
    },

    setupRecovery_async : function() {
        return this.card.sendApdu_async(0xe0, 0x20, 0xff, 0x00, new ByteString("00", HEX), [0x9000]);
    },

    verifyPin_async: function (pin) {
        return this.card.sendApdu_async(0xe0, 0x22, 0x00, 0x00, pin, [0x9000]);
    },

    getOperationMode_async: function () {
        return this.card.sendApdu_async(0xe0, 0x24, 0x00, 0x00, 0x01, [0x9000]).then(function (result) {
            return result.byteAt(0);
        });
    },

    setOperationMode_async: function (operationMode) {
        return this.card.sendApdu_async(0xe0, 0x26, 0x00, 0x00, new ByteString(Convert.toHexByte(operationMode), HEX), [0x9000]);
    },

    getFirmwareVersion_async: function () {
        return this.card.sendApdu_async(0xe0, 0xc4, 0x00, 0x00, 0x04, [0x9000]).then(function (result) {
            var response = {};
            response['compressedPublicKeys'] = (result.byteAt(0) == 0x01);
            response['firmwareVersion'] = result.bytes(1);
            return response;
        });
    },

    getWalletPublicKey_async: function (path, verify, segwit) {
        var data;
        var path = this.parseBIP32Path(path);
        var p1;
        var p2 = 0x00;

        if (this.deprecatedBIP32Derivation) {
            var account, chainIndex, internalChain;
            if (path.length != 3) {
                throw "Invalid BIP 32 path for deprecated BIP32 derivation";
            }
            account = path[0];
            internalChain = (path[1].equals(new ByteString("00000001", HEX)));
            chainIndex = path[2];
            data = account.concat(chainIndex);
            p1 = (internalChain ? BTChip.INTERNAL_CHAIN : BTChip.EXTERNAL_CHAIN);
        }
        else {
            data = new ByteString(Convert.toHexByte(path.length), HEX);
            for (var i = 0; i < path.length; i++) {
                data = data.concat(path[i]);
            }
            p1 = 0x00;
        }
        if (verify === true) {
            p1 = 0x01;
        }
        if (segwit == true) {
            p2 = 0x01;
        }

        return this.card.sendApdu_async(0xe0, 0x40, p1, p2, data, [0x9000]).then(function (result) {
            var resultList = {};
            var offset = 0;
            resultList['publicKey'] = result.bytes(offset + 1, result.byteAt(offset));
            offset += result.byteAt(offset) + 1;
            resultList['bitcoinAddress'] = result.bytes(offset + 1, result.byteAt(offset));
            /* AJOUT NESS */
            offset += result.byteAt(offset) + 1;
            resultList['chainCode'] = result.bytes(offset, 32);
            /* FIN AJOUT NESS */
            return resultList;
        });
    },

    signMessagePrepare_async: function (path, message) {
        var data;
        var path = this.parseBIP32Path(path);
        if (this.deprecatedBIP32Derivation) {
            var account, chainIndex, internalChain;
            if (path.length != 3) {
                throw "Invalid BIP 32 path for deprecated BIP32 derivation";
            }
            account = path[0];
            internalChain = (path[1].equals(new ByteString("00000001", HEX)));
            chainIndex = path[2];
            data = account.concat(chainIndex);
            data = data.concat(new ByteString(Convert.toHexByte(internalChain ? BTChip.INTERNAL_CHAIN : BTChip.EXTERNAL_CHAIN)), HEX);
        }
        else {
            data = new ByteString(Convert.toHexByte(path.length), HEX);
            for (var i = 0; i < path.length; i++) {
                data = data.concat(path[i]);
            }
        }
        data = data.concat(new ByteString(Convert.toHexByte(message.length), HEX));
        data = data.concat(message);
        return this.card.sendApdu_async(0xe0, 0x4e, 0x00, 0x00, data);
    },

    signMessageSign_async: function (pin) {
        var data;
        if (typeof pin != "undefined") {
            data = pin;
        }
        else {
            data = new ByteString("", HEX);
        }
        return this.card.sendApdu_async(0xe0, 0x4e, 0x80, 0x00, data).then(function (signature) {
            var result = {};
            result['signature'] = new ByteString("30", HEX).concat(signature.bytes(1));
            result['parity'] = (signature.byteAt(0) & 0x01);
            return result;
        });
    },

    ecdsaSignImmediate_async: function (privateKeyEncryptionVersion, encryptedPrivateKey, hash) {
        var data = "";
        data = data + Convert.toHexByte(privateKeyEncryptionVersion);
        data = data + Convert.toHexByte(encryptedPrivateKey.length);
        data = new ByteString(data, HEX);
        data = data.concat(encryptedPrivateKey);
        data = data.concat(hash);
        return this.card.sendApdu_async(0xe0, 0x40, 0x00, 0x00, data, [0x9000]).then(function (signature) {
            return new ByteString("30", HEX).concat(signature.bytes(1));
        });

    },

    ecdsaVerifyImmediate_async: function (publicKey, hash, signature, curveFid) {
        if (typeof curveFid == 'undefined') {
            curveFid = 0xb1c0;
        }
        var data = new ByteString(Convert.toHexShort(curveFid) + Convert.toHexByte(publicKey.length), HEX);
        data = data.concat(publicKey);
        data = data.concat(new ByteString(Convert.toHexByte(hash.length), HEX));
        data = data.concat(hash);
        data = data.concat(signature);
        return this.card.sendApdu_async(0xe0, 0x40, 0x80, 0x00, data, [0x9000]);
    },

    getTrustedInputRaw_async: function (firstRound, indexLookup, transactionData) {
        var data = "";
        if (firstRound) {
            data = data + Convert.toHexByte((indexLookup >> 24) & 0xff) + Convert.toHexByte((indexLookup >> 16) & 0xff) + Convert.toHexByte((indexLookup >> 8) & 0xff) + Convert.toHexByte(indexLookup & 0xff);
            data = new ByteString(data, HEX).concat(transactionData);
        }
        else {
            data = transactionData;
        }
        return this.card.sendApdu_async(0xe0, 0x42, (firstRound ? 0x00 : 0x80), 0x00, data, [0x9000]);
    },

    getTrustedInput_async: function (indexLookup, transaction) {
        var currentObject = this;
        var deferred = Q.defer();

        var notifyInputIndex = 0;
        var notifyOutputIndex = 0;
        var notifyInputsCount = transaction['inputs'].length;
        var notifyOutputsCount = transaction['outputs'].length;

        var notify = function () {
          deferred.notify({inputIndex: notifyInputIndex, outputIndex: notifyOutputIndex, inputsCount: notifyInputsCount, outputsCount: notifyOutputsCount});
        };
        var processScriptBlocks = function (script, sequence) {
            var internalPromise = Q.defer();
            var scriptBlocks = [];
            var offset = 0;
            var scriptResult;
            while (offset != script.length) {
                var blockSize = (script.length - offset > 251 ? 251 : script.length - offset);
                if (((offset + blockSize) != script.length) || (typeof sequence == 'undefined')) {
                    scriptBlocks.push(script.bytes(offset, blockSize));
                }
                else {
                    scriptBlocks.push(script.bytes(offset, blockSize).concat(sequence));
                }
                offset += blockSize;
            }
            async.eachSeries(
                scriptBlocks,
                function (scriptBlock, finishedCallback) {
                    currentObject.getTrustedInputRaw_async(false, undefined, scriptBlock).then(function (result) {
                        scriptResult = result;
                        finishedCallback();
                    }).fail(function (err) {
                        internalPromise.reject(err);
                    });
                },
                function (finished) {
                    internalPromise.resolve(scriptResult);
                }
            );
            return internalPromise.promise;
        }
        var processInputs = function () {
            async.eachSeries(
                transaction['inputs'],
                function (input, finishedCallback) {
                    notifyInputIndex += 1;
                    data = input['prevout'].concat(currentObject.createVarint(input['script'].length));
                    currentObject.getTrustedInputRaw_async(false, undefined, data).then(function (result) {
                        // iteration (eachSeries) ended
                        notify();
                        // deferred.notify("input");
                        processScriptBlocks(input['script'], input['sequence']).then(function (result) {
                            finishedCallback();
                        }).fail(function (err) {
                            deferred.reject(err);
                        });
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                },
                function (finished) {
                    data = currentObject.createVarint(transaction['outputs'].length);
                    currentObject.getTrustedInputRaw_async(false, undefined, data).then(function (result) {
                        processOutputs();
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                }
            );
        }
        var processOutputs = function () {
            async.eachSeries(
                transaction['outputs'],
                function (output, finishedCallback) {
                    notifyOutputIndex += 1;
                    data = output['amount'];
                    data = data.concat(currentObject.createVarint(output['script'].length).concat(output['script']));
                    currentObject.getTrustedInputRaw_async(false, undefined, data).then(function (result) {
                        // iteration (eachSeries) ended
                        notify();
                        // deferred.notify("output");
                        finishedCallback();
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                },
                function (finished) {
                    data = transaction['locktime'];
                    if (typeof transaction['extraData'] != 'undefined') {
                        data = data.concat(currentObject.createVarint(transaction['extraData'].length));
                    }
                    currentObject.getTrustedInputRaw_async(false, undefined, data).then(function (result) {
                        if (typeof transaction['extraData'] != 'undefined') {
                            processExtraData();
                        }
                        else {
                            deferred.resolve(result);
                        }
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                }
            );
        }
        var processExtraData = function() {
            processScriptBlocks(transaction['extraData']).then(function (result) {
                deferred.resolve(result);
            }).fail(function (err) {
                deferred.reject(err);
            });
        }
        var data = transaction['version'].concat(transaction['timestamp']).concat(currentObject.createVarint(transaction['inputs'].length));
        currentObject.getTrustedInputRaw_async(true, indexLookup, data).then(function (result) {
            processInputs();
        }).fail(function (err) {
            deferred.reject(err);
        });
        // return the promise to be resolve when the trusted input has been processed completely
        return deferred.promise;
    },

    startUntrustedHashTransactionInputRaw_async: function (newTransaction, firstRound, transactionData) {
        return this.card.sendApdu_async(0xe0, 0x44, (firstRound ? 0x00 : 0x80), (newTransaction ? 0x00 : 0x80), transactionData, [0x9000]);
    },

    startUntrustedHashTransactionInput_async: function (newTransaction, transaction, trustedInputs) {
        var currentObject = this;
        var data = transaction['version'].concat(transaction['timestamp']).concat(currentObject.createVarint(transaction['inputs'].length));
        var deferred = Q.defer();
        currentObject.startUntrustedHashTransactionInputRaw_async(newTransaction, true, data).then(function (result) {
            var i = 0;
            async.eachSeries(
                transaction['inputs'],
                function (input, finishedCallback) {
                    var inputKey;
                    data = new ByteString(Convert.toHexByte(0x01) + Convert.toHexByte(trustedInputs[i].length), HEX);
                    data = data.concat(trustedInputs[i]).concat(currentObject.createVarint(input['script'].length));
                    currentObject.startUntrustedHashTransactionInputRaw_async(newTransaction, false, data).then(function (result) {
                        data = input['script'].concat(input['sequence']);
                        currentObject.startUntrustedHashTransactionInputRaw_async(newTransaction, false, data).then(function (result) {
                            // TODO notify progress
                            i++;
                            finishedCallback();
                        }).fail(function (err) {
                            deferred.reject(err);
                        });
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                },
                function (finished) {
                    deferred.resolve(finished);
                }
            )
        }).fail(function (err) {
            deferred.reject(err);
        });
        // return the notified object at end of the loop
        return deferred.promise;
    },

    startP2SHUntrustedHashTransactionInput_async: function (newTransaction, version, inputs, redeemScript, currentIndex) {
        var currentObject = this;
        var data = version.concat(currentObject.createVarint(inputs.length));
        var deferred = Q.defer();
        currentObject.startUntrustedHashTransactionInputRaw_async(newTransaction, true, data).then(function (result) {
            var i = 0;
            async.eachSeries(
                inputs,
                function (input, finishedCallback) {
                    data = new ByteString(Convert.toHexByte(0x00), HEX);
                    var txhash = currentObject.reverseBytestring(new ByteString(input[0], HEX));
                    var outpoint = currentObject.reverseBytestring(new ByteString(input[1], HEX));
                    data = data.concat(txhash).concat(outpoint);
                    if (i == currentIndex) {
                        script = new ByteString(redeemScript, HEX);
                    } else {
                        script = "";
                    }
                    data = data.concat(currentObject.createVarint(script.length));
                    if (script.length == 0) {
                        data = data.concat(new ByteString("FFFFFFFF", HEX)); // TODO: unusual sequence
                    }
                    currentObject.startUntrustedHashTransactionInputRaw_async(true, false, data).then(function (result) {
                        var offset = 0;
                        var blocks = [];
                        while (offset != script.length) {
                            var blockSize = (script.length - offset > 255 ? 255 : script.length - offset);
                            block = script.bytes(offset, blockSize);
                            if (offset + blockSize == script.length) {
                                block = block.concat(new ByteString("FFFFFFFF", HEX)); // TODO: unusual sequence
                            }
                            blocks.push(block);
                            offset += blockSize;
                        }
                        async.eachSeries(
                            blocks,
                            function (block, blockFinishedCallback) {
                                currentObject.startUntrustedHashTransactionInputRaw_async(true, false, block).then(function (result) {
                                    blockFinishedCallback();
                                }).fail(function (err) {
                                    finishedCallback();
                                });
                            },
                            function (finished) {
                                i++;
                                finishedCallback();
                            }
                        );
                    }).fail(function (err) {
                        finishedCallback();
                    });
                },
                function (finished) {
                    deferred.resolve(finished);
                }
            );
        }).fail(function (err) {
            deferred.reject(err);
        });
        return deferred.promise;
    },

    untrustedHashTransactionInputFinalizeFullRaw_async: function (lastRound, transactionData) {
        return this.card.sendApdu_async(0xe0, 0x4a, (lastRound ? 0x80 : 0x00), 0x00, transactionData, [0x9000]);
    },

    untrustedHashTransactionInputFinalizeFull_async: function (numOutputs, output) {
        var currentObject = this;
        var data = currentObject.createVarint(numOutputs);
        var deferred = Q.defer();
        return currentObject.untrustedHashTransactionInputFinalizeFullRaw_async(false, data).then(function (result) {
            var data = new ByteString(output, HEX);
            var internalPromise = Q.defer();
            var outputsBlocks = [];
            var offset = 0;
            while (offset != data.length) {
                var blockSize = (data.length - offset > 255 ? 255 : data.length - offset);
                outputsBlocks.push(data.bytes(offset, blockSize));
                offset += blockSize;
            }
            var i = 0;
            async.eachSeries(
                outputsBlocks,
                function (outputsBlock, finishedCallback) {
                    currentObject.untrustedHashTransactionInputFinalizeFullRaw_async(i == outputsBlocks.length - 1, outputsBlock).then(function (result) {
                        i += 1;
                        finishedCallback();
                    }).fail(function (err) {
                        internalPromise.reject(err);
                    });
                },
                function (finished) {
                    internalPromise.resolve();
                }
            );
            return internalPromise.promise;
        });
    },

    hashOutputInternal_async: function (outputType, path, outputAddress, amount, fees) {
        if (typeof changeKey == "undefined") {
            changeKey = new ByteString("", HEX);
        }
        var p2;
        var data = new ByteString(Convert.toHexByte(outputAddress.length), HEX);
        data = data.concat(outputAddress);
        data = data.concat(amount).concat(fees);
        var path = this.parseBIP32Path(path);
        if (this.deprecatedBIP32Derivation) {
            var account, chainIndex, internalChain;
            if (path.length != 3) {
                throw "Invalid BIP 32 path for deprecated BIP32 derivation";
            }
            account = path[0];
            internalChain = (path[1].equals(new ByteString("00000001", HEX)));
            chainIndex = path[2];
            data = data.concat(account).concat(chainIndex);
            p2 = (internalChain ? BTChip.INTERNAL_CHAIN : BTChip.EXTERNAL_CHAIN);
        }
        else {
            data = data.concat(new ByteString(Convert.toHexByte(path.length), HEX));
            for (var i = 0; i < path.length; i++) {
                data = data.concat(path[i]);
            }
            p2 = 0x00;
        }
        var p2;
        if (this.deprecatedFirmwareVersion) {
            p2 = 0x00;
        }
        return this.card.sendApdu_async(0xe0, 0x46, outputType, p2, data, [0x9000]).then(function (outData) {
            var result = {};
            var scriptDataLength = outData.byteAt(0);
            result['scriptData'] = outData.bytes(1, scriptDataLength);
            /* MODIF NESS */
            //result['authorizationRequired'] = (outData.byteAt(1 + scriptDataLength) == 0x01);
            result['authorizationRequired'] = outData.byteAt(1 + scriptDataLength);
            result['indexesKeyCard'] = outData.bytes(2 + scriptDataLength).toString(HEX);
            /* FIN MODIF NESS */
            /* MODIF VINCENT */
            var authorizationMode = outData.byteAt(1 + scriptDataLength);
            var offset = 1 + scriptDataLength + 1;
            if (authorizationMode == 0x02) {
                result['authorizationReference'] = outData.bytes(offset);
            }
            if (authorizationMode == 0x03) {
                var referenceLength = outData.byteAt(offset++);
                result['authorizationReference'] = outData.bytes(offset, referenceLength);
                offset += referenceLength;
                result['authorizationPaired'] = outData.bytes(offset);
            }
            /* FIN MODIF VINCENT */
            return result;
        });
    },

    hashOutputBinary_async: function (path, outputAddress, amount, fees) {
        return this.hashOutputInternal_async(0x01, path, outputAddress, amount, fees);
    },

    hashOutputBase58_async: function (path, outputAddress, amount, fees) {
        return this.hashOutputInternal_async(0x02, path, outputAddress, amount, fees);
    },

    signTransaction_async: function (path, transactionAuthorization, lockTime, sigHashType) {
        if (typeof transactionAuthorization == "undefined") {
            transactionAuthorization = new ByteString("", HEX);
        }
        if (typeof lockTime == "undefined") {
            lockTime = BTChip.DEFAULT_LOCKTIME;
        }
        if (typeof sigHashType == "undefined") {
            sigHashType = BTChip.SIGHASH_ALL;
        }
        var data;
        var path = this.parseBIP32Path(path);
        if (this.deprecatedBIP32Derivation) {
            var account, chainIndex, internalChain;
            if (path.length != 3) {
                throw "Invalid BIP 32 path for deprecated BIP32 derivation";
            }
            account = path[0];
            internalChain = (path[1].equals(new ByteString("00000001", HEX)));
            chainIndex = path[2];
            data = account.concat(chainIndex);
            data = data.concat(new ByteString((Convert.toHexByte(internalChain ? BTChip.INTERNAL_CHAIN : BTChip.EXTERNAL_CHAIN)), HEX));
        }
        else {
            data = new ByteString(Convert.toHexByte(path.length), HEX);
            for (var i = 0; i < path.length; i++) {
                data = data.concat(path[i]);
            }
        }
        data = data.concat(new ByteString(Convert.toHexByte(transactionAuthorization.length), HEX));
        data = data.concat(transactionAuthorization);
        data = data.concat(lockTime);
        data = data.concat(new ByteString(Convert.toHexByte(sigHashType), HEX));
        return this.card.sendApdu_async(0xe0, 0x48, 0x00, 0x00, data, [0x9000]).then(function (signature) {
            return new ByteString("30", HEX).concat(signature.bytes(1));
        });
    },

    createInputScript: function (publicKey, signatureWithHashtype) {
        var data = new ByteString(Convert.toHexByte(signatureWithHashtype.length), HEX).concat(signatureWithHashtype);
        data = data.concat(new ByteString(Convert.toHexByte(publicKey.length), HEX)).concat(publicKey);
        return data;
    },

    compressPublicKey: function (publicKey) {
        var prefix = ((publicKey.byteAt(64) & 1) != 0 ? 0x03 : 0x02);
        return new ByteString(Convert.toHexByte(prefix), HEX).concat(publicKey.bytes(1, 32));
    },

    createPaymentTransaction_async: function (inputs, associatedKeysets, changePath, outputAddress, amount, fees, lockTime, sighashType, authorization, resumeData) {
        // Inputs are provided as arrays of [transaction, output_index]
        // associatedKeysets are provided as arrays of [path]
        var defaultVersion = new ByteString("01000000", HEX);
        var defaultSequence = new ByteString("FFFFFFFF", HEX);
        var trustedInputs = [];
        var regularOutputs = [];
        var signatures = [];
        var firstRun = true;
        var scriptData;
        var resuming = (typeof authorization != "undefined");
        var currentObject = this;

        if (typeof lockTime == "undefined") {
            lockTime = BTChip.DEFAULT_LOCKTIME;
        }
        if (typeof sigHashType == "undefined") {
            sigHashType = BTChip.SIGHASH_ALL;
        }

        var deferred = Q.defer();
        var inputIndex = 0;
        var progressObject = {
            stage: "undefined",
            currentPublicKey: 0,
            publicKeyCount: inputs.length,
            currentTrustedInput: 0,
            trustedInputsCount: inputs.length,
            currentSignTransaction: 0,
            transactionSignCount: resuming ? inputs.length : 0,
            currentHashOutputBase58: 0,
            hashOutputBase58Count: resuming ? inputs.length : 1,
            currentUntrustedHash: 0,
            untrustedHashCount: resuming ? inputs.length : 1
        };
        for (var index in inputs) {
            if (typeof inputs[index] === "function")
                continue;
            progressObject["currentTrustedInputProgress_" + index] = resuming ? inputs[index][0].inputs.length + inputs[index][0].outputs.length : 0;
            progressObject["trustedInputsProgressTotal_" + index] = inputs[index][0].inputs.length + inputs[index][0].outputs.length;
        }
        var notify = function (notifyObject) {
            var result = {};
            for (var key in progressObject) {
                result[key] = progressObject[key];
                if (typeof notifyObject[key] !== "undefined") {
                    result[key] = notifyObject[key];
                    progressObject[key] = notifyObject[key];
                }
            }
            deferred.notify(result);
        };
        async.eachSeries(
            inputs,
            // Iteration callback
            function (input, finishedCallback) {
                inputIndex += 1;
                if (!resuming) {
                    currentObject.getTrustedInput_async(input[1], input[0])
                        .progress(function (p) {
                            var inputProgress = {stage: "getTrustedInputsRaw"};
                            inputProgress["currentTrustedInputProgress_" + (inputIndex - 1)] = p.inputIndex + p.outputIndex;
                            notify(inputProgress);
                        })
                        .then(function (result) {
                        notify({stage: "getTrustedInput", currentTrustedInput: inputIndex});
                        trustedInputs.push(result);
                        regularOutputs.push(input[0].outputs[input[1]]);
                        finishedCallback();
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                }
                else {
                    notify({stage: "getTrustedInput", currentTrustedInput: inputIndex});
                    regularOutputs.push(input[0].outputs[input[1]]);
                    finishedCallback();
                }
            },
            // Finish callback
            function (finished) {
                if (resuming) {
                    trustedInputs = resumeData['trustedInputs'];
                    firstRun = false;
                }
                // Pre-build the target transaction
                var targetTransaction = {};
                targetTransaction['version'] = defaultVersion;
                targetTransaction['timestamp'] = new ByteString("", HEX);
                targetTransaction['inputs'] = [];
                for (var i = 0; i < inputs.length; i++) {
                    var tmpInput = {};
                    tmpInput['script'] = new ByteString("", HEX);
                    tmpInput['sequence'] = defaultSequence;
                    targetTransaction['inputs'].push(tmpInput);
                }

                // compute public keys
                var deferredPublicKeys = Q.defer();

                // process public keys
                deferredPublicKeys.promise.then(function (publicKeys) {
                    // Sign each input
                    var i = 0;
                    async.eachSeries(
                        inputs,
                        function (input, finishedCallback) {
                            targetTransaction['inputs'][i]['script'] = regularOutputs[i]['script'];
                            var resultHash;
                            var notifyHashOutputBase58 = {stage: "hashTransaction", currentHashOutputBase58: i + 1};
                            var notifyStartUntrustedHash = {stage: "hashTransaction", currentUntrustedHash: i + 1};
                            currentObject.startUntrustedHashTransactionInput_async(firstRun, targetTransaction, trustedInputs).then(function (result) {
                                notify(notifyHashOutputBase58);
                                currentObject.hashOutputBase58_async(changePath, outputAddress, amount, fees).then(function (resultHash) {
                                    notify(notifyStartUntrustedHash);
                                    if (resultHash['scriptData'].length != 0) {
                                        scriptData = resultHash['scriptData'];
                                    }
                                    /* MODIF NESS */
                                    //if (resultHash['authorizationRequired']) {
                                    if (resultHash['authorizationRequired'] >= 0x01) {
                                        /* FIN MODIF NESS */
                                        // we're in the resume phase, but still required for authorization, this is odd
                                        if (resuming) {
                                            deferred.reject("Authorization has been rejected");
                                            return;
                                        }

                                        var resumeData = {};
                                        resumeData['authorizationRequired'] = resultHash['authorizationRequired'];
                                        /* ADD NESS */
                                        resumeData['indexesKeyCard'] = resultHash['indexesKeyCard'];
                                        /* FIN ADD NESS */
                                        resumeData['scriptData'] = scriptData;
                                        resumeData['trustedInputs'] = trustedInputs;
                                        resumeData['publicKeys'] = publicKeys;
                                        /* ADD VINCENT */
                                        resumeData['authorizationReference'] = resultHash['authorizationReference'];
                                        resumeData['authorizationPaired'] = resultHash['authorizationPaired'];
                                        /* FIN ADD VINCENT */
                                        // return current state
                                        deferred.resolve(resumeData);
                                        return ;
                                    }
                                    currentObject.signTransaction_async(associatedKeysets[i], authorization, lockTime, sigHashType).then(function (result) {
                                        signatures.push(result);
                                        targetTransaction['inputs'][i]['script'] = new ByteString("", HEX);
                                        if (firstRun) {
                                            firstRun = false;
                                        }
                                        // finished with this iteration
                                        i++;
                                        notify({stage: "getTrustedInput", currentSignTransaction: i});
                                        finishedCallback();
                                    }).fail(function (err) {
                                        deferred.reject(err);
                                    });
                                }).fail(function (err) {
                                    deferred.reject(err);
                                });
                            }).fail(function (err) {
                                deferred.reject(err);
                            });
                        },
                        function (finished) {
                            // Populate the final input scripts
                            var i = 0;
                            async.eachSeries(
                                inputs,
                                function (input, finishedCallback) {
                                    var tmpScriptData = new ByteString(Convert.toHexByte(signatures[i].length), HEX);
                                    tmpScriptData = tmpScriptData.concat(signatures[i]);
                                    tmpScriptData = tmpScriptData.concat(new ByteString(Convert.toHexByte(publicKeys[i].length), HEX));
                                    tmpScriptData = tmpScriptData.concat(publicKeys[i]);
                                    targetTransaction['inputs'][i]['script'] = tmpScriptData;
                                    targetTransaction['inputs'][i]['prevout'] = trustedInputs[i].bytes(4, 0x24);
                                    // prepare next iteration
                                    i++;
                                    finishedCallback();
                                },
                                function (finished) {
                                    var result = currentObject.serializeTransaction(targetTransaction);
                                    result = result.concat(scriptData);
                                    result = result.concat(currentObject.reverseBytestring(lockTime));
                                    // return result
                                    deferred.resolve(result);
                                }
                            );
                        }
                    );
                });

                // compute public keys, then continue signing
                if (!resuming) {
                    var publicKeysArray = [];
                    var i = 0;
                    async.eachSeries(
                        inputs,
                        function (input, finishedCallback) {
                            currentObject.getWalletPublicKey_async(associatedKeysets[i]).then(function (result) {
                                notify({stage: "getWalletPublicKey", currentPublicKey: i + 1});
                                if (currentObject.compressedPublicKeys) {
                                    publicKeysArray[i] = currentObject.compressPublicKey(result['publicKey']);
                                }
                                else {
                                    publicKeysArray[i] = result['publicKey'];
                                }
                                // prepare next iteration
                                i++;
                                finishedCallback();
                            }).fail(function (err) {
                                deferred.reject(err);
                            });
                        },
                        function (finished) {
                            // we've computed all public keys
                            deferredPublicKeys.resolve(publicKeysArray);
                        }
                    );
                }
                else {
                    notify({stage: "getWalletPublicKey", currentPublicKey: inputs.length});
                    // this is resuming, reuse already computed during first pass
                    deferredPublicKeys.resolve(resumeData['publicKeys']);
                }
            }
        );
        return deferred.promise;
    },

    provideOutputFullChangePath_async: function(path) {
        var path = this.parseBIP32Path(path);
        var data = new ByteString(Convert.toHexByte(path.length), HEX);
        for (var i=0; i<path.length; i++) {
            data = data.concat(path[i]);
        }
        this.card.sendApdu_async(0xe0, 0x4a, 0xff, 0x00, data, [0x9000]);
    },

    hashOutputFull_async: function(outputScript) {
        var offset = 0;
        var MAX_BLOCK_FULL = 216;
        var encryptedOutputScript = new ByteString("", HEX);
        var outData;
        var self = this;

        return asyncWhile(function () {return offset < outputScript.length;}, function () {
            var blockSize = ((offset + MAX_BLOCK_FULL) >= outputScript.length ? outputScript.length - offset : MAX_BLOCK_FULL);
            var p1 = ((offset + blockSize) == outputScript.length ? 0x80 : 0x00);
            return self.card.sendApdu_async(0xe0, 0x4a, p1, 0x00, outputScript.bytes(offset, blockSize), [0x9000])
                .then(function (data) {
                    outData = data;
                    if (outData.byteAt(0) != 0x00) {
                        encryptedOutputScript = encryptedOutputScript.concat(outData.bytes(1, outData.byteAt(0)));
                    }
                    offset += offset + blockSize;
                });
        }).then(function () {
            var result = {};
            var scriptDataLength = outData.byteAt(0);
            result['encryptedOutputScript'] = encryptedOutputScript;
            result['authorizationRequired'] = (outData.byteAt(1 + scriptDataLength));
            var authorizationMode = outData.byteAt(1 + scriptDataLength);
            var offset = 1 + scriptDataLength + 1;
            if (authorizationMode == 0x02 || authorizationMode == 0x04) {
                var referenceLength = outData.byteAt(offset++);
                result['authorizationReference'] = outData.bytes(offset, referenceLength);
            }
            if (authorizationMode == 0x03) {
                var referenceLength = outData.byteAt(offset++);
                result['authorizationReference'] = outData.bytes(offset - 1, referenceLength + 1);
                offset += referenceLength;
                result['authorizationPaired'] = outData.bytes(offset);
            }
            return result;
        });

        // Library
        function asyncWhile(condition, callback) {
            var deferred = Q.defer();
            var iterate = function (result) {
                if (!condition()) {
                    deferred.resolve(result);
                    return ;
                }
                callback().then(function (res) {
                    result.push(res);
                    iterate(result);
                }).fail(function (ex) {
                    deferred.reject(ex);
                }).done();
            };
            iterate([]);
            return deferred.promise;
        }
    },

    createPaymentTransactionNew_async: function(inputs, associatedKeysets, changePath, outputScript, lockTime, sighashType, authorization, resumeData) {

        // Implementation starts here

        // Inputs are provided as arrays of [transaction, output_index, optional redeem script]
        // associatedKeysets are provided as arrays of [path]
        var defaultVersion = new ByteString("01000000", HEX);
        var defaultSequence = new ByteString("FFFFFFFF", HEX);
        var trustedInputs = [];
        var regularOutputs = [];
        var signatures = [];
        var publicKeys = [];
        var firstRun = true;
        var scriptData;
        var timestamp = new ByteString(Convert.toHexInt((new Date().getTime() / 1000)).match(/([0-9a-f]{2})/g).reverse().join(''), HEX);
        if (ledger.config.network.areTransactionTimestamped !== true) {
            timestamp = new ByteString("", HEX);
        } else if (ledger.config.network.name === "stratis") {
          timestamp = new ByteString(Convert.toHexInt((new Date().getTime() / 1000) - (15 * 60)).match(/([0-9a-f]{2})/g).reverse().join(''), HEX); // Well... Stratis node doesn't like on-time transaction. Only late transaction can go through ><
        }
        var resuming = (typeof authorization != "undefined");
        var self = this;
        var targetTransaction = {};

        if (typeof lockTime == "undefined") {
            lockTime = BTChip.DEFAULT_LOCKTIME;
        }
        if (typeof sigHashType == "undefined") {
            sighashType = BTChip.SIGHASH_ALL;
        }

        var deferred = Q.defer();

        var progressObject = {
            stage: "undefined",
            currentPublicKey: 0,
            publicKeyCount: inputs.length,
            currentTrustedInput: 0,
            trustedInputsCount: inputs.length,
            currentSignTransaction: 0,
            transactionSignCount: resuming ? inputs.length : 0,
            currentHashOutputBase58: 0,
            hashOutputBase58Count: resuming ? inputs.length : 1,
            currentUntrustedHash: 0,
            untrustedHashCount: resuming ? inputs.length : 1
        };
        for (var index in inputs) {
            if (typeof inputs[index] === "function")
                continue;
            progressObject["currentTrustedInputProgress_" + index] = resuming ? inputs[index][0].inputs.length + inputs[index][0].outputs.length : 0;
            progressObject["trustedInputsProgressTotal_" + index] = inputs[index][0].inputs.length + inputs[index][0].outputs.length;
        }
        var notify = function (notifyObject) {
            var result = {};
            for (var key in progressObject) {
                result[key] = progressObject[key];
                if (typeof notifyObject[key] !== "undefined") {
                    result[key] = notifyObject[key];
                    progressObject[key] = notifyObject[key];
                }
            }
            deferred.notify(result);
        };
        foreach(inputs, function (input, i) {
            return doIf(!resuming, function () {
                return self.getTrustedInput_async(input[1], input[0])
                    .progress(function (p) {
                        var inputProgress = {stage: "getTrustedInputsRaw"};
                        inputProgress["currentTrustedInputProgress_" + (i)] = p.inputIndex + p.outputIndex;
                        notify(inputProgress);
                    })
                    .then(function (trustedInput) {
                        notify({stage: "getTrustedInput", currentTrustedInput: i + 1});
                        trustedInputs.push(trustedInput);
                    });
            }).then(function () {
                notify({stage: "getTrustedInput", currentTrustedInput: i + 1});
                regularOutputs.push(input[0].outputs[input[1]]);
            });
        }).then(function () {
          return ledger.api.TransactionsRestClient.instance.getTime()
        }).then(function (time) {
          if (ledger.config.network.areTransactionTimestamped !== true) {

          } else {
            if (ledger.config.network.name === "stealthcoin") {
              timestamp = new ByteString(Convert.toHexInt(time - (10 * 60)).match(/([0-9a-f]{2})/g).reverse().join(''), HEX);
            } else {
              timestamp = new ByteString(Convert.toHexInt(time).match(/([0-9a-f]{2})/g).reverse().join(''), HEX);
            }
          }
        }).then(function () {
            if (resuming) {
                trustedInputs = resumeData['trustedInputs'];
                publicKeys = resumeData['publicKeys'];
                scriptData = resumeData['scriptData'];
                firstRun = false;
            }

            // Pre-build the target transaction
            targetTransaction['version'] = defaultVersion;
            targetTransaction['timestamp'] = timestamp;
            targetTransaction['inputs'] = [];

            for (var i = 0; i < inputs.length; i++) {
                var tmpInput = {};
                tmpInput['script'] = new ByteString("", HEX);
                tmpInput['sequence'] = defaultSequence;
                targetTransaction['inputs'].push(tmpInput);
            }
        }).then(function () {
            return doIf(!resuming, function () {
                // Collect public keys
                return foreach(inputs, function (input, i) {
                    return self.getWalletPublicKey_async(associatedKeysets[i]).then(function (p) {
                        notify({stage: "getWalletPublicKey", currentPublicKey: i + 1});
                        return p;
                    });
                }).then(function (result) {
                    notify({stage: "getWalletPublicKey", currentPublicKey: inputs.length});
                    for (var index = 0; index < result.length; index++) {
                        if (self.compressedPublicKeys) {
                            publicKeys.push(self.compressPublicKey(result[index]['publicKey']));
                        } else {
                            publicKeys.push(result[index]['publicKey']);
                        }
                    }
                });
            })
        }).then(function () {
            return foreach(inputs, function (input, i) {
                var usedScript;
                if ((inputs[i].length == 3) && (typeof inputs[i][2] != "undefined")) {
                    usedScript = inputs[i][2];
                }
                else {
                    usedScript = regularOutputs[i]['script'];
                }
                targetTransaction['inputs'][i]['script'] = usedScript;
                var notifyHashOutputBase58 = {stage: "hashTransaction", currentHashOutputBase58: i + 1};
                var notifyStartUntrustedHash = {stage: "hashTransaction", currentUntrustedHash: i + 1};
                return self.startUntrustedHashTransactionInput_async(firstRun, targetTransaction, trustedInputs).then(function () {
                    notify(notifyHashOutputBase58);
                    return doIf(!resuming && (typeof changePath != "undefined"), function () {
                        return self.provideOutputFullChangePath_async(changePath);
                    }).then (function () {
                        return self.hashOutputFull_async(outputScript);
                    }).then (function (resultHash) {
                        notify(notifyStartUntrustedHash);
                        scriptData = outputScript;
                        if (resultHash['authorizationRequired']) {
                            var tmpResult = {};
                            tmpResult['authorizationRequired'] = resultHash['authorizationRequired'];
                            tmpResult['authorizationReference'] = resultHash['authorizationReference'];
                            tmpResult['authorizationPaired'] = resultHash['authorizationPaired'];
                            tmpResult['encryptedOutputScript'] = resultHash['encryptedOutputScript'];
                            tmpResult['indexesKeyCard'] = resultHash['authorizationReference'].toString(HEX);
                            tmpResult['scriptData'] = scriptData;
                            tmpResult['trustedInputs'] = trustedInputs;
                            tmpResult['publicKeys'] = publicKeys;
                            // Interrupt the loop over inputs. We recover the failure at the end of the main function
                            throw tmpResult;
                        }
                        return self.signTransaction_async(associatedKeysets[i], authorization).then(function (signature) {
                            notify({stage: "getTrustedInput", currentSignTransaction: i + 1});
                            signatures.push(signature);
                            targetTransaction['inputs'][i]['script'] = new ByteString("", HEX);
                            if (firstRun) {
                                firstRun = false;
                            }
                        });
                    });
                });
            });
        }).then(function () {
            // Populate the final input scripts
            for (var i=0; i < inputs.length; i++) {
                var tmpScriptData = new ByteString(Convert.toHexByte(signatures[i].length), HEX);
                tmpScriptData = tmpScriptData.concat(signatures[i]);
                var publicKey = publicKeys[i];
                tmpScriptData = tmpScriptData.concat(new ByteString(Convert.toHexByte(publicKey.length), HEX));
                tmpScriptData = tmpScriptData.concat(publicKey);
                targetTransaction['inputs'][i]['script'] = tmpScriptData;
                targetTransaction['inputs'][i]['prevout'] = trustedInputs[i].bytes(4, 0x24);
            }
            var result = self.serializeTransaction(targetTransaction, timestamp);
            result = result.concat(scriptData);
            result = result.concat(self.reverseBytestring(lockTime));

            return result;
        }).fail(function (failure) {
            if ((typeof failure) != "undefined" && (typeof failure.authorizationRequired) != "undefined") {
                // Recover from failure
                // This is just the signature interruption due to authorization requirement
                return failure;
            }
            throw failure;
        }).then(function (result) {
            deferred.resolve(result);
        }).fail(function (error) {
            deferred.reject(error);
        });

        return deferred.promise;

        // Library
        function foreach(arr, callback) {
            var deferred = Q.defer();
            var iterate = function (index, array, result) {
                if (index >= array.length) {
                    deferred.resolve(result);
                    return ;
                }
                callback(array[index], index).then(function (res) {
                    result.push(res);
                    iterate(index + 1, array, result);
                }).fail(function (ex) {
                    deferred.reject(ex);
                }).done();
            };
            iterate(0, arr, []);
            return deferred.promise;
        }

        function doIf(condition, callback) {
            var deferred = Q.defer();
            if (condition) {
                deferred.resolve(callback())
            } else {
                deferred.resolve();
            }
            return deferred.promise;
        }
    },


    getTrustedInputBIP143_async: function (indexLookup, transaction) {
        sha = new JSUCrypt.hash.SHA256();
        hash = sha.finalize(this.serializeTransaction(transaction, undefined, true).toString(HEX));
        hash = new ByteString(JSUCrypt.utils.byteArrayToHexStr(hash), HEX)
        hash = sha.finalize(hash.toString(HEX));
        hash = new ByteString(JSUCrypt.utils.byteArrayToHexStr(hash), HEX)
        data = Convert.toHexByte(indexLookup & 0xff) + Convert.toHexByte((indexLookup >> 8) & 0xff) + Convert.toHexByte((indexLookup >> 16) & 0xff) + Convert.toHexByte((indexLookup >> 24) & 0xff);
        hash = hash.concat(new ByteString(data, HEX));
        hash = hash.concat(transaction.outputs[indexLookup]['amount']);
        return Q.fcall(function() {
            return hash;
        });
    },

    startUntrustedHashTransactionInputRawBIP143_async: function (newTransaction, firstRound, transactionData) {
        return this.card.sendApdu_async(0xe0, 0x44, (firstRound ? 0x00 : 0x80), (newTransaction ? 0x02 : 0x80), transactionData, [0x9000]);
    },


    startUntrustedHashTransactionInputBIP143_async: function (newTransaction, transaction, trustedInputs) {
        var currentObject = this;
        var data = transaction['version'].concat(transaction['timestamp']).concat(currentObject.createVarint(transaction['inputs'].length));
        var deferred = Q.defer();
        currentObject.startUntrustedHashTransactionInputRawBIP143_async(newTransaction, true, data).then(function (result) {
            var i = 0;
            async.eachSeries(
                transaction['inputs'],
                function (input, finishedCallback) {
                    var inputKey;
                    data = new ByteString(Convert.toHexByte(0x02), HEX);
                    data = data.concat(trustedInputs[i]).concat(currentObject.createVarint(input['script'].length));
                    currentObject.startUntrustedHashTransactionInputRawBIP143_async(newTransaction, false, data).then(function (result) {
                        data = input['script'].concat(input['sequence']);
                        currentObject.startUntrustedHashTransactionInputRawBIP143_async(newTransaction, false, data).then(function (result) {
                            // TODO notify progress
                            i++;
                            finishedCallback();
                        }).fail(function (err) {
                            deferred.reject(err);
                        });
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                },
                function (finished) {
                    deferred.resolve(finished);
                }
            )
        }).fail(function (err) {
            deferred.reject(err);
        });
        // return the notified object at end of the loop
        return deferred.promise;
    },

    hashPublicKey: function(publicKey) {
        var tmp = [];
        for (var i=0; i<publicKey.length; i++) {
            tmp.push(publicKey.byteAt(i));
        }
        var compressedKey = Bitcoin.Util.sha256ripe160(tmp);
        tmp = "";
        for (var i=0; i<compressedKey.length; i++) {
            tmp = tmp + Convert.toHexByte(compressedKey[i]);
        }
        return new ByteString(tmp, HEX);
    },

    createPaymentTransactionNewBIP143_async: function(segwit, inputs, associatedKeysets, changePath, outputScript, lockTime, sighashType, authorization, resumeData) {
        // Implementation starts here

        // Inputs are provided as arrays of [transaction, output_index, optional redeem script]
        // associatedKeysets are provided as arrays of [path]
        var defaultVersion = new ByteString("01000000", HEX);
        var defaultSequence = new ByteString("FFFFFFFF", HEX);
        var trustedInputs = [];
        var regularOutputs = [];
        var signatures = [];
        var publicKeys = [];
        var firstRun = true;
        var scriptData;
        var timestamp = new ByteString(Convert.toHexInt(new Date().getTime() / 1000).match(/([0-9a-f]{2})/g).reverse().join(''), HEX);
        if (ledger.config.network.areTransactionTimestamped !== true) {
            timestamp = new ByteString("", HEX);
        }
        var resuming = (typeof authorization != "undefined");
        var self = this;
        var targetTransaction = {};

        if (typeof lockTime == "undefined") {
            lockTime = BTChip.DEFAULT_LOCKTIME;
        }
        if (typeof sigHashType == "undefined") {
            sighashType = BTChip.SIGHASH_ALL;
        }

        var deferred = Q.defer();

        var progressObject = {
            stage: "undefined",
            currentPublicKey: 0,
            publicKeyCount: inputs.length,
            currentTrustedInput: 0,
            trustedInputsCount: inputs.length,
            currentSignTransaction: 0,
            transactionSignCount: resuming ? inputs.length : 0,
            currentHashOutputBase58: 0,
            hashOutputBase58Count: resuming ? inputs.length : 1,
            currentUntrustedHash: 0,
            untrustedHashCount: resuming ? inputs.length : 1
        };
        for (var index in inputs) {
            if (typeof inputs[index] === "function")
                continue;
            progressObject["currentTrustedInputProgress_" + index] = resuming ? inputs[index][0].inputs.length + inputs[index][0].outputs.length : 0;
            progressObject["trustedInputsProgressTotal_" + index] = inputs[index][0].inputs.length + inputs[index][0].outputs.length;
        }
        var notify = function (notifyObject) {
            var result = {};
            for (var key in progressObject) {
                result[key] = progressObject[key];
                if (typeof notifyObject[key] !== "undefined") {
                    result[key] = notifyObject[key];
                    progressObject[key] = notifyObject[key];
                }
            }
            deferred.notify(result);
        };
        foreach(inputs, function (input, i) {
            return doIf(!resuming, function () {
                return self.getTrustedInputBIP143_async(input[1], input[0])
                    .progress(function (p) {
                        var inputProgress = {stage: "getTrustedInputsRaw"};
                        inputProgress["currentTrustedInputProgress_" + (i)] = p.inputIndex + p.outputIndex;
                        notify(inputProgress);
                    })
                    .then(function (trustedInput) {
                        notify({stage: "getTrustedInput", currentTrustedInput: i + 1});
                        trustedInputs.push(trustedInput);
                    });
            }).then(function () {
                notify({stage: "getTrustedInput", currentTrustedInput: i + 1});
                regularOutputs.push(input[0].outputs[input[1]]);
            });
        }).then(function () {
            if (resuming) {
                trustedInputs = resumeData['trustedInputs'];
                publicKeys = resumeData['publicKeys'];
                scriptData = resumeData['scriptData'];
                firstRun = false;
            }

            // Pre-build the target transaction
            targetTransaction['version'] = defaultVersion;
            targetTransaction['timestamp'] = timestamp;
            targetTransaction['inputs'] = [];

            for (var i = 0; i < inputs.length; i++) {
                var tmpInput = {};
                tmpInput['script'] = new ByteString("", HEX);
                tmpInput['sequence'] = defaultSequence;
                targetTransaction['inputs'].push(tmpInput);
            }
        }).then(function () {
            return doIf(!resuming, function () {
                // Collect public keys
                return foreach(inputs, function (input, i) {
                    return self.getWalletPublicKey_async(associatedKeysets[i]).then(function (p) {
                        notify({stage: "getWalletPublicKey", currentPublicKey: i + 1});
                        return p;
                    });
                }).then(function (result) {
                    notify({stage: "getWalletPublicKey", currentPublicKey: inputs.length});
                    for (var index = 0; index < result.length; index++) {
                        if (self.compressedPublicKeys) {
                            publicKeys.push(self.compressPublicKey(result[index]['publicKey']));
                        } else {
                            publicKeys.push(result[index]['publicKey']);
                        }
                    }
                });
            })
        }).then(function () {
            // Do the first run with all inputs
            return doIf(!resuming, function () {
                var notifyHashOutputBase58 = {stage: "hashTransaction", currentHashOutputBase58: 1};
                var notifyStartUntrustedHash = {stage: "hashTransaction", currentUntrustedHash: 1};
                return self.startUntrustedHashTransactionInputBIP143_async(true, targetTransaction, trustedInputs).then(function () {
                    notify(notifyHashOutputBase58);
                    return doIf(!resuming && (typeof changePath != "undefined"), function () {
                        return self.provideOutputFullChangePath_async(changePath);
                    }).then (function () {
                        return self.hashOutputFull_async(outputScript);
                    }).then (function (resultHash) {
                        notify(notifyStartUntrustedHash);
                        scriptData = outputScript;
                        if (resultHash['authorizationRequired']) {
                            var tmpResult = {};
                            tmpResult['authorizationRequired'] = resultHash['authorizationRequired'];
                            tmpResult['authorizationReference'] = resultHash['authorizationReference'];
                            tmpResult['authorizationPaired'] = resultHash['authorizationPaired'];
                            tmpResult['encryptedOutputScript'] = resultHash['encryptedOutputScript'];
                            tmpResult['indexesKeyCard'] = resultHash['authorizationReference'].toString(HEX);
                            tmpResult['scriptData'] = scriptData;
                            tmpResult['trustedInputs'] = trustedInputs;
                            tmpResult['publicKeys'] = publicKeys;
                            // Interrupt the loop over inputs. We recover the failure at the end of the main function
                            throw tmpResult;
                        }
                    });
                });
            })
        }).then(function () {
            // Do the second run with the individual transaction
            return foreach(inputs, function (input, i) {
                var usedScript;
                if ((inputs[i].length == 3) && (typeof inputs[i][2] != "undefined")) {
                    usedScript = inputs[i][2];
                }
                else {
                    if (!segwit) {
                        usedScript = regularOutputs[i]['script'];
                    }
                    else {
                        var hashedPublicKey = self.hashPublicKey(publicKeys[i]);
                        usedScript = new ByteString("76a914", HEX).concat(hashedPublicKey).concat(new ByteString("88ac", HEX));
                    }
                }
                var pseudoTransaction = {};
                pseudoTransaction['version'] = targetTransaction['version'];
                pseudoTransaction['timestamp'] = targetTransaction['timestamp'];
                pseudoTransaction['inputs'] = [];
                var pseudoInput = {};
                pseudoInput['script'] = usedScript;
                pseudoInput['sequence'] = defaultSequence;
                pseudoTransaction['inputs'].push(pseudoInput);
                var pseudoTrustedInputs = [ trustedInputs [i] ];
                var notifyHashOutputBase58 = {stage: "hashTransaction", currentHashOutputBase58: i + 1};
                var notifyStartUntrustedHash = {stage: "hashTransaction", currentUntrustedHash: i + 1};
                return self.startUntrustedHashTransactionInputBIP143_async(false, pseudoTransaction, pseudoTrustedInputs).then(function () {
                    notify(notifyStartUntrustedHash);
                    var hashType = (segwit ? 0x01 : 0x41);
                    return self.signTransaction_async(associatedKeysets[i], authorization, undefined, hashType).then(function (signature) {
                        notify({stage: "getTrustedInput", currentSignTransaction: i + 1});
                        signatures.push(signature);
                        targetTransaction['inputs'][i]['script'] = new ByteString("", HEX);
                    });
                });
            });
        }).then(function () {
            // Populate the final input scripts
            for (var i=0; i < inputs.length; i++) {
                var tmpScriptData;
                if (segwit) {
                    tmpScriptData = new ByteString("160014", HEX);
                    tmpScriptData = tmpScriptData.concat(self.hashPublicKey(publicKeys[i]));
                }
                else {
                    tmpScriptData = new ByteString(Convert.toHexByte(signatures[i].length), HEX);
                    tmpScriptData = tmpScriptData.concat(signatures[i]);
                    var publicKey = publicKeys[i];
                    tmpScriptData = tmpScriptData.concat(new ByteString(Convert.toHexByte(publicKey.length), HEX));
                    tmpScriptData = tmpScriptData.concat(publicKey);
                }
                targetTransaction['inputs'][i]['script'] = tmpScriptData;
                targetTransaction['inputs'][i]['prevout'] = trustedInputs[i].bytes(0, 0x24);
            }
            if (segwit) {
                targetTransaction['witness'] = "";
            }
            var result = self.serializeTransaction(targetTransaction, timestamp);
            result = result.concat(scriptData);
            if (segwit) {
                witness = new ByteString("", HEX);
                for (var i=0; i < inputs.length; i++) {
                    var tmpScriptData = new ByteString("02", HEX);
                    tmpScriptData = tmpScriptData.concat(new ByteString(Convert.toHexByte(signatures[i].length), HEX));
                    tmpScriptData = tmpScriptData.concat(signatures[i]);
                    var publicKey = publicKeys[i];
                    tmpScriptData = tmpScriptData.concat(new ByteString(Convert.toHexByte(publicKey.length), HEX));
                    tmpScriptData = tmpScriptData.concat(publicKey);
                    witness = witness.concat(tmpScriptData);
                }
                result = result.concat(witness);
            }
            result = result.concat(self.reverseBytestring(lockTime));

            console.log("SIGNED TX " + result.toString(HEX));

            return result;
        }).fail(function (failure) {
            if ((typeof failure) != "undefined" && (typeof failure.authorizationRequired) != "undefined") {
                // Recover from failure
                // This is just the signature interruption due to authorization requirement
                return failure;
            }
            throw failure;
        }).then(function (result) {
            deferred.resolve(result);
        }).fail(function (error) {
            deferred.reject(error);
        });

        return deferred.promise;

        // Library
        function foreach(arr, callback) {
            var deferred = Q.defer();
            var iterate = function (index, array, result) {
                if (index >= array.length) {
                    deferred.resolve(result);
                    return ;
                }
                callback(array[index], index).then(function (res) {
                    result.push(res);
                    iterate(index + 1, array, result);
                }).fail(function (ex) {
                    deferred.reject(ex);
                }).done();
            };
            iterate(0, arr, []);
            return deferred.promise;
        }

        function doIf(condition, callback) {
            var deferred = Q.defer();
            if (condition) {
                deferred.resolve(callback())
            } else {
                deferred.resolve();
            }
            return deferred.promise;
        }
    },

    // Inputs : [ [ prevout tx hash, prevout index ] ]
    // Scripts : [ redeem scripts ] for each input
    // Output : the full output script
    // Paths : [ key path ] for each associated input
    signP2SHTransaction_async: function (inputs, scripts, numOutputs, output, paths) {
        var authorization = new ByteString("", HEX);
        var signatures = [];
        var scriptData;
        var defaultVersion = new ByteString("01000000", HEX);
        var lockTime = BTChip.DEFAULT_LOCKTIME;
        var sigHashType = BTChip.SIGHASH_ALL;
        var currentObject = this;
        var deferred = Q.defer();
        var firstRun = true;
        var currentIndex = 0
        async.eachSeries(
            inputs,
            function (input, finishedCallback) {
                deferred.notify("progress");
                currentObject.startP2SHUntrustedHashTransactionInput_async(firstRun, defaultVersion, inputs, scripts[currentIndex], currentIndex).then(function (result) {
                    deferred.notify("progress");
                    currentObject.untrustedHashTransactionInputFinalizeFull_async(numOutputs, output).then(function (result) {
                        deferred.notify("progress");
                        currentObject.signTransaction_async(paths[currentIndex], authorization, lockTime, sigHashType).then(function (result) {
                            deferred.notify("progress");
                            signatures.push(result.toString(HEX));
                            firstRun = false;
                            currentIndex++;
                            finishedCallback();
                        }).fail(function (err) {
                            deferred.reject(err);
                        });
                    }).fail(function (err) {
                        deferred.reject(err);
                    });
                }).fail(function (err) {
                    deferred.reject(err);
                });
            },
            function (finished) {
                deferred.resolve(signatures);
            }
        );
        return deferred.promise;
    },

    formatP2SHInputScript: function (redeemScript, signatures) {
        var OP_0 = 0x00;
        var OP_1_BEFORE = 0x50;
        var OP_PUSHDATA1 = 0x4c;
        var OP_PUSHDATA2 = 0x4d;
        var m = redeemScript.byteAt(0) - OP_1_BEFORE;
        var result = new ByteString("00", HEX); // start with OP_0
        for (var i = 0; i < m; i++) {
            if (i < signatures.length) {
                result = result.concat(new ByteString(Convert.toHexByte(signatures[i].length), HEX)).concat(signatures[i]);
            }
            else {
                result = result.concat(new ByteString("00", HEX));
            }
        }
        if (redeemScript.length > 255) {
            result = result.concat(new ByteString(Convert.toHexByte(OP_PUSHDATA2) +
            Convert.toHexByte(redeemScript.length & 0xff) + Convert.toHexByte((redeemScript.length >> 8) & 0xff), HEX));
        }
        else if (redeemScript.length >= OP_PUSHDATA1) {
            result = result.concat(new ByteString(Convert.toHexByte(OP_PUSHDATA1) +
            Convert.toHexByte(redeemScript.length), HEX));
        }
        else {
            result = result.concat(new ByteString(Convert.toHexByte(redeemScript.length), HEX));
        }
        result = result.concat(redeemScript);
        return result;
    },

    formatP2SHOutputScript: function (transaction) {
        var data = new ByteString('', HEX);
        currentObject = this;
        transaction.outs.forEach(
            function (txout) {
                data = data.concat(new ByteString(Bitcoin.convert.bytesToHex(ledger.bitcoin.numToBytes(txout.value, 8)), HEX));
                var scriptBytes = txout.script.buffer;
                data = data.concat(currentObject.createVarint(scriptBytes.length))
                data = data.concat(new ByteString(Bitcoin.convert.bytesToHex(scriptBytes), HEX));
            }
        );
        return data.toString();
    },

    serializeTransaction: function (transaction, timestamp, skipWitness) {
        var data = transaction['version'];
        var useWitness = ((typeof transaction['witness'] != "undefined") && !skipWitness);
        if (useWitness) {
            data = data.concat(new ByteString("0001", HEX));
        }
        if (ledger.config.network.areTransactionTimestamped === true) {
            data = data.concat(timestamp);
        }
        data = data.concat(this.createVarint(transaction['inputs'].length));
        for (var i = 0; i < transaction['inputs'].length; i++) {
            var input = transaction['inputs'][i];
            data = data.concat(input['prevout'].concat(this.createVarint(input['script'].length)));
            data = data.concat(input['script']).concat(input['sequence']);
        }
        if (typeof transaction['outputs'] != "undefined") {
            data = data.concat(this.createVarint(transaction['outputs'].length));
            for (var i = 0; i < transaction['outputs'].length; i++) {
                var output = transaction['outputs'][i];
                data = data.concat(output['amount']);
                data = data.concat(this.createVarint(output['script'].length).concat(output['script']));
            }
            if (useWitness) {
                data = data.concat(transaction['witness']);
            }
            data = data.concat(transaction['locktime']);
        }
        return data;
    },

    getVarint: function (data, offset) {
        if (data.byteAt(offset) < 0xfd) {
            return [data.byteAt(offset), 1];
        }
        if (data.byteAt(offset) == 0xfd) {
            return [((data.byteAt(offset + 2) << 8) + data.byteAt(offset + 1)), 3];
        }
        if (data.byteAt(offset) == 0xfe) {
            return [((data.byteAt(offset + 4) << 24) + (data.byteAt(offset + 3) << 16) +
            (data.byteAt(offset + 2) << 8) + data.byteAt(offset + 1)), 5];
        }
    },

    reverseBytestring: function (value) {
        var result = "";
        for (var i = 0; i < value.length; i++) {
            result = result + Convert.toHexByte(value.byteAt(value.length - 1 - i));
        }
        return new ByteString(result, HEX);
    },

    createVarint: function (value) {
        if (value < 0xfd) {
            return new ByteString(Convert.toHexByte(value), HEX);
        }
        if (value <= 0xffff) {
            return new ByteString("fd" + Convert.toHexByte(value & 0xff) + Convert.toHexByte((value >> 8) & 0xff), HEX);
        }
        return new ByteString("fe" + Convert.toHexByte(value & 0xff) + Convert.toHexByte((value >> 8) & 0xff) + Convert.toHexByte((value >> 16) & 0xff) + Convert.toHexByte((value >> 24) & 0xff));
    },

    splitTransaction: function (transaction, hasTimestamp, isSegwitSupported) {
        var result = {};
        var inputs = [];
        var outputs = [];
        var offset = 0;
        var witness = false;
        var version = transaction.bytes(offset, 4);
        offset += 4;
        if (!hasTimestamp && isSegwitSupported && ((transaction.byteAt(offset) == 0) && (transaction.byteAt(offset + 1) != 0))) {
            offset += 2;
            witness = true;
        }
        if (hasTimestamp === true) {
            result['timestamp'] = transaction.bytes(offset, 4);
            offset += 4;
        } else {
            result['timestamp'] = new ByteString("", HEX);
        }
        var varint = this.getVarint(transaction, offset);
        var numberInputs = varint[0];
        offset += varint[1];
        for (var i = 0; i < numberInputs; i++) {
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
        for (var i = 0; i < numberOutputs; i++) {
            var output = {};
            output['amount'] = transaction.bytes(offset, 8);
            offset += 8;
            varint = this.getVarint(transaction, offset);
            offset += varint[1];
            output['script'] = transaction.bytes(offset, varint[0]);
            offset += varint[0];
            outputs.push(output);
        }
        var locktime;
        var witnessScript;
        if (witness) {
            witnessScript = transaction.bytes(offset, transaction.length - offset - 4);
            locktime = transaction.bytes(transaction.length - 4);
        }
        else {
            locktime = transaction.bytes(offset, 4);
        }
        result['version'] = version;
        result['inputs'] = inputs;
        result['outputs'] = outputs;
        result['locktime'] = locktime;
        if (witness) {
            result['witness'] = witnessScript;
        }
        else {
            // TODO : This conflicts with witness transactions - worry about it later, only affects Zcash so far
            offset += 4;
            if (offset != transaction.length) {
                result['extraData'] = transaction.bytes(offset);
            }
        }
        return result;
    },

    displayTransactionDebug: function (transaction) {
        console.log("version " + transaction['version'].toString(HEX));
        for (var i = 0; i < transaction['inputs'].length; i++) {
            var input = transaction['inputs'][i];
            console.log("input " + i + " prevout " + input['prevout'].toString(HEX) + " script " + input['script'].toString(HEX) + " sequence " + input['sequence'].toString(HEX));
        }
        for (var i = 0; i < transaction['outputs'].length; i++) {
            var output = transaction['outputs'][i];
            console.log("output " + i + " amount " + output['amount'].toString(HEX) + " script " + output['script'].toString(HEX));
        }
        console.log("locktime " + transaction['locktime'].toString(HEX));
        if (typeof transaction['witness'] != "undefined") {
            console.log("witness " + transaction['witness'].toString(HEX));
        }
    },

    setDriverMode_async: function (mode) {
        return this.card.sendApdu_async(0xe0, 0x2a, mode, 0x00, 0x00, [0x9000]);
    },

});

BTChip.MODE_WALLET = 0x01;
BTChip.MODE_RELAXED_WALLET = 0x02;
BTChip.MODE_SERVER = 0x04;
BTChip.MODE_DEVELOPER = 0x08;
BTChip.FLAG_RFC6979 = 0x80;

BTChip.FEATURE_UNCOMPRESSED_KEYS = 0x01;
BTChip.FEATURE_DETERMINISTIC_SIGNATURE = 0x02;
BTChip.FEATURE_FREE_SIGHASHTYPE = 0x04;
BTChip.FEATURE_NO_2FA_P2SH = 0x08;

BTChip.VERSION_BITCOIN_MAINNET = 0;
BTChip.VERSION_BITCOIN_P2SH_MAINNET = 5;

BTChip.QWERTY_KEYMAP = new ByteString("00271E1F202122232425260405060708090A0B0C0D0E0F101112131415161718191A1B1C1D372C28", HEX);
BTChip.AZERTY_KEYMAP = new ByteString("03271E1F202122232425261405060708090A0B0C0D0E0F331112130415161718191D1B1C1A362C28", HEX);

BTChip.QWERTY_KEYMAP_NEW = new ByteString("000000000000000000000000760f00d4ffffffc7000000782c1e3420212224342627252e362d3738271e1f202122232425263333362e37381f0405060708090a0b0c0d0e0f101112131415161718191a1b1c1d2f3130232d350405060708090a0b0c0d0e0f101112131415161718191a1b1c1d2f313035", HEX);
BTChip.AZERTY_KEYMAP_NEW = new ByteString("08000000010000200100007820c8ffc3feffff07000000002c38202030341e21222d352e102e3637271e1f202122232425263736362e37101f1405060708090a0b0c0d0e0f331112130415161718191d1b1c1a2f64302f2d351405060708090a0b0c0d0e0f331112130415161718191d1b1c1a2f643035", HEX);

BTChip.KEY_PREPARE_FLAG_BASE58_ENCODED = 0x02;
BTChip.KEY_PREPARE_FLAG_HASH_SHA256 = 0x04;
BTChip.KEY_PREPARE_DERIVE = 0x08;
BTChip.KEY_PREPARE_FLAG_RAW = 0x20;

BTChip.SIGHASH_ALL = 1;

BTChip.EXTERNAL_CHAIN = 1;
BTChip.INTERNAL_CHAIN = 2;

BTChip.DEFAULT_LOCKTIME = new ByteString("00000000", HEX);
