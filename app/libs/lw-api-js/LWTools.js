var LWTools = {
    debug: 3,

    console: function (message, lvl){

        lvl = (typeof lvl === "undefined") ? 0 : lvl;

        if(lvl <= this.debug){
            if(lvl == 0){
                window.ledger.utils.logger.debug(message);
            }else if(lvl == 1){
                window.ledger.utils.logger.error(message);
            }else if(lvl == 2){
                window.ledger.utils.logger.warn(message);
            }else if(lvl == 3){
                window.ledger.utils.logger.info(message);
            }
        }
    },

    isFunction: function (functionToCheck) {
        var getType = {};
        return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
    },

    ajax: function (method, url, data) {

        return new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.onload = function() {
                if (xhr.status == 200) {
                    var response = xhr.response;
                    try{
                        response = JSON.parse(response);
                    } finally {
                        resolve(response);
                    }
                } else {
                    reject(Error(xhr.statusText));
                }
            };
            xhr.onerror = function() {
                reject(Error("Network Connection Error !"));
            };
            xhr.open(method, url, true);
            if (method == "POST") {
                xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            }
            xhr.send(data);
        });

    },

    parseBitcoinValue: function (valueString) {
        // TODO: Detect other number formats (e.g. comma as decimal separator)
        valueString = valueString.toString();
        var valueComp = valueString.split('.');
        var integralPart = valueComp[0];
        var fractionalPart = valueComp[1] || "0";
        while (fractionalPart.length < 8) fractionalPart += "0";
            fractionalPart = fractionalPart.replace(/^0+/g, '');
        var value = Bitcoin.BigInteger.valueOf(parseInt(integralPart));
        value = value.multiply(Bitcoin.BigInteger.valueOf(100000000));
        value = value.add(Bitcoin.BigInteger.valueOf(parseInt(fractionalPart)));
        var valueString = value.toString(16);
        while (valueString.length < 16) {
            valueString = "0" + valueString;
        }
        return new ByteString(valueString, HEX);
    },

    pickUnspent: function (resultUnspent, desiredAmount) {
        var chosenTransactions = [];
        /* Sort all transactions by smallest value */
        var resultUnspentSorted = resultUnspent.sort(function(item1, item2) {
            var value1 = new BigInteger(item1['value'], 16);
            var value2 = new BigInteger(item2['value'], 16);
            return value1.compareTo(value2);
        });
        /* Pick transactions until the amount is found */
        var cumulatedValue = BigInteger.ZERO;
        for (var i=0; i<resultUnspentSorted.length; i++) {
            chosenTransactions.push(resultUnspentSorted[i]);
            cumulatedValue = cumulatedValue.add(new BigInteger(resultUnspentSorted[i]['value'], 16));
            if (cumulatedValue.compareTo(desiredAmount) >= 0) {
            break;
            }
        }
        return chosenTransactions;
    },

}