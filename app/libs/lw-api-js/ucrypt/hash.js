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
 * All hasher support a unified API:
 * 
 *  - void reset()
 *  - void update(data)
 *  - void finalize(data) 
 * 
 * ### Creating hasher
 * 
 * To create an XXX hasher:
 * 
 *   - new JSUCrypt.hash.XXX()
 * 
 * Supported XXX cipher are:
 *  
 *   - HASHNONE
 *   - SHA1
 *   - SHA256
 *   - SHA224
 *   - SHA384
 *   - SHA512
 *   - RIPEMD160
 * 
 * ### Examples
 * 
 * example 1:
 *         
 *         var sha = new JSUCrypt.hash.SHA1();
 *         var h = sha.finalize("616263")
 *         
 * 
 * example 2:
 *         
 *         var sha = new JSUCrypt.hash.SHA1();
 *         sha.upate("61")*
 *         var h =  sha.finalize("6263")
 *         
 * 
 * example 3:
 *         
 *         var sha = new JSUCrypt.hash.SHA1();
 *         sha.upate("60")*
 *         sha.reset();
 *         var h =  sha.finalize("616263")
 *         
 * --------------------------------------------------------------------------
 * @namespace JSUCrypt.hash 
 */
JSUCrypt.hash  || (function (undefined) {

    /**
     * @lends JSUCrypt.hash
     */
    var hash = {
        /** @class JSUCrypt.hash.HASHNONE */
        HASHNONE: undefined,
        /** @class JSUCrypt.hash.SHA1 */
        SHA1: undefined,
        /** @class JSUCrypt.hash.SHA224 */
        SHA224: undefined,
        /** @class JSUCrypt.hash.SHA256 */
        SHA256: undefined,
        /** @class JSUCrypt.hash.SHA384 */
        SHA384: undefined,
        /** @class JSUCrypt.hash.SHA512 */
        SHA512: undefined,
        /** @class JSUCrypt.hash.RIPEMD160 */
        RIPEMD160: undefined,
    };

    /**
     * Reinit hasher as it was just created.
     * The hasher is ready for new computation.
     *
     * @name  JSUCrypt.hash#reset
     * @function
     * @memberof JSUCrypt.hash
     * @abstract
     */
    /**
     * Add more data to the hash
     * @param {anyBA} [block] data to add before ending computation
     *
     * @name  JSUCrypt.hash#update
     * @function
     * @memberof JSUCrypt.hash
     * @abstract
     */
     /**
     * Add more data to hash, terminate computation and return the computed hash
     * @param {anyBA} [block] data to add before ending computation
     * @returns {byte[]} hash
     *
     * @name JSUCrypt.hash#finalize
     * @function
     * @memberof JSUCrypt.hash
     * @abstract
     */

    // --- shortcuts ---
    var UINT64  = JSUCrypt.utils.UINT64;
    var CLONE64  = JSUCrypt.utils.CLONE64;

    // --- Hash Helper ---
    hash._reset = function() {
        if (this.wordSize == 8) {
            this._hash  = [].concat(this._IV.map(CLONE64));
        } else {
            this._hash  = [].concat(this._IV);
        }
        this._block = [];
        this._msglen = 0;
    };


   hash._update = function(block) {
        block  = JSUCrypt.utils.anyToByteArray(block);
        if (block == undefined)  {
            block = [];
        }
        this._block =  this._block.concat(block);        
        if ( this._block.length<this.blockSize) {
            return;
        } 
        do {
            this._msglen += this.blockSize;
            // Build next 32bits block M
            // 16word M15, M14.....M0        
            var M = [];            
            for (var i = 0; i < 16; i++) {
                if (this._BE) {
                    if (this.wordSize == 8) {
                        //64bits
                        M[i] = UINT64( 
                            0xFFFFFFFF&
                                ( (this._block[i*8+0]<<24) |
                                  (this._block[i*8+1]<<16) |
                                  (this._block[i*8+2]<<8)  |
                                  (this._block[i*8+3]<<0)  ),
                            0xFFFFFFFF&
                                ( (this._block[i*8+4]<<24) |
                                  (this._block[i*8+5]<<16) |
                                  (this._block[i*8+6]<<8)  |
                                  (this._block[i*8+7]<<0)  ));
                    } else {
                        //assume 4, aka 32bits
                        M[i] = 0xFFFFFFFF&
                            ( (this._block[i*4+0]<<24) |
                              (this._block[i*4+1]<<16) |
                              (this._block[i*4+2]<<8)  |
                              (this._block[i*4+3]<<0)  );
                    }
                } else {
                    M[i] = 0xFFFFFFFF&
                        ( (this._block[i*4+3]<<24) |
                          (this._block[i*4+2]<<16) |
                          (this._block[i*4+1]<<8)  |
                          (this._block[i*4+0]<<0)  );
                }
            }
            this._block = this._block.slice(this.blockSize);
            //process block 64/128bytes set in 32/64bits array
            this._process(M);
        } while (this._block.length>=64);        
    };

    hash._finalize = function(block) {
        block  = JSUCrypt.utils.anyToByteArray(block);
        if (block == undefined)  {
            block = [];
        }
        
        this.update(block);
        var msglen = this._msglen + this._block.length;
        this._block.push(0x80);
        if ((this.blockSize-this._block.length)< (this.blockSize/8/*8*/)) {
            while (this._block.length<this.blockSize) {
                this._block.push(0);
        }
            this.update([]);
        }
        while (this._block.length<this.blockSize) {
            this._block.push(0);
        }
        
        //pad
        msglen = msglen*8;    
        if (this._BE) {
            this._block[this.blockSize-4] = (msglen>>24) & 0xFF;
            this._block[this.blockSize-3] = (msglen>>16) & 0xFF;
            this._block[this.blockSize-2] = (msglen>>8)  & 0xFF;
            this._block[this.blockSize-1] = (msglen)     & 0xFF;
        } else {
            this._block[64-8] = (msglen)     & 0xFF;
            this._block[64-7] = (msglen>>8)  & 0xFF;
            this._block[64-6] = (msglen>>16) & 0xFF;
            this._block[64-5] = (msglen>>24) & 0xFF;
        }
        //last padded block
        this.update([]);
        
        //build hash array
        var h = [];
        var offset = 0;
        var i;
        if (this._BE) {
            for (i = 0; i < this._nWords; i++) {
                if (this.wordSize == 8) {
                    //64bits
                    h.push( (this._hash[i].h>>24) &0xFF,
                            (this._hash[i].h>>16) &0xFF,
                            (this._hash[i].h>>8)  &0xFF,
                            (this._hash[i].h)      &0xFF );
                    h.push( (this._hash[i].l>>24) &0xFF,
                            (this._hash[i].l>>16) &0xFF,
                            (this._hash[i].l>>8)  &0xFF,
                            (this._hash[i].l)      &0xFF );
                    offset+=8;
                } else {
                    //assume 4, aka 32bits
                    h.push( (this._hash[i]>>24) &0xFF,
                            (this._hash[i]>>16) &0xFF,
                            (this._hash[i]>>8)  &0xFF,
                            (this._hash[i])      &0xFF );
                    offset+=4;
                }
            }
        } else {
            for (i = 0; i < this._nWords; i++) {
                h.push( (this._hash[i])     &0xFF,
                        (this._hash[i]>>8)  &0xFF,
                        (this._hash[i]>>16) &0xFF,
                        (this._hash[i]>>24) &0xFF );
                offset+=4;
            }
        }
        this.reset();
        return h;
    };

    // --- Set it ---
    JSUCrypt.hash = hash;
}());
