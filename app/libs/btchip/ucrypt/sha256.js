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

JSUCrypt.hash.SHA256 || (function(undefined) {

    // --- SHA256 ---
    /** 
     * An SHA256 hasher
     * @lends  JSUCrypt.hash.SHA256
     * @class 
     */
    var SHA256 = function() {
        this.reset();
    };
    
    /**
     * @see JSUCrypt.hash#reset
     * @function
     */
    SHA256.prototype.reset       = JSUCrypt.hash._reset;
    /**
     * @see JSUCrypt.hash#update
     * @function
     */
     SHA256.prototype.update      = JSUCrypt.hash._update;
    /**
     * @see JSUCrypt.hash#finalize
     * @function
     */
    SHA256.prototype.finalize    = JSUCrypt.hash._finalize;

    SHA256.prototype.length       = 32;
    SHA256.prototype.blockSize    = 64;
    SHA256.prototype.wordSize     = 4;
    SHA256.prototype.PKCS1_OID    = [0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20];
    SHA256.prototype._BE         = true;
    SHA256.prototype._nWords     = 8;
    SHA256.prototype._IV         = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    SHA256.prototype._process    = _doProcess;

    
    // --- SHA224 ---

   /** 
     * An SHA224 hasher
     * @lends  JSUCrypt.hash.SHA224
     * @class 
     */
    var SHA224 = function() {
        this.reset();
    };
   /**
     * @see JSUCrypt.hash#reset
     * @function
     */
    SHA224.prototype.reset        = JSUCrypt.hash._reset;
    /**
     * @see JSUCrypt.hash#update
     * @function
     */
    SHA224.prototype.update       = JSUCrypt.hash._update;
    /**
     * @see JSUCrypt.hash#finalize
     * @function
     */
    SHA224.prototype.finalize     = function(block) {
        return (this._finalize256(block)).slice(0,28);
    };
    SHA224.prototype.length       = 28;
    SHA224.prototype.blockSize    = 64;
    SHA224.prototype.wordSize     = 4;
    SHA224.prototype.PKCS1_OID     = [0x30, 0x2d, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x04, 0x05, 0x00, 0x04, 0x1c];
    SHA224.prototype._BE          = true;
    SHA224.prototype._nWords      = 8;
    SHA224.prototype._IV          = [0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939, 0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4];
    SHA224.prototype._finalize256 = JSUCrypt.hash._finalize;
    SHA224.prototype._process     = _doProcess;


    // --- common ---


    // Constants table
    var primeSqrt = [ 
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ];


    function _doProcess(M) {
        /* M is an of  32bits word, endianness already set */
        
        function rotL(x,n)   { return ((x) << (n)) | ((x) >>> ((32) - (n))); }
        function rotR(x,n)   { return ((x) >>> (n)) | ((x) << ((32) - (n))); }
        function shR(x,n)    { return (x) >>> (n); }
        
        function ch(x,y,z)   { return ((x) & (y)) ^ (~(x) & (z)); }
        function maj(x,y,z)  { return ((x) & (y)) ^ ( (x) & (z)) ^ ((y) & (z)); }
        
        function sum0(x)     { return rotR((x),2)  ^ rotR((x),13)  ^ rotR((x),22); }
        function sum1(x)     { return rotR((x),6)  ^ rotR((x),11)  ^ rotR((x),25); }
        
        function sigma0(x)   { return rotR((x),7)  ^ rotR((x),18)  ^ shR((x),3);  }
        function sigma1(x)   { return rotR((x),17) ^ rotR((x),19)  ^ shR((x),10); }
        
        // Working variables       
        var A, B, C, D, E, F, G, H;
        A =  this._hash[0];
        B =  this._hash[1];
        C =  this._hash[2];
        D =  this._hash[3];
        E =  this._hash[4];
        F =  this._hash[5];
        G =  this._hash[6];
        H =  this._hash[7];
        
        // Computation
        var t1,t2;
        for (var j = 0; j<64; j++) {      
            /* for j in 16 to 63, Mj <- (Sigma_1_256( Mj-2) + Mj-7 + Sigma_0_256(Mj-15) + Mj-16 ). */
            if (j >= 16) {
                M[j & 0xF]  = (sigma1(M[(j-2)  & 0xF]) + 
                               M[(j-7)  & 0xF]         + 
                               sigma0(M[(j-15) & 0xF]) + 
                               M[(j-16) & 0xF])|0;
            }
            
            t1 =  H + sum1(E) + ch(E,F,G) + primeSqrt[j] + M[j&0xF];
            t1 = t1|0;
            t2 = sum0(A) + maj(A,B,C);
            t2 = t2|0;
            H = G ;
            G = F;
            F = E;
            E = (D+t1)|0;
            D = C;
            C = B;
            B = A;
            A = (t1+t2)|0;
        }
        this._hash[0] = (this._hash[0]+A)|0;
        this._hash[1] = (this._hash[1]+B)|0;
        this._hash[2] = (this._hash[2]+C)|0;
        this._hash[3] = (this._hash[3]+D)|0;
        this._hash[4] = (this._hash[4]+E)|0;
        this._hash[5] = (this._hash[5]+F)|0;
        this._hash[6] = (this._hash[6]+G)|0;
        this._hash[7] = (this._hash[7]+H)|0;
    }

    // --- Set it ---
    JSUCrypt.hash.SHA256 = SHA256;
    JSUCrypt.hash.SHA224 = SHA224;
}());
   
