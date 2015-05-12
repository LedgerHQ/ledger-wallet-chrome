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



JSUCrypt.hash.SHA1 || (function(undefined) {

    /** 
     * An SHA1 hasher
     * @lends  JSUCrypt.hash.SHA1
     * @class 
     */
    var SHA1 = function() {
        this.reset();
    };

    /**
     * @see JSUCrypt.hash#reset
     * @function
     */
    SHA1.prototype.reset        = JSUCrypt.hash._reset;
    /**
     * @see JSUCrypt.hash#update
     * @function
     */
    SHA1.prototype.update       = JSUCrypt.hash._update;
    /**
     * @see JSUCrypt.hash#finalize
     * @function
     */
    SHA1.prototype.finalize     = JSUCrypt.hash._finalize;

    SHA1.prototype.length       = 20;
    SHA1.prototype.blockSize    = 64;
    SHA1.prototype.wordSize     = 4;
    SHA1.prototype.PKCS1_OID    = [ 0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14];
    SHA1.prototype._BE          = true;
    SHA1.prototype._nWords      = 5;
    SHA1.prototype._IV          = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0XC3D2E1F0];
    SHA1.prototype._process     = function(M) {
        /* M is an of  32bits word, endianness already set */

        function f(u, v, w)  { return (((u) & (v)) | ((~(u))&(w)));        }
        function g(u, v, w)  { return (((u)&(v)) | ((u)&(w)) | ((v)&(w))); }
        function h(u, v, w)  { return ((u) ^ (v) ^ (w));                   }
        function rotate(x,n) { return (((x)<<(n)) | ((x)>>>(32-(n))));     }
        
        // Working variables       
        var A, B, C, D, E;
        A =  this._hash[0];
        B =  this._hash[1];
        C =  this._hash[2];
        D =  this._hash[3];
        E =  this._hash[4];

        // Computation
        var t;
        for (var j = 0; j<80; j++) {      
            if (j >= 16) {
	        t = (M[(j-3)  & 0xF] ^ 
	             M[(j-8)  & 0xF] ^ 
	             M[(j-14) & 0xF] ^ 
	             M[(j-16) & 0xF]) |0;
	        M[j & 0xF] = rotate(t, 1);
            }
            
            t =  rotate(A,5) + E + M[j & 0xF]; 
            t = t|0;
            if (j <20) {
	        t += f(B,C,D) + 0x5A827999;	  
            } else if (j<40) {
	        t += h(B,C,D) + 0x6ED9EBA1;	
            } else if(j<60) {
	        t += g(B,C,D) + 0x8F1BBCDC;
            } else /*j<80*/ {
	        t += h(B,C,D) + 0xCA62C1D6;
            }
            t = t|0;
            E = D;
            D = C;
            C = rotate(B,30);
            B = A;
            A = t;
        }
        
        this._hash[0] = (this._hash[0]+A)|0;
        this._hash[1] = (this._hash[1]+B)|0;
        this._hash[2] = (this._hash[2]+C)|0;
        this._hash[3] = (this._hash[3]+D)|0;
        this._hash[4] = (this._hash[4]+E)|0;
    };

    
    // --- Set it ---
    JSUCrypt.hash.SHA1 = SHA1;
}());
