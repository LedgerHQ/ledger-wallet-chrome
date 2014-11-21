function LWTransaction (wallet) {
    LWTools.console("LWTransaction.construct", 3);
    this.wallet = wallet;
    this.fee = 0.0001,
    this.amount = 0;
    this.destinationAddress = null;
    this.pendingSignature = undefined;
    this.txSec = "";
    this.minConfirm = 2;

}

LWTransaction.prototype = {

    constructor: LWTransaction,

    event: function (eventName, data) {
        var lWTransaction = this;

        lWTransaction.wallet.lW.deviceManager.emit(eventName, data);

        //window.dispatchEvent(new CustomEvent(eventName, data));
    },

    reset: function (){
        LWTools.console("LWTransaction.reset", 3);
        var lWTransaction = this;

        lWTransaction.fee = 0.0001;
        lWTransaction.amount = 0;
        lWTransaction.destinationAddress = null;
        lWTransaction.pendingSignature = undefined;
        lWTransaction.txSec = "";
    },

    checkAmount: function(amount){
        LWTools.console("LWTransaction.checkAmount", 3);
        var lWTransaction = this;

        if(isNaN(amount)){
            throw translations.wallet.pleaseEnterValidAmount;
        }

        if (parseFloat(amount) > lWTransaction.wallet.balance){
            throw translations.wallet.sendMoreBTCThanYouHave;
        }

        if (parseFloat(amount * 100000000) + (lWTransaction.fee * 100000000) > (lWTransaction.wallet.balance * 100000000)){
            var mess = translations.wallet.notEnoughBTCForFees;
            mess = mess.replace(/__fee__/g, lWTransaction.fee);
            throw mess;
        }

        if (parseFloat(amount) == 0 || amount == ""){
            throw translations.wallet.pleaseEnterAnAmount;
        }

        if (parseFloat(amount) < 0.00001){
            throw translations.wallet.minAmount;
        }

        if ((amount.split('.')[1] || []).length > 7){
            throw translations.wallet.amountDecimalLimit;
        }

        return true;
    },

    setAmount: function(amount){
        LWTools.console("LWTransaction.setAmount", 3);
        var lWTransaction = this;

        try{
            if(lWTransaction.checkAmount(amount)){
                lWTransaction.amount = parseFloat(amount);
            }
        }catch(error){
            throw(error);
        }

    },

    checkAddress: function(address){
        LWTools.console("LWTransaction.checkAddress", 3);
        var lWTransaction = this;

        try{
            var res = Bitcoin.base58.checkDecode(address);
            var version = res.version
            var payload = res.slice(0);
            if (version == 0)
                return true;
        }catch (err){
            throw(translations.wallet.malformedAddress);
        }
    },

    setAddress: function(address){
        LWTools.console("LWTransaction.setAddress", 3);
        var lWTransaction = this;

        try{
            if(lWTransaction.checkAddress(address)){
                lWTransaction.destinationAddress = address;
            }
        }catch(error){
            throw(error);
        }
    },

    generate: function(){
        LWTools.console("LWTransaction.generate", 3);
        var lWTransaction = this;


        lWTransaction.getUnspentForDongle(lWTransaction.wallet.address, "0'/0/0").then(function(result) {
            return lWTransaction.getUnspentForDongle(lWTransaction.wallet.addressChange, "0'/1/0").then(function(result2) {

                for (var i=0; i<result2["unspent"].length; i++) {
                    result["unspent"].push(result2["unspent"][i])
                }

                if(result["unspent"].length == 0){

                    /* Event : LWTransaction.ErrorOccured */
                    lWTransaction.event('LWTransaction.ErrorOccured', {lWTransaction: lWTransaction, title: 'unspentMinConfirm'});

                    return;
                }

                /* Get the transactions we need */
                var transactionAmount = LWTools.parseBitcoinValue(lWTransaction.amount);
                var transactionFees = LWTools.parseBitcoinValue(lWTransaction.fee);
                var transactionTotal = new BigInteger(transactionAmount.toString(HEX), 16).add(new BigInteger(transactionFees.toString(HEX), 16));
                result = LWTools.pickUnspent(result["unspent"], transactionTotal);
                lWTransaction.pendingSignature = {};
                lWTransaction.pendingSignature['in'] = result;
                LWTools.console("getUnspent result", 3);
                LWTools.console(result, 3);
                var inputs = [];
                var keyReferences = [];
                for (var i=0; i<result.length; i++) {
                    var splitTransaction = lWTransaction.wallet.lW.dongle.splitTransaction(new ByteString(result[i]['rawtx'], HEX));
                    LWTools.console(splitTransaction, 3);
                    inputs.push([ splitTransaction, result[i]['index']]);
                    keyReferences.push(result[i]['internalAddress']);
                }


                lWTransaction.wallet.lW.dongle.createPaymentTransaction_async(
                    inputs,
                    keyReferences,
                    "0'/1/0",
                    new ByteString(lWTransaction.destinationAddress, ASCII),
                    transactionAmount,
                    transactionFees).then(function(result) {

                        if(lWTransaction.wallet.lW.operationMode == 4){
                            LWTools.console("Mode Server", 3);

                            lWTransaction.txHex = result.toString(HEX);
                            LWTools.console(lWTransaction.txHex, 3);

                            /* Event : LWTransaction.Generated */
                            lWTransaction.event('LWTransaction.Generated', {lWTransaction: lWTransaction});

                        }else{

                            lWTransaction.pendingSignature['out'] = result;

                            var pendingTransaction = {};
                            pendingTransaction['pendingSignature'] = lWTransaction.pendingSignature;

                            lWTransaction.pendingSignature.out.scriptData = lWTransaction.pendingSignature.out.scriptData.toString(HEX);
                            var trustedInputs = [];
                            for (var i=0; i<lWTransaction.pendingSignature.out.trustedInputs.length; i++) {
                                trustedInputs.push(lWTransaction.pendingSignature.out.trustedInputs[i].toString(HEX));
                            }
                            lWTransaction.pendingSignature.out.trustedInputs = trustedInputs;
                            var publicKeys = [];
                            for (var i=0; i<lWTransaction.pendingSignature.out.publicKeys.length; i++) {
                                publicKeys.push(lWTransaction.pendingSignature.out.publicKeys[i].toString(HEX));
                            }
                            lWTransaction.pendingSignature.out.publicKeys = publicKeys;
                            pendingTransaction['address'] = lWTransaction.destinationAddress;
                            pendingTransaction['amount'] = lWTransaction.amount;


                            LWTools.console('Fin de génération de la transaction', 3);



                            if(result.authorizationRequired == 0x01){
                                lWTransaction.validation = "pin";
                                LWTools.console("Mode Wallet", 3);

                                /* Event : LWTransaction.WaitSignatureToValidate */
                                lWTransaction.event('LWTransaction.WaitSignatureToValidate', {lWTransaction: lWTransaction, authorization: result.authorizationRequired});

                            }else if(result.authorizationRequired == 0x02){
                                lWTransaction.validation = "keycard";
                                LWTools.console("Mode KeyCard", 3);

                                /* Event : LWTransaction.WaitSignatureToValidate */
                                lWTransaction.event('LWTransaction.WaitSignatureToValidate', {lWTransaction: lWTransaction, authorization: result.authorizationRequired, keyCardIndexesAddr: result.indexesKeyCard});

                            }
                        }
                    }).fail(function(error) {
                        LWTools.console("createPaymentTransaction error", 1);
                        LWTools.console(error, 1);

                        /* Event : LWTransaction.ErrorOccured */
                        lWTransaction.event('LWTransaction.ErrorOccured', {lWTransaction: lWTransaction, title: 'signingFailed', message: error});                        

                    });
            });
        }, function(error) {
            LWTools.console("getUnspent error", 1);
            LWTools.console(error, 1);

            /* Event : LWTransaction.ErrorOccured */
            lWTransaction.event('LWTransaction.ErrorOccured', {lWTransaction: lWTransaction, title: 'signingFailed', message: error});

        });
    },

    signature: function(PINSign){
        LWTools.console("LWTransaction.signature", 3);
        var lWTransaction = this;

        lWTransaction.pendingSignature.out.scriptData = new ByteString(lWTransaction.pendingSignature.out.scriptData, HEX);
        var trustedInputs = [];
        for (var i=0; i<lWTransaction.pendingSignature.out.trustedInputs.length; i++) {
            trustedInputs.push(new ByteString(lWTransaction.pendingSignature.out.trustedInputs[i], HEX));
        }
        lWTransaction.pendingSignature.out.trustedInputs = trustedInputs;
        var publicKeys = [];
        for (var i=0; i<lWTransaction.pendingSignature.out.publicKeys.length; i++) {
            publicKeys.push(new ByteString(lWTransaction.pendingSignature.out.publicKeys[i], HEX));
        }
        lWTransaction.pendingSignature.out.publicKeys = publicKeys;

        var pendingSignature = lWTransaction.pendingSignature;
        lWTransaction.pendingSignature = undefined;
        var result = pendingSignature['in'];
        LWTools.console(pendingSignature, 3);
        LWTools.console(result, 3);
        var inputs = [];
        var keyReferences = [];
        for (var i=0; i<result.length; i++) {
            var splitTransaction = lWTransaction.wallet.lW.dongle.splitTransaction(new ByteString(result[i]['rawtx'], HEX));
            LWTools.console(splitTransaction, 3);
            inputs.push([ splitTransaction, result[i]['index']]);
            keyReferences.push(result[i]['internalAddress']);
        }

        LWTools.console("Finalizing signature, please wait", 3);


        if(lWTransaction.validation == "keycard"){
            PIN = new ByteString(PINSign, HEX);
        }else{
            PIN = new ByteString(PINSign, ASCII);
        }

        lWTransaction.wallet.lW.dongle.createPaymentTransaction_async(
            inputs,
            keyReferences,
            "0'/1/0",
            new ByteString(lWTransaction.destinationAddress, ASCII),
            LWTools.parseBitcoinValue(lWTransaction.amount),
            LWTools.parseBitcoinValue(lWTransaction.fee),
            undefined, undefined,
            PIN,
            pendingSignature['out']).then(function(result) {
                LWTools.console("createPaymentTransaction result", 3);
                LWTools.console(result, 3);
                lWTransaction.txHex = result.toString(HEX);
                LWTools.console(lWTransaction.txHex, 3);

                /* Event : LWTransaction.Generated */
                lWTransaction.event('LWTransaction.Generated', {lWTransaction: lWTransaction});

            }).fail(function(error) {
                LWTools.console("createPaymentTransaction error", 1);
                LWTools.console(error, 1);

                /* Event : LWTransaction.ErrorOccured */
                lWTransaction.event('LWTransaction.ErrorOccured', {lWTransaction: lWTransaction, title: 'signingFailed', message: error});

            });
    },

    send: function(){
        LWTools.console("LWTransaction.send", 3);
        var lWTransaction = this;

        var url = lWTransaction.wallet.blockchain+'/chain/transactions';

        LWTools.ajax("POST", 
            url, 
            JSON.stringify({hex: lWTransaction.txHex})
        ).then(function(data) {

            /* Event : LWTransaction.Sent */
            lWTransaction.event('LWTransaction.Sent', {lWTransaction: lWTransaction});

        }, function(error){
            LWTools.console("There seems to be a problem with building the transaction. This in no way affects the safety of your Bitcoins.", 1);

            /* Event : LWTransaction.NotSent */
            lWTransaction.event('LWTransaction.NotSent', {lWTransaction: lWTransaction});
        });

    },

    getUnspentForDongle: function(address, internalAddress){
        LWTools.console("LWTransaction.getUnspentForDongle", 3);
        var lWTransaction = this;

        var resultData = {};
        resultData['address'] = address;
        resultData['unspent'] = [];

        url = lWTransaction.wallet.blockchain+'/chain/addresses/'+address+'/unspents';

        return LWTools.ajax("GET", url).then(function (result) {

            var deferred = Q.defer();

            /* compute trusted inputs */
            async.each( result, function (unspent, finishedCallback) {
            
                if (unspent['confirmations'] < lWTransaction.minConfirm) {

                    /* Chain.com ne mettant pas à jour au même instant les conf des tx et des unspent, on vérife si la tx n'est pas confirmée: */

                    var tmpTX = null;
                    lWTransaction.wallet.transactions.forEach(function(t){
                        if(lWTransaction.wallet.transactions[t].hash == unspent['transaction_hash']){
                            tmpTX = lWTransaction.wallet.transactions[t];
                        }
                    });

                    if(tmpTX){
                        if(tmpTX.confirmations < lWTransaction.minConfirm){
                            /* Contains the list of wallets */
                            finishedCallback();
                            return;
                        }else{
                            unspent['confirmations'] = tmpTX.confirmations;
                        }
                    }else{
                        /* Contains the list of wallets */
                        finishedCallback();
                        return;
                    }
                }

                var url = lWTransaction.wallet.blockchain+'/chain/transactions/'+unspent['transaction_hash']+'/hex';

                LWTools.ajax("GET", url).then(function (rawtx) {

                    rawtx = rawtx.hex;

                    LWTools.console('rawtx :', 3);
                    LWTools.console(rawtx, 3);

                    /* append the raw transaction that generated each unspent output (for later selection) */
                    var transactionElement = {};
                    transactionElement['rawtx'] = rawtx;
                    transactionElement['index'] = unspent['output_index'];
                    transactionElement['value'] = unspent['value'].toString(16);


                    transactionElement['internalAddress'] = internalAddress;
                    resultData['unspent'].push(transactionElement);

                    finishedCallback();

                }, function (err) {
                    LWTools.console("error gettxraw", 1);
                    LWTools.console(err, 1);

                    /* Event : LWTransaction.ErrorOccured */
                    lWTransaction.event('LWTransaction.ErrorOccured', {lWTransaction: lWTransaction, title: problemGetData, message: err});


                });
            }, function (enderr) {
                if ((typeof enderr != "undefined") && (enderr != null)) {
                    deferred.reject(enderr);
                }
                /* if another pending request, then abort the current one */
                if (1 == 1) {
                    deferred.resolve(resultData);
                } else {
                    deferred.reject("Another address is being processed");
                }
            });

            return deferred.promise.fail(function (err) {
                LWTools.console("Can't process unspent outputs for that address", 1);
                LWTools.console(err, 1);
                throw (err, "Can't process unspent outputs for that address");
            });

        }, function (err) {
            LWTools.console("Can't retrieve balance for that address :"+address, 1);
            LWTools.console(err, 1);
            throw (err, "Can't retrieve balance for that address :"+address);
        });

    }

}