/*
************************************************************************
Copyright (c) 2013 UBINITY SAS,  Cédric Mesnil <cedric.mesnil@ubinity.com>

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
/**
 * @project JSUCrypt
 * @author Cédric Mesnil <cedric.mesnil@ubinity.com>
 * @license Apache License, Version 2.0
 */



// --------------------------------------------------------------------------
//                                   ECDSA
// --------------------------------------------------------------------------

JSUCrypt.signature.ECDSA  ||  (function (undefined) {
    /** 
     * An ECDSA Signature
     * @class  JSUCrypt.signature.ECDSA
     * @param {JSUCrypt.hash} hasher an hasher
     * @see JSUCrypt.cipher
     * @see JSUCrypt.hash
     */
    JSUCrypt.signature.ECDSA = function(hash) {        
        this._hash = hash; 
        this._randMethod = "PRNG";
        this.reset();
    };

    /**
     * @see JSUCrypt.signature#init
     */    
    JSUCrypt.signature.ECDSA.prototype.init = function(key, mode) {
        if (mode == JSUCrypt.signature.MODE_SIGN) {
            if ( ! key instanceof JSUCrypt.key.EcFpPrivateKey) {
                throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
            }
        } else if (mode == JSUCrypt.signature.MODE_VERIFY) {
            if ( ! key instanceof JSUCrypt.key.EcFpPublicKey) {
                throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
            }
        } else {
            throw new JSUCrypt.JSUCryptException("Invalid 'mode' parameter");
        }
        this._key = key;
        this._mode = mode;
        this.reset();
    };


    /**
     * Change the way the random k in generated during the ECDSA signature.
     *
     * Known method are:
     *
     *   - "PRNG"
     *   - "RFC6979"
     *
     * @param {string} meth   random generator to use.
     * @function
     */
    JSUCrypt.signature.ECDSA.prototype.setRandomMethod = function (meth) {
        this._randMethod = meth;
    };

    /**
     * @param {X} X X   
     * @see JSUCrypt.signature#reset
     * @function
     */
    JSUCrypt.signature.ECDSA.prototype.reset     = JSUCrypt.signature._asymReset;
    /**
     * @param {X} X X   
     * @see JSUCrypt.signature#update
     * @function
     */
    JSUCrypt.signature.ECDSA.prototype.update    = JSUCrypt.signature._asymUpdate;
    /**
     * @param {X} X X   
     * @see JSUCrypt.signature#sign
     * @function
     */
    JSUCrypt.signature.ECDSA.prototype.sign      = JSUCrypt.signature._asymSign;
    /**
     * @param {X} X X   
     * @see JSUCrypt.signature#version
     * @function
     */
    JSUCrypt.signature.ECDSA.prototype.verify    = JSUCrypt.signature._asymVerify;

    JSUCrypt.signature.ECDSA.prototype._doSign = function (mh) {  
        var order = this._key.domain.order;        

        var h = new BigInteger(JSUCrypt.utils.byteArrayToHexStr(mh),16);
        var hlen;

        for(;;) {
            //peek random
            var k;
            var key_blen =  this._key.size>>>3;
            if (this._randMethod.equals("PRNG")) {
                k = [];
                //True Random
                var i = key_blen;
                while (i--) {
                    k.push(Math.floor(Math.random()*255));
                }
                k = JSUCrypt.utils.byteArrayToHexStr(k);
                k = new BigInteger(k,16);
                k = k.mod(order);
            } else if (this._randMethod.equals("RFC6979")) {
                var d = this._key.d.toByteArray();
                d = JSUCrypt.utils.normalizeByteArrayUL(d, Math.ceil(order.bitLength()/8));

                var h1 = h;
                hlen = this._hash.length*8;
                if (hlen>order.bitLength()) {
                    h1 = h1.shiftRight(hlen-order.bitLength());
                }
                h1 = h1.mod(order);
                h1 = h1.toByteArray();
                h1 = JSUCrypt.utils.normalizeByteArrayUL(h1, Math.ceil(order.bitLength()/8));
   
                for (;;) {
                    var loop;
                    if (loop == undefined) {
                        var hmac = new JSUCrypt.signature.HMAC(this._hash);
                        //b.  Set:          V = 0x01 0x01 0x01 ... 0x01
                        var V = [];
                        hlen = this._hash.length;
                        while(hlen--) {
                            V.push(0x01);
                        }
                        //c. Set: K = 0x00 0x00 0x00 ... 0x00
                        var K = [];
                        hlen = this._hash.length;
                        while(hlen--) {
                            K.push(0x00);
                        }
                        //d.  Set: K = HMAC_K(V || 0x00 || int2octets(x) || bits2octets(h1))
                        hmac.init( new JSUCrypt.key.HMACKey(K), JSUCrypt.signature.MODE_SIGN);
                        hmac.update(V);
                        hmac.update([0]);
                        hmac.update(d);
                        K = hmac.sign(h1);
                        //e.  Set: V = HMAC_K(V) 
                        hmac.init(new JSUCrypt.key.HMACKey(K), JSUCrypt.signature.MODE_SIGN);
                        V =  hmac.sign(V);
                        //f.  Set:  K = HMAC_K(V || 0x01 || int2octets(x) || bits2octets(h1))
                        hmac.update(V);
                        hmac.update([1]);
                        hmac.update(d);
                        K = hmac.sign(h1);
                        //g. Set: V = HMAC_K(V) 
                        hmac.init(new JSUCrypt.key.HMACKey(K), JSUCrypt.signature.MODE_SIGN);
                        V =  hmac.sign(V);
                        loop = 0;
                    } else {
                        //h.3 loop
                        hmac.update(V);                            
                        K = hmac.sign([0]);
                        hmac.init(new JSUCrypt.key.HMACKey(K), JSUCrypt.signature.MODE_SIGN);
                        V = hmac.sign(V);
                        loop++;
                    }
                    //h. Apply the following algorithm until a proper value is found fo  k:
                    //  h.1 
                    var T = [];
                    //  h.2
                    var orderlen = Math.ceil(order.bitLength()/8);
                    while (T.length<orderlen) {
                        V = hmac.sign(V);
                        T = T.concat(V);
                    }
                    //  h.3
                    hlen = T.length*8;
                    k = new BigInteger("00"+JSUCrypt.utils.byteArrayToHexStr(T),16);
                    if (hlen > order.bitLength()) {
                        k = k.shiftRight(hlen-order.bitLength());
                    }                    
                    if (!k.equals(BigInteger.ZERO) &&
                        (k.compareTo(order.subtract(BigInteger.ONE))<0)) {
                        break;
                    }
                }
            } else {
                throw new JSUCrypt.JSUCryptException("Invalid ECDSA random  method");
            }

            //align h
            hlen = this._hash.length*8;
            if (hlen>order.bitLength()) {
                h = h.shiftRight(hlen-order.bitLength());
            }
            //compute kG
            var  kG   = this._key.domain.G.multiply(k);
            //extract sig r,s
            var  x     = kG.x.mod(order);
            if (k.equals(BigInteger.ZERO)) {
                continue;   
            }
            var  kinv  = k.modInverse(order);
            var  dx    = this._key.d.multiply(x).mod(order);
            var  h_dx  = h.add(dx).mod(order);
            var  y     = (kinv.multiply(h_dx)).mod(order); 
            if (y.equals(BigInteger.ZERO)) {
                continue;   
            }
            break;
        } 

        var r = x.toByteArray();
        var s = y.toByteArray();
        
        r = [0x02, r.length].concat(r);
        s = [0x02, s.length].concat(s);
        
        return [0x30, r.length+s.length].concat(r).concat(s);        
    };

    JSUCrypt.signature.ECDSA.prototype._doVerify = function(mh, sig) {
        sig = JSUCrypt.utils.anyToByteArray(sig);
        var order = this._key.domain.order;

        //finalize hash        
        var h = new BigInteger(JSUCrypt.utils.byteArrayToHexStr(mh),16);
        //align h
        var hlen = this._hash.length*8;
        if (hlen>order.bitLength()) {
            h = h.shiftRight(hlen-order.bitLength());
        }
        //extract r/s
        var r = sig.slice(4,4+sig[3]);
        var s = sig.slice(4+sig[3]+2);

        s = new BigInteger(JSUCrypt.utils.byteArrayToHexStr(s),16);
        r = new BigInteger(JSUCrypt.utils.byteArrayToHexStr(r),16);
        //check format
        var offset =  4+ (sig[3]&0xFF);
        if ((sig[0] != 0x30)                         ||
            (sig[1] != (4+sig[3]+sig[offset+1]))     ||
            (sig[2] != 0x02)                         ||
            (sig[offset] != 0x02)) {
            return false;
        }
        //precheck r/s
        var order_1 = order.subtract(BigInteger.ONE);

        if ((r.compareTo(order_1)>=0) ||
            (r.compareTo(order_1)>=0)){
            return false;
        }
        
        var w   = s.modInverse(order); 
        var u1  = (h.multiply(w)).mod(order);
        var u2  = (r.multiply(w)).mod(order);
        var u1G = this._key.domain.G.toProjective().multiply(u1);
        var u2Q = this._key.W.toProjective().multiply(u2);

        var xy  = u2Q.add(u1G).toAffine();
        var verified =  xy.x.mod(order).equals(r);
        return verified;
    };

}());
