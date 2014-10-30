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
 * ## Base definition for Cipher
 * 
 * All cipher support a unified API:
 * 
 *  - void reset()
 *  - void init(key,mode, [IV])
 *  - data update(data) 
 *  - data finalize(data) 
 * 
 * 
 * _key_ is byte array containing the key value.
 * 
 * _mode_ is one of :
 * 
 *    - JSUCrypt.cipher.MODE_ENCRYPT
 *    - JSUCrypt.cipher.MODE_DECRYPT
 * 
 * Cipher are automatically re-initialized on power up and on final call 
 * with last used key and default empty parameters.
 *
 *
 * ### Creating  Cipher
 *
 * To create en XXX cipher:
 * 
 *  - new JSUCrypt.cipher.XXX(padder, [chainMode])
 * 
 * _chainMode_ is one of :
 * 
 *    - JSUCrypt.cipher.MODE_ECB
 *    - JSUCrypt.cipher.MODE_CBC
 *    - JSUCrypt.cipher.MODE_CFB
 * 
 * Supported XXX cipher are:
 *  
 *   - DES
 *   - AES
 *   - RSA
 * 
 * #### Example:
 * 
 *         
 *         //create cipher
 *         cipher = new JSUCrypt.cipher.DES(JSUCrypt.padder.None, JSUCrypt.cipher.MODE_CBC);
 * 
 *         //init cipher without IV, aka IV = [0,0,0,0,0,0,0,0]
 *         cipher.init("466431296486ed9c", JSUCrypt.cipher.MODE_ENCRYPT);
 *         ct = cipher.update("506b4e5b8c8fa4db1b95d3e8c5");
 *         ct = ct.concat(cipher.finalize([0xc5, 0xfb, 0x5a]));
 *         
 * 
 * ------------------------------------------------------------------------------------
 * 
 * @namespace JSUCrypt.cipher 
*/
JSUCrypt.cipher || (function (undefined) {

    /**
     * @lends  JSUCrypt.cipher 
     */
    var ciph = {
    };

    /** 
     * Encrypt mode 
     * @constant
     */
    ciph.MODE_ENCRYPT = 1;

    /** 
     * Dencrypt mode  
     * @constant
     */
    ciph.MODE_DECRYPT = 2;

    /**  
     * ECB Mode  
     * @constant
     */
    ciph.MODE_ECB = 1;
    /**  
     * CBC Mode  
     * @constant
     */
    ciph.MODE_CBC = 2;
    /**  
     * CFB Mode  **UNTESTED**
     * @constant
     */
    ciph.MODE_CFB = 3;
    /*
     * OFB Mode  **UNTESTED** **UNIMPLEMENTED**
     * @constant
     */
    ciph.MODE_OFB = 4;    

    /** 
     * Init the cipher
     * @name JSUCrypt.cipher#init
     * @function
     * @memberof  JSUCrypt.cipher
     * @abstract
     * @param {key}    key    the key
     * @param {number} mode   MODE_ENCRYPT or MODE_DECRYPT 
     */       
    /** 
     * Reset the cipher
     * @name JSUCrypt.cipher#reset
     * @function
     * @memberof  JSUCrypt.cipher
     * @abstract
     */    
    /** 
     * Push more data into the cipher
     * @name JSUCrypt.cipher#update
     * @function
     * @memberof  JSUCrypt.cipher
     * @abstract
     * @param  {anyBA}  data chunk to decrypt/encrypt
     * @return {byte[]}      decrypted/encrypted chunk 
     */
    /** 
     * Finalize the ciphering process.
     *
     * After finialization the cipher is automaticcaly reset and ready to encrypt/decrypt.
     *
     * @name JSUCrypt.cipher#finalize
     * @function
     * @memberof  JSUCrypt.cipher
     * @abstract
     * @param  {anyBA}   data   chunk to encrypt before finalization
     * @return {byte[]}         decrypted/encrypted chunk 
     */
    
    /* ------- Asymetric helper ------ */
    ciph._asymReset = function() {
        this._remaining = [];
    };
    ciph._asymUpdate = function(data) {
        data = JSUCrypt.utils.anyToByteArray(data);
        this._remaining = this._remaining.concat(data);
        return [];
    };
    ciph._asymFinalize = function(data) {
        var x;
        data = JSUCrypt.utils.anyToByteArray(data);
        this._remaining.append(data);

        if (this._enc_mode == JSUCrypt.cipher.MODE_ENCRYPT) {
            x = this._doCrypt(this._remaining);
        }
        if (this._enc_mode == JSUCrypt.cipher.MODE_DECRYPT) {
            x = this._doDecrypt(this._remaining);
        }
        this.reset();
        return x;
    };

    /* ------- Symetric helper ------- */
    ciph._symReset  = function() {
        this._block     = [].concat(this._IV);
        this._remaining = [];
    };
    ciph._symUpdate = function(data) {
        return _symUpdFin.call(this, data, false);
    };
    ciph._symFinalize = function(data) {
        return _symUpdFin.call(this, data, true);
    };
    function _symUpdFin(data, last) {
        var x = [];
        var encBlk, decBlk;
        var i;
        try {
            data = JSUCrypt.utils.anyToByteArray(data);
            data = this._remaining.concat(data);
            this._remaining = [];
            
            switch(this._enc_mode) {
                // --- ENC ---
            case JSUCrypt.cipher.MODE_ENCRYPT:
                if (last) {
                    data = this._padder.pad(data, this._blockSize);
                }
                
                switch(this._chain_mode) {
                    //ECB
                case  JSUCrypt.cipher.MODE_ECB:
                    while (data.length >= this._blockSize) {
                        //crypt
                        encBlk = this._doEncryptBlock(data);
                        x.append(encBlk);
                        data = data.slice(this._blockSize);
                    }
                    break;                
                    //CBC
                case  JSUCrypt.cipher.MODE_CBC:
                    while (data.length >= this._blockSize) {
                        //xor
                        for (i = 0; i<this._blockSize; i++) {
                            this._block[i] ^=  data[i];
                        }
                        data = data.slice(this._blockSize);
                        //crypt
                        this._block = this._doEncryptBlock(this._block);
                        x.append(this._block);
                    }
                    break;
                    //CFB
                case JSUCrypt.cipher.MODE_CFB:
                    while (data.length >= this._blockSize) {
                        //crypt
                        this._block = this._doEncryptBlock(this._block);
                        //xor
                        for (i = 0; i<this._blockSize; i++) {
                            this._block[i] ^=  data[i];
                        }
                        //
                        x.append(this._block[i]);
                        //next
                        data = data.slice(this._blockSize);                    
                    }
                    break;
                    //WAT
                default:
                    throw new JSUCrypt.JSUCryptException("Invalid 'chain mode' parameter");
                }
                break;
                
                // --- DEC ---
            case JSUCrypt.cipher.MODE_DECRYPT:
                switch(this._chain_mode) {
                    //ECB
                case  JSUCrypt.cipher.MODE_ECB:
                    while (data.length >= this._blockSize) {
                        //decrypt
                        x.append(this._doDecryptBlock(data));
                        data = data.slice(this._blockSize);
                    }
                    break;
                    //CBC
                case  JSUCrypt.cipher.MODE_CBC:
                    while (data.length >= this._blockSize) {
                        //decrypt
                        decBlk = this._doDecryptBlock(data);
                        //xor and keep
                        for (i = 0; i<this._blockSize; i++) {
                            decBlk[i] ^=  this._block[i];
                        }
                        this._block =  data.slice(0,this._blockSize);
                        //
                        x.append(decBlk);
                        //next
                        data = data.slice(this._blockSize);
                    }                
                    break;
                    //CFB
                case JSUCrypt.cipher.MODE_CFB:
                    while (data.length >= this._blockSize) {
                        //decrypt
                        decBlk = this._doDecryptBlock(this._block);
                        //xor and keep
                        for (i = 0; i<this._blockSize; i++) {
                       decBlk[i] ^= data[i];
                        }
                        this._block =  data.slice(0,this._blockSize);
                        //
                    x.puxh(decBlk);
                        //next
                        data = data.slice(this._blockSize);
                    }
                    break;
                    //WAT
                default:
                    throw new JSUCrypt.JSUCryptException("Invalid 'chain mode' parameter");                
                }
                if (last) {
                    x = this._padder.unpad(x, this._blockSize);
                }
                break;
                
                //WAT
            default:
                throw new JSUCrypt.JSUCryptException("Invalid 'crypt mode' parameter");            
            }
            
            this._remaining = data;
            
            if (last) {
                this.reset();
            }
            return x;        
        } catch (e) {
            this.reset();
            throw e;
        }
    }

    JSUCrypt.cipher = ciph;
}());



