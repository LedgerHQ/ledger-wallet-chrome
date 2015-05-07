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

/** 
 * 
 * ## Base definition for Signature.
 *  
 * All Signature support a unified API:
 * 
 *   - void reset()
 *   - void init(key, mode, [IV])
 *   - data sign(data) 
 *   - bool verify(data, sig) 
 * 
 * _key_ is byte array containing the key value.
 * 
 * _mode_ is one of :
 * 
 *  - JSUCrypt.cipher.MODE_SIGN
 *  - JSUCrypt.cipher.MODE_VERIFY
 * 
 * _sign_, return the signature.
 * 
 * _verify_ return true or false, depending on the provided signature has been verified or not.
 *
 * Signature are automatically re-initialized on power up and on final call 
 * with last used key and default empty parameters.
 *
 *
 *
 * ### Creating  signature
 * 
 * 
 * #### AES/DES
 * 
 * to create en DES/AES cipher:
 * 
 *  - new JSUCrypt.signature.[DES|AES](padder, chainMode)
 * 
 * _chainMode_ is one of :
 * 
 *    - JSUCrypt.cipher.MODE_CBC
 *    - JSUCrypt.cipher.MODE_CFB
 * 
 * _padder_ is the padder to use. See above.
 * 
 * #### HMAC
 * 
 *  To create en HMAC signature:
 * 
 *  - new JSUCrypt.signature.HMAC(hasher)
 *
 *   * _hasher_ is a hasher object. 
 *
 * #### ECDSA/RSA
 * 
 * To create en ECDSA/RSA signature:
 * 
 *    - new JSUCrypt.signature.XXX(hasher)
 * 
 * _hasher_ is a hasher object. 
 * 
 * 
 * #### Example
 *         
 *         //create SHA1 hasher
 *         var sha  = new  JSUCrypt.hash.SHA1();
 *         
 *         //create ECFp keys
 *         var pubkey,privkey,domain,ver;
 *         domain =  JSUCrypt.ECFp.getEcDomainByName("secp256k1");
 *         privkey = new JSUCrypt.key.EcFpPrivateKey(
 *             256, domain, 
 *             "f028458b39af92fea938486ecc49562d0e7731b53d9b25e2701183e4f2adc991");
 *         
 *         pubkey = new JSUCrypt.key.EcFpPublicKey(
 *             256, domain, 
 *             new JSUCrypt.ECFp.AffinePoint("81bc1f9486564d3d57a305e8f9067df2a7e1f007d4af4fed085aca139c6b9c7a",
 *                                         "8e3f35e4d7fb27a56a3f35d34c8c2b27cd1d266d5294df131bf3c1cbc39f5a91" ));
 *         
 *         //create signer
 *         var ecsig = new JSUCrypt.signature.ECDSA(sha);
 *         
 *         //sign abc string
 *         ecsig.init(privkey,  JSUCrypt.signature.MODE_SIGN);
 *         sig = ecsig.sign("616263");
 *         
 *         //verify
 *         ecsig.init(pubkey,  JSUCrypt.signature.MODE_VERIFY);
 *         ver = ecsig.verify("616263", sig);
 *         
 * 
 * ------------------------------------------------------------------------------------
 *
 * @namespace JSUCrypt.signature 
 **/
JSUCrypt.signature || (function (undefined) {
    /**
     * @lends  JSUCrypt.signature 
     */
    var sig = {
    };

    /** 
     * Sign mode 
     * @constant
     */
    sig.MODE_SIGN=1;
    /** 
     * Verify mode 
     * @constant
     */
    sig.MODE_VERIFY=2;

    /**  
     * CBC Mode  
     * @constant
     */
    sig.MODE_CBC = 1;
    /**  
     * CFB Mode  **UNTESTED**
     * @constant
     */
    sig.MODE_CFB = 2;


    /** 
     * Init the signature
     * @name JSUCrypt.signature#init
     * @function
     * @memberof  JSUCrypt.signature
     * @abstract
     * @param {key}    key          the key
     * @param {number} mode         MODE_SIGN or MODE_VERIFY 
     * @param {anyBA} [IV]   optional IV
     */       
    /** 
     * Reset the signature
     * @name JSUCrypt.signature#reset
     * @function
     * @memberof  JSUCrypt.signature
     * @abstract
     */
    /** 
     * Push more data into the signature
     * @name JSUCrypt.signature#update
     * @function
     * @memberof  JSUCrypt.signature
     * @abstract
     * @param {anyBA} data chunk to decrypt/encrypt
     */
    /** 
     * Finalize the signature process.
     *
     * After finialization the signature is automaticcaly reset and ready to sign/verify.
     *
     * @name JSUCrypt.signature#sign
     * @function
     * @memberof  JSUCrypt.signature
     * @abstract
     * @param  {anyBA}  data  chunk to encrypt before finalization
     * @return {byte[]}       the signature
     */
    /** 
     * Finalize the signature process and check it
     *
     * After finialization the signature is automaticcaly reset and ready to encrypt/decrypt.
     *
     * @name JSUCrypt.signature#verify
     * @function
     * @memberof  JSUCrypt.signature
     * @abstract
     * @param  {anyBA} data   chunk to encrypt before finalization
     * @param  {anyBA} sig    signature to check
     * @return {boolean}      true or false
     */
    
    

    /* ------- Asymetric helper ------ */
    sig._asymReset = function() {
        this._hash.reset();
    };

    sig._asymUpdate = function(data) {
        try {
            data = JSUCrypt.utils.anyToByteArray(data);
            this._hash.update(data);        
        } catch(e) {
            this.reset();
            throw e;
        }
    };

    sig._asymSign = function(data) {
        try {
            data = JSUCrypt.utils.anyToByteArray(data);
            var h = this._hash.finalize(data);
            var s = this._doSign(h);
            this.reset();
            return s;
        } catch(e) {
            this.reset();
            throw e;
        }
    };

    sig._asymVerify = function(data, sig) {
       try {
           data = JSUCrypt.utils.anyToByteArray(data);
           var h = this._hash.finalize(data);
           var v = this._doVerify(h,sig);
           this.reset();
           return v;
       } catch(e) {
           this.reset();
           throw e;
       }
    };

    /* ------- Symetric helper ------ */
    sig._symReset  = function() {
        if (this._IV) {
            this._block     = [].concat(this._IV);
        } else {
            this._block     = [0,0,0,0,0,0,0,0];
        }
        this._remaining = [];
    };
    
    sig._symUpdate = function(data) {
        try {
            var i;
            data = JSUCrypt.utils.anyToByteArray(data);
            data = this._remaining.concat(data);
            this._remaining = [];
            switch(this._chain_mode) {
                //CBC
            case  JSUCrypt.signature.MODE_CBC:
                while (data.length >= this._blockSize) {
                    //xor
                    for (i = 0; i<8; i++) {
                        this._block[i] ^=  data[i];
                    }
                    data = data.slice(8);
                    //crypt
                    this._block = this._doEncryptBlock(this._block);
                }
                break;
                
                //CFB
            case JSUCrypt.signature.MODE_CFB:
                while (data.length >= this._blockSize) {
                    //crypt
                    this._block = this._doEncryptBlock(this._block);
                    //xor
                    for (i = 0; i<8; i++) {
                        this._block[i] ^=  data[i];
                    }
                    data = data.slice(8);
                }
                break;
                
                //WAT
            default:
                throw new JSUCrypt.JSUCryptException("Invalid 'chain mode' parameter");
            }
            this._remaining = data;
        } catch(e) {
            this.reset();
            throw e;
        }        
    };
    
    sig._symSign = function(data) {
        try {
            data = JSUCrypt.utils.anyToByteArray(data);
            data = this._remaining.concat(data);
            this._remaining = [];
            data = this._padder.pad(data, this._blockSize);
            this.update(data);
            var sig = [].concat(this._block);
            this.reset();
            return sig;
        } catch(e) {
            this.reset();
            throw e;
        }
    };

    sig._symVerify = function(data, sigToCheck) {
        try {
            sigToCheck = JSUCrypt.utils.anyToByteArray(sigToCheck);
            data = JSUCrypt.utils.anyToByteArray(data);
            data = this._remaining.concat(data);
            this._remaining = [];
            this._padder.pad(data, this._blockSize);
            this.update(data);
            var sig = [].concat(this._block);
            this.reset();
            
            if (sigToCheck.length != sig.length) {
                return false;
            }
            for (var i = 0; i<this._block.length; i++) {
                if (sig[i] != sigToCheck[i]) {
                    return false;
                }
        }
            return true;
        } catch(e) {
            this.reset();
            throw e;
        }
    };

    // --- set it ---
    JSUCrypt.signature = sig;
}());



