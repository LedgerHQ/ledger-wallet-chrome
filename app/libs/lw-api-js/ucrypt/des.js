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


((JSUCrypt.signature && JSUCrypt.signature.DES) && (JSUCrypt.ciper && JSUCrypt.ciper.DES)) || (function (undefined) {

    // --------------------------------------------------------------------------
    //                                   Signature
    // --------------------------------------------------------------------------
    if (JSUCrypt.signature && !JSUCrypt.signature.DES) {
        /** 
         * An DES Signature
         * @class JSUCrypt.signature.DES
         * @param {JSUCrypt.padder} padder       a padder
         * @param {number}        chain_mode   ECB, CBC, ....
         * @see JSUCrypt.cipher
         * @see JSUCrypt.padder
         */
        JSUCrypt.signature.DES = function(padder, chain_mode) {
            if(!padder) {
                padder = JSUCrypt.padder.None;
            }
            this._padder = padder;
            this._chain_mode = chain_mode;
            _setIV.call(this);
            this.reset();
        };
        
        
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#init
         */
        JSUCrypt.signature.DES.prototype.init = function(key, mode, IV) {
            if ((mode != JSUCrypt.signature.MODE_SIGN) && 
                (mode != JSUCrypt.signature.MODE_VERIFY)){
                throw new JSUCrypt.JSUCryptException("Invalid 'mode' parameter");
            }            
            _setKey.call(this, key, EN0);
            _setIV.call(this, IV);
            this._sig_mode = mode; 
            this.reset();
        };
        
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#reset
         * @function
         */
        JSUCrypt.signature.DES.prototype.reset             = JSUCrypt.signature._symReset;
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#update
         * @function
         */       
        JSUCrypt.signature.DES.prototype.update            = JSUCrypt.signature._symUpdate;
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#sign
         * @function
         */
        JSUCrypt.signature.DES.prototype.sign              = JSUCrypt.signature._symSign;
        /**
         * @param {X} X X   
         * @see JSUCrypt.signature#verify
         * @function
         */
        JSUCrypt.signature.DES.prototype.verify            = JSUCrypt.signature._symVerify;

        JSUCrypt.signature.DES.prototype._doEncryptBlock   = _doCrypt;
        JSUCrypt.signature.DES.prototype._blockSize        = 8;
    }

    // --------------------------------------------------------------------------
    //                                   Cipher
    // --------------------------------------------------------------------------
    if (JSUCrypt.cipher && !JSUCrypt.cipher.DES) {
        /** 
         * An DES Cipher
         * @class JSUCrypt.cipher.DES
         * @param {JSUCrypt.padder} padder       a padder
         * @param {number}          chain_mode   ECB, CBC, ....
         * @see JSUCrypt.cipher
         * @see JSUCrypt.padder
         */
        JSUCrypt.cipher.DES = function(padder, chain_mode) {
            if(!padder) {
                padder = JSUCrypt.padder.None;
            }
            this._padder = padder;
            this._chain_mode = chain_mode;
            _setIV.call(this);
            this.reset();
        };
        
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#init
         */
        JSUCrypt.cipher.DES.prototype.init = function(key, mode, IV) {      
            var enc_dec;
            if (mode == JSUCrypt.cipher.MODE_ENCRYPT) {
                enc_dec = EN0;
            } else if (mode == JSUCrypt.cipher.MODE_DECRYPT) {
                enc_dec = DE1;
            } else {
                throw new JSUCrypt.JSUCryptException("Invalid 'mode' parameter");
            }            
            _setKey.call(this, key, enc_dec);
            _setIV.call(this,IV);
            this._enc_mode = mode;
            this.reset();
        };
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#reset
         * @function
         */
        JSUCrypt.cipher.DES.prototype.reset             = JSUCrypt.cipher._symReset;
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#update
         * @function
         */
        JSUCrypt.cipher.DES.prototype.update            = JSUCrypt.cipher._symUpdate;
        /**
         * @param {X} X X   
         * @see JSUCrypt.cipher#finalize
         * @function
         */
        JSUCrypt.cipher.DES.prototype.finalize          = JSUCrypt.cipher._symFinalize;

        JSUCrypt.cipher.DES.prototype._blockSize        = 8;
        JSUCrypt.cipher.DES.prototype._doEncryptBlock   = _doCrypt;
        JSUCrypt.cipher.DES.prototype._doDecryptBlock   = _doCrypt;
    }

    // --------------------------------------------------------------------------
    //                                   Keys
    // --------------------------------------------------------------------------

    /**
     * DES key container.
     *
     * @param {anyBA}  key   key value
     * @class
     */
    JSUCrypt.key.DESKey = function (key) {
        this.rawKey = JSUCrypt.utils.anyToByteArray(key);
    };

    // --------------------------------------------------------------------------
    //                                   ...
    // --------------------------------------------------------------------------
    function _setKey(key, m) {
        var k = key.rawKey;
        if (k.length == 8) {
            deskey.call(this, k, m);
        } else if (k.length == 16) {
            des2key.call(this, k, m);
        } else if (k.length == 24) {
            des3key.call(this, k, m);
        } else {
            throw new JSUCrypt.JSUCryptException("Invalid 'key' parameter");
        }
        this._key = key;
    }

    function _setIV(IV) {
        if (IV) {
            IV = JSUCrypt.utils.anyToByteArray(IV);
            if (IV.length != 8) {
                throw new JSUCrypt.JSUCryptException("Invalid 'IV' parameter");
            }
            this._IV = [].concat(IV);
        } else {
            this._IV = this._IV = [0,0,0,0,0,0,0,0];
        }        
    }

    function _doCrypt(block) {
        if (this._key.rawKey.length == 8) {
            return des.call(this, block);
        } else  {
            return Ddes.call(this, block);
        } 

    }


    // --- Moified R. Outerbridge DES code ---
    
    /*
     * D3DES (V5.09) - 
     *
     * A portable, public domain, version of the Data Encryption Standard.
     *
     * Written with Symantec's THINK (Lightspeed) C by Richard Outerbridge.
     * Thanks to: Dan Hoey for his excellent Initial and Inverse permutation
     * code;  Jim Gillogly & Phil Karn for the DES key schedule code; Dennis
     * Ferguson, Eric Young and Dana How for comparing notes; and Ray Lau,
     * for humouring me on. 
     *
     * Copyright (c) 1988,1989,1990,1991,1992 by Richard Outerbridge.
     * (GEnie : OUTER; CIS : [71755,204]) Graven Imagery, 1992.
     */

    var EN0 = 0;
    var DE1 = 1;

    var bytebit = [
        0200, 0100, 040, 020, 010, 04, 02, 01 
    ];

    var bigbyte = [
        0x800000, 0x400000, 0x200000, 0x100000,
        0x80000,  0x40000,  0x20000,  0x10000,
        0x8000,   0x4000,   0x2000,   0x1000,
        0x800,    0x400,    0x200,    0x100,
        0x80,     0x40,     0x20,     0x10,
        0x8,      0x4,      0x2,      0x1  
    ];


    /* Use the key schedule specified in the Standard (ANSI X3.92-1981). */

    var pc1 = [
        56, 48, 40, 32, 24, 16,  8,   0, 57, 49, 41, 33, 25, 17,
        9,  1, 58, 50, 42, 34, 26,  18, 10,  2, 59, 51, 43, 35,
        62, 54, 46, 38, 30, 22, 14,   6, 61, 53, 45, 37, 29, 21,
        13,  5, 60, 52, 44, 36, 28,  20, 12,  4, 27, 19, 11,  3 
    ];

    var totrot = [
        1,2,4,6,8,10,12,14,15,17,19,21,23,25,27,28 
    ];

    var pc2 = [
        13, 16, 10, 23,  0,  4,   2, 27, 14,  5, 20,  9,
        22, 18, 11,  3, 25,  7,  15,  6, 26, 19, 12,  1,
        40, 51, 30, 36, 46, 54,  29, 39, 50, 44, 32, 47,
        43, 48, 38, 55, 33, 52,  45, 41, 49, 35, 28, 31 
    ];

    var SP1 = [
        0x01010400, 0x00000000, 0x00010000, 0x01010404,
        0x01010004, 0x00010404, 0x00000004, 0x00010000,
        0x00000400, 0x01010400, 0x01010404, 0x00000400,
        0x01000404, 0x01010004, 0x01000000, 0x00000004,
        0x00000404, 0x01000400, 0x01000400, 0x00010400,
        0x00010400, 0x01010000, 0x01010000, 0x01000404,
        0x00010004, 0x01000004, 0x01000004, 0x00010004,
        0x00000000, 0x00000404, 0x00010404, 0x01000000,
        0x00010000, 0x01010404, 0x00000004, 0x01010000,
        0x01010400, 0x01000000, 0x01000000, 0x00000400,
        0x01010004, 0x00010000, 0x00010400, 0x01000004,
        0x00000400, 0x00000004, 0x01000404, 0x00010404,
        0x01010404, 0x00010004, 0x01010000, 0x01000404,
        0x01000004, 0x00000404, 0x00010404, 0x01010400,
        0x00000404, 0x01000400, 0x01000400, 0x00000000,
        0x00010004, 0x00010400, 0x00000000, 0x01010004 
    ];

    var SP2= [
        0x80108020, 0x80008000, 0x00008000, 0x00108020,
        0x00100000, 0x00000020, 0x80100020, 0x80008020,
        0x80000020, 0x80108020, 0x80108000, 0x80000000,
        0x80008000, 0x00100000, 0x00000020, 0x80100020,
        0x00108000, 0x00100020, 0x80008020, 0x00000000,
        0x80000000, 0x00008000, 0x00108020, 0x80100000,
        0x00100020, 0x80000020, 0x00000000, 0x00108000,
        0x00008020, 0x80108000, 0x80100000, 0x00008020,
        0x00000000, 0x00108020, 0x80100020, 0x00100000,
        0x80008020, 0x80100000, 0x80108000, 0x00008000,
        0x80100000, 0x80008000, 0x00000020, 0x80108020,
        0x00108020, 0x00000020, 0x00008000, 0x80000000,
        0x00008020, 0x80108000, 0x00100000, 0x80000020,
        0x00100020, 0x80008020, 0x80000020, 0x00100020,
        0x00108000, 0x00000000, 0x80008000, 0x00008020,
        0x80000000, 0x80100020, 0x80108020, 0x00108000 
    ];
    var  SP3 = [
        0x00000208, 0x08020200, 0x00000000, 0x08020008,
        0x08000200, 0x00000000, 0x00020208, 0x08000200,
        0x00020008, 0x08000008, 0x08000008, 0x00020000,
        0x08020208, 0x00020008, 0x08020000, 0x00000208,
        0x08000000, 0x00000008, 0x08020200, 0x00000200,
        0x00020200, 0x08020000, 0x08020008, 0x00020208,
        0x08000208, 0x00020200, 0x00020000, 0x08000208,
        0x00000008, 0x08020208, 0x00000200, 0x08000000,
        0x08020200, 0x08000000, 0x00020008, 0x00000208,
        0x00020000, 0x08020200, 0x08000200, 0x00000000,
        0x00000200, 0x00020008, 0x08020208, 0x08000200,
        0x08000008, 0x00000200, 0x00000000, 0x08020008,
        0x08000208, 0x00020000, 0x08000000, 0x08020208,
        0x00000008, 0x00020208, 0x00020200, 0x08000008,
        0x08020000, 0x08000208, 0x00000208, 0x08020000,
        0x00020208, 0x00000008, 0x08020008, 0x00020200 
    ];

    var SP4 = [
        0x00802001, 0x00002081, 0x00002081, 0x00000080,
        0x00802080, 0x00800081, 0x00800001, 0x00002001,
        0x00000000, 0x00802000, 0x00802000, 0x00802081,
        0x00000081, 0x00000000, 0x00800080, 0x00800001,
        0x00000001, 0x00002000, 0x00800000, 0x00802001,
        0x00000080, 0x00800000, 0x00002001, 0x00002080,
        0x00800081, 0x00000001, 0x00002080, 0x00800080,
        0x00002000, 0x00802080, 0x00802081, 0x00000081,
        0x00800080, 0x00800001, 0x00802000, 0x00802081,
        0x00000081, 0x00000000, 0x00000000, 0x00802000,
        0x00002080, 0x00800080, 0x00800081, 0x00000001,
        0x00802001, 0x00002081, 0x00002081, 0x00000080,
        0x00802081, 0x00000081, 0x00000001, 0x00002000,
        0x00800001, 0x00002001, 0x00802080, 0x00800081,
        0x00002001, 0x00002080, 0x00800000, 0x00802001,
        0x00000080, 0x00800000, 0x00002000, 0x00802080 
    ];

    var SP5 = [
        0x00000100, 0x02080100, 0x02080000, 0x42000100,
        0x00080000, 0x00000100, 0x40000000, 0x02080000,
        0x40080100, 0x00080000, 0x02000100, 0x40080100,
        0x42000100, 0x42080000, 0x00080100, 0x40000000,
        0x02000000, 0x40080000, 0x40080000, 0x00000000,
        0x40000100, 0x42080100, 0x42080100, 0x02000100,
        0x42080000, 0x40000100, 0x00000000, 0x42000000,
        0x02080100, 0x02000000, 0x42000000, 0x00080100,
        0x00080000, 0x42000100, 0x00000100, 0x02000000,
        0x40000000, 0x02080000, 0x42000100, 0x40080100,
        0x02000100, 0x40000000, 0x42080000, 0x02080100,
        0x40080100, 0x00000100, 0x02000000, 0x42080000,
        0x42080100, 0x00080100, 0x42000000, 0x42080100,
        0x02080000, 0x00000000, 0x40080000, 0x42000000,
        0x00080100, 0x02000100, 0x40000100, 0x00080000,
        0x00000000, 0x40080000, 0x02080100, 0x40000100 
    ];

    var SP6 = [
        0x20000010, 0x20400000, 0x00004000, 0x20404010,
        0x20400000, 0x00000010, 0x20404010, 0x00400000,
        0x20004000, 0x00404010, 0x00400000, 0x20000010,
        0x00400010, 0x20004000, 0x20000000, 0x00004010,
        0x00000000, 0x00400010, 0x20004010, 0x00004000,
        0x00404000, 0x20004010, 0x00000010, 0x20400010,
        0x20400010, 0x00000000, 0x00404010, 0x20404000,
        0x00004010, 0x00404000, 0x20404000, 0x20000000,
        0x20004000, 0x00000010, 0x20400010, 0x00404000,
        0x20404010, 0x00400000, 0x00004010, 0x20000010,
        0x00400000, 0x20004000, 0x20000000, 0x00004010,
        0x20000010, 0x20404010, 0x00404000, 0x20400000,
        0x00404010, 0x20404000, 0x00000000, 0x20400010,
        0x00000010, 0x00004000, 0x20400000, 0x00404010,
        0x00004000, 0x00400010, 0x20004010, 0x00000000,
        0x20404000, 0x20000000, 0x00400010, 0x20004010 
    ];

    var SP7 =[
        0x00200000, 0x04200002, 0x04000802, 0x00000000,
        0x00000800, 0x04000802, 0x00200802, 0x04200800,
        0x04200802, 0x00200000, 0x00000000, 0x04000002,
        0x00000002, 0x04000000, 0x04200002, 0x00000802,
        0x04000800, 0x00200802, 0x00200002, 0x04000800,
        0x04000002, 0x04200000, 0x04200800, 0x00200002,
        0x04200000, 0x00000800, 0x00000802, 0x04200802,
        0x00200800, 0x00000002, 0x04000000, 0x00200800,
        0x04000000, 0x00200800, 0x00200000, 0x04000802,
        0x04000802, 0x04200002, 0x04200002, 0x00000002,
        0x00200002, 0x04000000, 0x04000800, 0x00200000,
        0x04200800, 0x00000802, 0x00200802, 0x04200800,
        0x00000802, 0x04000002, 0x04200802, 0x04200000,
        0x00200800, 0x00000000, 0x00000002, 0x04200802,
        0x00000000, 0x00200802, 0x04200000, 0x00000800,
        0x04000002, 0x04000800, 0x00000800, 0x00200002 
    ];

    var SP8 = [
        0x10001040, 0x00001000, 0x00040000, 0x10041040,
        0x10000000, 0x10001040, 0x00000040, 0x10000000,
        0x00040040, 0x10040000, 0x10041040, 0x00041000,
        0x10041000, 0x00041040, 0x00001000, 0x00000040,
        0x10040000, 0x10000040, 0x10001000, 0x00001040,
        0x00041000, 0x00040040, 0x10040040, 0x10041000,
        0x00001040, 0x00000000, 0x00000000, 0x10040040,
        0x10000040, 0x10001000, 0x00041040, 0x00040000,
        0x00041040, 0x00040000, 0x10041000, 0x00001000,
        0x00000040, 0x10040040, 0x00001000, 0x00041040,
        0x10001000, 0x00000040, 0x10000040, 0x10040000,
        0x10040040, 0x10000000, 0x00040000, 0x10001040,
        0x00000000, 0x10041040, 0x00040040, 0x10000040,
        0x10040000, 0x10001000, 0x10001040, 0x00000000,
        0x10041040, 0x00041000, 0x00041000, 0x00001040,
        0x00001040, 0x00040040, 0x10000000, 0x10041000 
    ];


    function   scrunch(outof) {
        var into = [];
        into[0]   = (outof[0] & 0xff) << 24;
        into[0]  |= (outof[1] & 0xff) << 16;
        into[0]  |= (outof[2] & 0xff) << 8;
        into[0]  |= (outof[3] & 0xff);
        into[1]   = (outof[4] & 0xff) << 24;
        into[1]  |= (outof[5] & 0xff) << 16;
        into[1]  |= (outof[6] & 0xff) << 8;
        into[1]  |= (outof[7]   & 0xff);
        return into;
    }

    function unscrun(outof) {
        var into = [];
        into[0] = (outof[0] >>> 24) & 0xff;
        into[1] = (outof[0] >>> 16) & 0xff;
        into[2] = (outof[0] >>>  8) & 0xff;
        into[3] =  outof[0]         & 0xff;
        into[4] = (outof[1] >>> 24) & 0xff;
        into[5] = (outof[1] >>> 16) & 0xff;
        into[6] = (outof[1] >>>  8) & 0xff;
        into[7] =  outof[1]         & 0xff;
        return into;
    }

    // --------------------------------------------------------------------------
    // -
    // --------------------------------------------------------------------------
    function desfunc(block, keys) {
        var  fval, work, right, left;
        var  round;
        
        left = block[0];
        right = block[1];
        work = ((left >>> 4) ^ right) & 0x0f0f0f0f;
        right ^= work;
        left ^= (work << 4);
        work = ((left >>> 16) ^ right) & 0x0000ffff;
        right ^= work;
        left ^= (work << 16);
        work = ((right >>> 2) ^ left) & 0x33333333;
        left ^= work;
        right ^= (work << 2);
        work = ((right >>> 8) ^ left) & 0x00ff00ff;
        left ^= work;
        right ^= (work << 8);
        right = ((right << 1) | ((right >>> 31) & 1)) & 0xffffffff;
        work = (left ^ right) & 0xaaaaaaaa;
        left ^= work;
        right ^= work;
        left = ((left << 1) | ((left >>> 31) & 1)) & 0xffffffff;
        
        var idx =0;
        for( round = 0; round < 8; round++ ) {
            work  = (right << 28) | (right >>> 4);
            work ^= keys[idx++];
            fval  = SP7[ work     & 0x3f];
            fval |= SP5[(work >>>  8) & 0x3f];
            fval |= SP3[(work >>> 16) & 0x3f];
            fval |= SP1[(work >>> 24) & 0x3f];
            work  = right ^ keys[idx++];
            fval |= SP8[ work     & 0x3f];
            fval |= SP6[(work >>>  8) & 0x3f];
            fval |= SP4[(work >>> 16) & 0x3f];
            fval |= SP2[(work >>> 24) & 0x3f];
            left ^= fval;
            work  = (left << 28) | (left >>> 4);
            work ^= keys[idx++];
            fval  = SP7[ work     & 0x3f];
            fval |= SP5[(work >>>  8) & 0x3f];
            fval |= SP3[(work >>> 16) & 0x3f];
            fval |= SP1[(work >>> 24) & 0x3f];
            work  = left ^ keys[idx++];
            fval |= SP8[ work     & 0x3f];
            fval |= SP6[(work >>>  8) & 0x3f];
            fval |= SP4[(work >>> 16) & 0x3f];
            fval |= SP2[(work >>> 24) & 0x3f];
            right ^= fval;
        }
        
        right = (right << 31) | (right >>> 1);
        work = (left ^ right) & 0xaaaaaaaa;
        left ^= work;
        right ^= work;
        left = (left << 31) | (left >>> 1);
        work = ((left >>> 8) ^ right) & 0x00ff00ff;
        right ^= work;
        left ^= (work << 8);
        work = ((left >>> 2) ^ right) & 0x33333333;
        right ^= work;
        left ^= (work << 2);
        work = ((right >>> 16) ^ left) & 0x0000ffff;
        left ^= work;
        right ^= (work << 16);
        work = ((right >>> 4) ^ left) & 0x0f0f0f0f;
        left ^= work;
        right ^= (work << 4);
        return [right, left];
    }

    // --------------------------------------------------------------------------
    // -
    // --------------------------------------------------------------------------
    function  deskeycomp(key,  edf) {  
        var kn_i;
        var raw0_i;
        var  i, j, l, m, n;
        var  pc1m = [];
        var  pcr = [];
        var rounds_key = [];

        for ( j = 0; j < 56; j++ ) {
            l = pc1[j];
            m = l & 07;
            pc1m[j] = (key[l >> 3] & bytebit[m]) ? 1 : 0;
        }
        for( i = 0; i < 16; i++ ) {
            if( edf == DE1 ) {
                m = (15 - i) << 1;
            } else {
                m = i << 1;
            }
            n = m + 1;
            rounds_key[m] = rounds_key[n] = 0;
            for( j = 0; j < 28; j++ ) {
                l = j + totrot[i];
                if( l < 28 ) {
                    pcr[j] = pc1m[l];
                } else {                
                    pcr[j] = pc1m[l - 28];
                }
            }
            for( j = 28; j < 56; j++ ) {
                l = j + totrot[i];
                if( l < 56 ) {
                    pcr[j] = pc1m[l];
                } else {
                    pcr[j] = pc1m[l - 28];
                }
            }
            for( j = 0; j < 24; j++ ) {
                if( pcr[pc2[j]] ) {
                    rounds_key[m] |= bigbyte[j];
                }
                if( pcr[pc2[j+24]] ) {
                    rounds_key[n] |= bigbyte[j];
                }
            }
        }
        
        for( i = 0; i < 16; i++ ) {   
            raw0_i = rounds_key[2*i];
            kn_i   = rounds_key[2*i+1];
            
            rounds_key[2*i]   = (raw0_i & 0x00fc0000) << 6;
            rounds_key[2*i]  |= (raw0_i & 0x00000fc0) << 10;
            rounds_key[2*i]  |= (kn_i & 0x00fc0000) >> 10;
            rounds_key[2*i]  |= (kn_i & 0x00000fc0) >> 6;
            
            rounds_key[2*i+1]   = (raw0_i & 0x0003f000) << 12;
            rounds_key[2*i+1]  |= (raw0_i & 0x0000003f) << 16;
            rounds_key[2*i+1]  |= (kn_i & 0x0003f000) >> 4;
            rounds_key[2*i+1]  |= (kn_i & 0x0000003f);
            
        }
        return rounds_key;
    }



    function  deskey(key,  edf) {  
        this._KnL = deskeycomp(key, edf);
        this._KnR = undefined;
        this._Kn3 = undefined;
    }

    function  des2key(hexkey, edf) {

        var i;
        if( edf == EN0 ) {
            this._KnL = deskeycomp(hexkey.slice(0,8),  EN0);
            this._KnR = deskeycomp(hexkey.slice(8,16),  DE1);
        } else {
            this._KnL = deskeycomp(hexkey.slice(0,8),  DE1);
            this._KnR = deskeycomp(hexkey.slice(8,16),  EN0);
        }
        this._Kn3 = [];
        for (i = 0; i<32; i++) {
            this._Kn3[i] = this._KnL[i];     /* Kn3 = KnL */
        }
    }
   

    function des3key(hexkey, edf) {   
        if( edf == EN0 ) {
            this._KnL = deskeycomp(hexkey.slice(0,8),  EN0);
            this._KnR = deskeycomp(hexkey.slice(8,16),  DE1);
            this._Kn3 = deskeycomp(hexkey.slice(16,24), EN0);
        } else {
            this._KnL = deskeycomp(hexkey.slice(16,24), DE1);
            this._KnR = deskeycomp(hexkey.slice(8,16),  EN0);
            this._Kn3 = deskeycomp(hexkey.slice(0,8),  DE1);    
        } 
    }

    function des(inblock) {
        var  blk;    
        blk = scrunch(inblock);
        blk = desfunc(blk, this._KnL);
        blk = unscrun(blk);
        return blk;
    }

    function Ddes(inblock) {
        var  blk;    
        blk = scrunch(inblock);
        blk = desfunc(blk, this._KnL);
        blk = desfunc(blk, this._KnR);
        blk = desfunc(blk, this._Kn3);
        blk = unscrun(blk);
        return blk ;
    }
    // --- ENDOF: Moified R. Outerbridge DES code ---


    /// --- Set it    
   

}());
