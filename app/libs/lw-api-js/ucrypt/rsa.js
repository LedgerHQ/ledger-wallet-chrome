/*
************************************************************************
Copyright (c) 2013 UBINITY SAS, Cédric Mesnil <cedric.mesnil@ubinity.com>

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



((JSUCrypt.signature && JSUCrypt.signature.RSA) && (JSUCrypt.cipher && JSUCrypt.cipher.RSA)) || (function (undefined) {

    // --------------------------------------------------------------------------
    //                                   Signature
    // --------------------------------------------------------------------------
    if (JSUCrypt.signature && !JSUCrypt.signature.RSA) {
        /** 
         * An RSA Signature
         * @class  JSUCrypt.signature.RSA 
         * @param {JSUCrypt.hash}   hasher     a hasher
         * @param {JSUCrypt.padder} padder     a padder
         * @see JSUCrypt.signature
         * @see JSUCrypt.hash
         * @see JSUCrypt.padder
         */
        JSUCrypt.signature.RSA = function(hasher, padder) {        
            if(!padder) {
                padder = JSUCrypt.padder.None;
            }
            this._padder = padder;
            this._hash = hasher; 
            this.reset();
        };

        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#init
         */    
        JSUCrypt.signature.RSA.prototype.init = function(key, mode) {
            if (mode == JSUCrypt.signature.MODE_SIGN) {
                if ( (! key instanceof JSUCrypt.key.RSAPrivateKey) && 
                     (! key instanceof JSUCrypt.key.CRTPrivateKey) ){
                    throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
                }
            } else if (mode == JSUCrypt.signature.MODE_VERIFY) {
                if ( ! key instanceof JSUCrypt.key.RSAPublicKey) {
                    throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
                }
            } else {
                throw new JSUCrypt.JSUCryptException("Invalid 'mode' parameter");
            }
            this._key = key;
            this._mode = mode;
        };
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#reset
         * @function
         */
        JSUCrypt.signature.RSA.prototype.reset     = JSUCrypt.signature._asymReset;
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#update
         * @function
         */
        JSUCrypt.signature.RSA.prototype.update    = JSUCrypt.signature._asymUpdate;
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#sign
         * @function
         */
        JSUCrypt.signature.RSA.prototype.sign      = JSUCrypt.signature._asymSign;
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#verify
         * @function
         */
        JSUCrypt.signature.RSA.prototype.verify    = JSUCrypt.signature._asymVerify;


        JSUCrypt.signature.RSA.prototype._doSign = function (h) {            
            var klen = this._key.size/8;
            //padd
            var blk;
            blk = [].concat(this._hash.PKCS1_OID).concat(h);
            blk = this._padder.pad(blk, this._key.size/8, false);
            //sign
            blk = JSUCrypt.utils.anyToBigInteger(blk);
            blk = blk.modPow(this._key.d,this._key.n);
            return JSUCrypt.utils.normalizeByteArrayUL(blk.toByteArray(),klen);
        };

        JSUCrypt.signature.RSA.prototype._doVerify = function (h, sig) {
            var klen = this._key.size/8;
            //decrypt
            var blk = JSUCrypt.utils.anyToBigInteger(sig);
            blk = blk.modPow(this._key.e,this._key.n);
            blk = JSUCrypt.utils.normalizeByteArrayUL(blk.toByteArray(),klen);
            //add missing zero
            
            blk = this._padder.unpad(blk, klen, false);
            var expected = [];
            var oidlen = 0;
            var oid = [];
            if (this._hash.PKCS1_OID) {                
                oid = this._hash.PKCS1_OID;
                expected.append(oid);
                oidlen = expected.length;
            }
            expected.append(h);
            //check length
            if (expected.length != oidlen + h.length) {
                return false;
            }
            //check OID
            for ( i = 0; i< oidlen; i++) {
                if (expected[i] != oid[i]) {
                    return false;
                }                
            }
            expected = expected.slice(oidlen);
            //check h
            for ( i = 0; i< h.length; i++) {
                if (expected[i] != h[i]) {
                    return false;
                }
            }
            return true;
        };
    }

    // --------------------------------------------------------------------------
    //                                   Cipher
    // --------------------------------------------------------------------------
    if (JSUCrypt.cipher && !JSUCrypt.cipher.RSA) {
        /** 
         * An RSA Cipher
         * @class JSUCrypt.cipher.RSA 
         * @param {JSUCrypt.padder} padder       a padder
         * @see JSUCrypt.cipher
         * @see JSUCrypt.padder
         */
        JSUCrypt.cipher.RSA = function(padder) {       
            if(!padder) {                
                padder = JSUCrypt.padder.None;
            }
            this._padder = padder;
            this.reset();
        };

        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#init
         */
        JSUCrypt.cipher.RSA.prototype.init = function(key, mode) {
            if (mode == JSUCrypt.cipher.MODE_DECRYPT) {
                if ( (! key instanceof JSUCrypt.key.RSAPrivateKey) && 
                     (! key instanceof JSUCrypt.key.CRTPrivateKey) ){
                    throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
                }
            } else if (mode == JSUCrypt.cipher.MODE_ENCRYPT) {
                if ( ! key instanceof JSUCrypt.key.RSAPublicKey) {
                    throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
                }
            } else {
                throw new JSUCrypt.JSUCryptException("Invalid 'mode' parameter");
            }
            this._key = key;
            this._enc_mode = mode;
        };
        
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#reset
         * @function
         */
        JSUCrypt.cipher.RSA.prototype.reset     = JSUCrypt.cipher._asymReset;
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#update
         * @function
         */
        JSUCrypt.cipher.RSA.prototype.update    = JSUCrypt.cipher._asymUpdate;
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#finalize
         * @function
         */
        JSUCrypt.cipher.RSA.prototype.finalize  = JSUCrypt.cipher._asymFinalize;

        JSUCrypt.cipher.RSA.prototype._doCrypt  = function(data) {
            var klen = this._key.size/8;
            //padd
            var blk;            
            blk = this._padder.pad(data, klen, true);
            blk = JSUCrypt.utils.anyToBigInteger(blk);
            //crypt
            blk = JSUCrypt.utils.anyToBigInteger(blk);
            blk = blk.modPow(this._key.e,this._key.n);
            blk = JSUCrypt.utils.normalizeByteArrayUL(blk.toByteArray(),klen);
            return blk;
        };

        JSUCrypt.cipher.RSA.prototype._doDecrypt = function(data) {
            var klen = this._key.size/8;
            //decrypt
            var blk;
            blk = JSUCrypt.utils.anyToBigInteger(data);
            blk = blk.modPow(this._key.d,this._key.n);
            blk = JSUCrypt.utils.normalizeByteArrayUL(blk.toByteArray(),klen);
            //unpadd
            blk = this._padder.unpad(blk, klen, true);
            return blk;            
        };
    }
  
    // --------------------------------------------------------------------------
    //                                   Keys
    // --------------------------------------------------------------------------

    /**
     * Public RSA key container.
     *
     * @param {number}      size     key size in bits 
     * @param {anyBN}       e        public exponent
     * @param {anyBN}       n        modulus
     * @class
     */
    JSUCrypt.key.RSAPublicKey = function (size, e, n) {       
        this.size     = size;
        this.e        = JSUCrypt.utils.anyToBigInteger(e);
        this.n        = JSUCrypt.utils.anyToBigInteger(n);
    };
    
    /**
     * Private RSA key container.
     *
     * @param {number}      size     key size in bits 
     * @param {anyBN}       d        private exponent
     * @param {anyBN}       n        modulus
     * @class     
     */
    JSUCrypt.key.RSAPrivateKey = function(size, d, n) {
        this.size     = size;
        this.d        = JSUCrypt.utils.anyToBigInteger(d);
        this.n        = JSUCrypt.utils.anyToBigInteger(n);
    };

    /**
     * Private RSA CRT key container.
     *
     * @param {number}      size     key size in bits 
     * @param {anyBN}       p        
     * @param {anyBN}       q        
     * @param {anyBN}       dp       
     * @param {anyBN}       dq       
     * @param {anyBN}       qinv     
     * @class
     */
    JSUCrypt.key.RSACRTPrivateKey = function(size, p, q, dp, dq, qinv) {
        this.size     = size;
        this.p        = JSUCrypt.utils.anyToBigInteger(p);
        this.q        = JSUCrypt.utils.anyToBigInteger(q);
        this.dp       = JSUCrypt.utils.anyToBigInteger(dp);
        this.dq       = JSUCrypt.utils.anyToBigInteger(dq);
        this.qinv     = JSUCrypt.utils.anyToBigInteger(qinv);
    };

}());

