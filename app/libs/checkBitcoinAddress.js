(function () {

    function base58_decode(string) {
        var table = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
        var table_rev = new Array();

        var i;
        for (i = 0; i < 58; i++) {
            table_rev[table[i]] = int2bigInt(i, 8, 0);
        }

        var l = string.length;
        var long_value = int2bigInt(0, 1, 0);

        var num_58 = int2bigInt(58, 8, 0);

        var c;
        for(i = 0; i < l; i++) {
            c = string[l - i - 1];
            long_value = add(long_value, mult(table_rev[c], pow(num_58, i)));
        }

        var hex = bigInt2str(long_value, 16);

        var str = hex2a(hex);

        var nPad;
        for (nPad = 0; string[nPad] == table[0]; nPad++);

        var output = str;
        if (nPad > 0) output = repeat("\0", nPad) + str;

        return output;
    }

    function hex2a(hex) {
        var str = '';
        for (var i = 0; i < hex.length; i += 2)
            str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
        return str;
    }

    function a2hex(str) {
        var aHex = "0123456789abcdef";
        var l = str.length;
        var nBuf;
        var strBuf;
        var strOut = "";
        for (var i = 0; i < l; i++) {
            nBuf = str.charCodeAt(i);
            strBuf = aHex[Math.floor(nBuf/16)];
            strBuf += aHex[nBuf % 16];
            strOut += strBuf;
        }
        return strOut;
    }

    function pow(big, exp) {
        if (exp == 0) return int2bigInt(1, 1, 0);
        var i;
        var newbig = big;
        for (i = 1; i < exp; i++) {
            newbig = mult(newbig, big);
        }

        return newbig;
    }

    function repeat(s, n){
        var a = [];
        while(a.length < n){
            a.push(s);
        }
        return a.join('');
    }

    function ia2hex(ia) {
        var aHex = "0123456789abcdef";
        var l = ia.length;
        var nBuf;
        var strBuf;
        var strOut = "";
        for (var i = 0; i < l; i++) {
            nBuf = ia[i];
            strBuf = aHex[Math.floor(nBuf/16)];
            strBuf += aHex[nBuf % 16];
            strOut += strBuf;
        }
        return strOut;
    }

    ledger.bitcoin = {};

    ledger.bitcoin.checkAddress = function (address) {
        var decoded = hex2a(ia2hex(bs58.decode(address)));

        var cksum = decoded.substr(-4);
        var rest = decoded.substr(0, decoded.length - 4);
        var good_cksum = hex2a(sha256_digest(hex2a(sha256_digest(rest)))).substr(0, 4);

        var version = parseInt(new ByteString(rest.substr(0, rest.length - 20), ASCII).toString(HEX), 16);
        if (cksum != good_cksum || (version !== ledger.config.network.version.P2SH && version !== ledger.config.network.version.regular)) return false;
        return true;
    }

    ledger.bitcoin.checkAddressBlake = function (address) {
        var decoded = hex2a(ia2hex(bs58.decode(address)));
        var cksum = decoded.substr(-4);
        var rest = decoded.substr(0, decoded.length - 4);
        var blake256 = blake.createhash('blake256')
        var hash = blake256.update(rest).digest()
        blake256 = blake.createhash('blake256')
        hash = blake256.update(hash).digest('hex')
        var good_cksum = hex2a(hash).substr(0, 4);

        var version = parseInt(new ByteString(rest.substr(0, rest.length - 20), ASCII).toString(HEX), 16);
        if (cksum != good_cksum || (version !== ledger.config.network.version.P2SH && version !== ledger.config.network.version.regular)) return false;
        return true;
    }

})()