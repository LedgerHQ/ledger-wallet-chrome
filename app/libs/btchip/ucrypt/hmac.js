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



(JSUCrypt.signature && JSUCrypt.signature.MAC) || (function (undefined) {

    // --------------------------------------------------------------------------
    //                                   Signature
    // --------------------------------------------------------------------------
    /** 
     * An HMAC Signature
     * @class JSUCrypt.signature.HMAC
     * @param {JSUCrypt.hash} hasher  a hasher
     * @see JSUCrypt.hash
     */
    JSUCrypt.signature.HMAC = function(hasher)  {
        this._hasher = hasher;
        this.reset();
    };

    /** 
     * ipad
     * @private
     */
    var ipad = 0x36;
    /** 
     * opad
     * @private
     */
    var opad = 0x5c;

    /**
     * @see JSUCrypt.signature#init
     * @param {JSUCrypt.key.HMACKey} key   secret hmac key
     * @param {number}               mode  Sign or Verify
     */
    JSUCrypt.signature.HMAC.prototype.init = function(key, mode) {
        if ((mode != JSUCrypt.signature.MODE_SIGN) && 
            (mode != JSUCrypt.signature.MODE_VERIFY)){
            throw new JSUCrypt.JSUCryptException("Invalid 'mode' parameter");
        }        
       
        this._key = key;
        this._sig_mode = mode; 
        this.reset();
    };
    
    /**
     * @see JSUCrypt.signature#reset
     * @function
     */
    JSUCrypt.signature.HMAC.prototype.reset  = function() {
        this._hasher.reset();
        if (this._key != undefined) {
            if (this._key.rawKey.length > this._hasher.blockSize) { 
                this._internalKey = this._hasher.finalize(this._key.rawKey);
                this._hasher.reset();
            } else {
                this._internalKey = [].append(this._key.rawKey);
            }
            var blk = [].append(this._internalKey);
            var l = blk.length;
            for (var i = 0; i<l; i++){
                blk[i] = blk[i]^ipad;
            }
            for (; i<this._hasher.blockSize;i++) {
                blk[i] = ipad;
            }
            this._hasher.update(blk);
        }
    }; 

    /**
     * @see JSUCrypt.signature#update
     * @function
     */       
    JSUCrypt.signature.HMAC.prototype.update            = function(data) {
        this._hasher.update(data);
        
    };

    /**
     * @see JSUCrypt.signature#sign
     * @function
     */
    JSUCrypt.signature.HMAC.prototype.sign              = function(data) {
        var h = this._hasher.finalize(data);
        var blk = [].append(this._internalKey);
        var l = blk.length;
        for (var i = 0; i<l; i++){
            blk[i] = blk[i]^opad;
        }
        for (; i<this._hasher.blockSize;i++) {
                blk[i] = opad;
        }
        this._hasher.reset();
        this._hasher.update(blk);
        h = this._hasher.finalize(h);
        this.reset();
        return h;
    };
    /**
     * @see JSUCrypt.signature#verify
     * @function
     */
    JSUCrypt.signature.HMAC.prototype.verify            = function(data, sig) {
        var s = this.sign(data);
        this.reset();
        sig = JSUCrypt.utils.anyToByteArray(sig);
        if (s.length != sig.length) {
            return false;
        }
        for (var i = 0; i<s.length; i++) {
            if (s[i] != sig[i]) {
                return false;
            }
        }
        return true;
    }; 
    



    // --------------------------------------------------------------------------
    //                                   Keys
    // --------------------------------------------------------------------------

    /**
     * HMAC key container.
     *
     * @param {anyBA}  key   key value
     * @class
     */
    JSUCrypt.key.HMACKey = function (key) {
        this.rawKey = JSUCrypt.utils.anyToByteArray(key);
    };


}());