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

JSUCrypt.hash.SHA512 || (function(undefined) {

    // --- shortcuts ---
    var UINT64   = JSUCrypt.utils.UINT64;
    var CLONE64  = JSUCrypt.utils.CLONE64;
    var ASSIGN64 = JSUCrypt.utils.ASSIGN64;
    var ADD64    = JSUCrypt.utils.ADD64;

    // --- SHA512 ---
    /** 
     * An SHA512 hasher
     * @lends  JSUCrypt.hash.SHA512
     * @class 
     */
    var SHA512 = function() {
        this.reset();
    };
    
    /**
     * @see JSUCrypt.hash#reset
     * @function
     */
    SHA512.prototype.reset       = JSUCrypt.hash._reset;
    /**
     * @see JSUCrypt.hash#update
     * @function
     */
     SHA512.prototype.update      = JSUCrypt.hash._update;
    /**
     * @see JSUCrypt.hash#finalize
     * @function
     */
    SHA512.prototype.finalize    = JSUCrypt.hash._finalize;

    SHA512.prototype.length       = 64;
    SHA512.prototype.blockSize    = 128;
    SHA512.prototype.wordSize     = 8;
    //SHA512.prototype.PKCS1_OID  = [???];
    SHA512.prototype._BE         = true;
    SHA512.prototype._nWords     = 8;
    SHA512.prototype._IV         = [
        UINT64(0x6a09e667, 0xf3bcc908),
        UINT64(0xbb67ae85, 0x84caa73b),
        UINT64(0x3c6ef372, 0xfe94f82b),
        UINT64(0xa54ff53a, 0x5f1d36f1),
        UINT64(0x510e527f, 0xade682d1),
        UINT64(0x9b05688c, 0x2b3e6c1f),
        UINT64(0x1f83d9ab, 0xfb41bd6b),
        UINT64(0x5be0cd19, 0x137e2179),
    ];
    SHA512.prototype._process    = _doProcess;

    
    // --- SHA384 ---

   /** 
     * An SHA384 hasher
     * @lends  JSUCrypt.hash.SHA384
     * @class 
     */
    var SHA384 = function() {
        this.reset();
    };
   /**
     * @see JSUCrypt.hash#reset
     * @function
     */
    SHA384.prototype.reset        = JSUCrypt.hash._reset;
    /**
     * @see JSUCrypt.hash#update
     * @function
     */
    SHA384.prototype.update       = JSUCrypt.hash._update;
    /**
     * @see JSUCrypt.hash#finalize
     * @function
     */
    SHA384.prototype.finalize     = function(block) {
        return (this._finalize512(block)).slice(0,48);
    };

    SHA384.prototype.length       = 48;
    SHA384.prototype.blockSize    = 128;
    SHA384.prototype.wordSize     = 8;
    //SHA384.prototype.PKCS1_OID     = [???];
    SHA384.prototype._BE          = true;
    SHA384.prototype._nWords      = 8;
    SHA384.prototype._IV          = [
        UINT64(0xcbbb9d5d, 0xc1059ed8),
        UINT64(0x629a292a, 0x367cd507),
        UINT64(0x9159015a, 0x3070dd17),
        UINT64(0x152fecd8, 0xf70e5939),
        UINT64(0x67332667, 0xffc00b31),
        UINT64(0x8eb44a87, 0x68581511),
        UINT64(0xdb0c2e0d, 0x64f98fa7),
        UINT64(0x47b5481d, 0xbefa4fa4)
    ];
    SHA384.prototype._finalize512 = JSUCrypt.hash._finalize;
    SHA384.prototype._process     = _doProcess;


    // --- common ---


    // Constants table
    var primeSqrt = [ 
        UINT64(0x428a2f98, 0xd728ae22), UINT64(0x71374491, 0x23ef65cd), UINT64(0xb5c0fbcf, 0xec4d3b2f), UINT64(0xe9b5dba5, 0x8189dbbc), 
        UINT64(0x3956c25b, 0xf348b538), UINT64(0x59f111f1, 0xb605d019), UINT64(0x923f82a4, 0xaf194f9b), UINT64(0xab1c5ed5, 0xda6d8118), 
        UINT64(0xd807aa98, 0xa3030242), UINT64(0x12835b01, 0x45706fbe), UINT64(0x243185be, 0x4ee4b28c), UINT64(0x550c7dc3, 0xd5ffb4e2), 
        UINT64(0x72be5d74, 0xf27b896f), UINT64(0x80deb1fe, 0x3b1696b1), UINT64(0x9bdc06a7, 0x25c71235), UINT64(0xc19bf174, 0xcf692694), 
        UINT64(0xe49b69c1, 0x9ef14ad2), UINT64(0xefbe4786, 0x384f25e3), UINT64(0x0fc19dc6, 0x8b8cd5b5), UINT64(0x240ca1cc, 0x77ac9c65), 
        UINT64(0x2de92c6f, 0x592b0275), UINT64(0x4a7484aa, 0x6ea6e483), UINT64(0x5cb0a9dc, 0xbd41fbd4), UINT64(0x76f988da, 0x831153b5), 
        UINT64(0x983e5152, 0xee66dfab), UINT64(0xa831c66d, 0x2db43210), UINT64(0xb00327c8, 0x98fb213f), UINT64(0xbf597fc7, 0xbeef0ee4), 
        UINT64(0xc6e00bf3, 0x3da88fc2), UINT64(0xd5a79147, 0x930aa725), UINT64(0x06ca6351, 0xe003826f), UINT64(0x14292967, 0x0a0e6e70), 
        UINT64(0x27b70a85, 0x46d22ffc), UINT64(0x2e1b2138, 0x5c26c926), UINT64(0x4d2c6dfc, 0x5ac42aed), UINT64(0x53380d13, 0x9d95b3df), 
        UINT64(0x650a7354, 0x8baf63de), UINT64(0x766a0abb, 0x3c77b2a8), UINT64(0x81c2c92e, 0x47edaee6), UINT64(0x92722c85, 0x1482353b), 
        UINT64(0xa2bfe8a1, 0x4cf10364), UINT64(0xa81a664b, 0xbc423001), UINT64(0xc24b8b70, 0xd0f89791), UINT64(0xc76c51a3, 0x0654be30), 
        UINT64(0xd192e819, 0xd6ef5218), UINT64(0xd6990624, 0x5565a910), UINT64(0xf40e3585, 0x5771202a), UINT64(0x106aa070, 0x32bbd1b8), 
        UINT64(0x19a4c116, 0xb8d2d0c8), UINT64(0x1e376c08, 0x5141ab53), UINT64(0x2748774c, 0xdf8eeb99), UINT64(0x34b0bcb5, 0xe19b48a8), 
        UINT64(0x391c0cb3, 0xc5c95a63), UINT64(0x4ed8aa4a, 0xe3418acb), UINT64(0x5b9cca4f, 0x7763e373), UINT64(0x682e6ff3, 0xd6b2b8a3), 
        UINT64(0x748f82ee, 0x5defb2fc), UINT64(0x78a5636f, 0x43172f60), UINT64(0x84c87814, 0xa1f0ab72), UINT64(0x8cc70208, 0x1a6439ec), 
        UINT64(0x90befffa, 0x23631e28), UINT64(0xa4506ceb, 0xde82bde9), UINT64(0xbef9a3f7, 0xb2c67915), UINT64(0xc67178f2, 0xe372532b), 
        UINT64(0xca273ece, 0xea26619c), UINT64(0xd186b8c7, 0x21c0c207), UINT64(0xeada7dd6, 0xcde0eb1e), UINT64(0xf57d4f7f, 0xee6ed178), 
        UINT64(0x06f067aa, 0x72176fba), UINT64(0x0a637dc5, 0xa2c898a6), UINT64(0x113f9804, 0xbef90dae), UINT64(0x1b710b35, 0x131c471b), 
        UINT64(0x28db77f5, 0x23047d84), UINT64(0x32caab7b, 0x40c72493), UINT64(0x3c9ebe0a, 0x15c9bebc), UINT64(0x431d67c4, 0x9c100d4c), 
        UINT64(0x4cc5d4be, 0xcb3e42b6), UINT64(0x597f299c, 0xfc657e2a), UINT64(0x5fcb6fab, 0x3ad6faec), UINT64(0x6c44198c, 0x4a475817)
    ];


    function _doProcess(M) {
        /* M is an of  64bits word, endianness already set */
        function  rotR64(x,n) {
            var  sl_rot, sh_rot;
            if (n >= 32) {
                sl_rot = x.l;
                x.l = x.h;
                x.h = sl_rot;
                n -= 32;
            } 
            sh_rot = ((((x.h)&0xFFFFFFFF)<<(32-n)))&0xFFFFFFFF;
            sl_rot = ((((x.l)&0xFFFFFFFF)<<(32-n)))&0xFFFFFFFF;
            //rotate
            x.h     = ((x.h >>>n) |sl_rot);
            x.l     = ((x.l >>>n) |sh_rot);
            return x;
        }
        
        function  shR64(x,n){
            var  sl_shr;    
            
            if (n >= 32) {
                x.l = (x.h);
                x.h = 0;
                n -= 32;
            } 
            
            sl_shr = ((((x.h)&0xFFFFFFFF)<<(32-n)))&0xFFFFFFFF;
            x.l = ((x.l)>>>n)|sl_shr;
            x.h = ((x.h)>>>n);
            
            return x;
        }
        
        function sig(x, a, b , c)  {
            var x1,x2,x3;
            
            x1 = CLONE64(x);
            x2 = CLONE64(x);
            x3 = CLONE64(x);
            rotR64(x1,a);
            rotR64(x2,b);
            shR64(x3,c);
            x.l = x1.l ^ x2.l ^ x3.l;
            x.h = x1.h ^ x2.h ^ x3.h;
            
            return x;
        }
        
        function sum(x, a, b , c)  {
            var x1,x2,x3;
            
            x1 = CLONE64(x);
            x2 = CLONE64(x);
            x3 = CLONE64(x);
            rotR64(x1,a);
            rotR64(x2,b);
            rotR64(x3,c);
            x.l = x1.l ^ x2.l ^ x3.l;
            x.h = x1.h ^ x2.h ^ x3.h;        
            
            return x;
        }
        function sigma0(x) { return  sig(x,1,8,7);    }
        function sigma1(x) { return  sig(x,19,61,6);  }
        function sum0(x)   { return  sum(x,28,34,39); }
        function sum1(x)   { return  sum(x,14,18,41); }
        
        // ( ((x) & (y)) ^ (~(x) & (z)) )
        function ch(r, x,y,z) {
            r.l = ((x.l) & (y.l)) ^ (~(x.l) & (z.l)); 
            r.h = ((x.h) & (y.h)) ^ (~(x.h) & (z.h));
            return r;
        }
        //( ((x) & (y)) ^ ( (x) & (z)) ^ ((y) & (z)) )
        function  maj(r, x,y,z)  {
            r.l = ((x.l) & (y.l)) ^ ( (x.l) & (z.l)) ^ ((y.l) & (z.l));
            r.h = ((x.h) & (y.h)) ^ ( (x.h) & (z.h)) ^ ((y.h) & (z.h));
            return r;
        }

        // Working variables       
        var A, B, C, D, E, F, G, H;
        A =  CLONE64(this._hash[0]);
        B =  CLONE64(this._hash[1]);
        C =  CLONE64(this._hash[2]);
        D =  CLONE64(this._hash[3]);
        E =  CLONE64(this._hash[4]);
        F =  CLONE64(this._hash[5]);
        G =  CLONE64(this._hash[6]);
        H =  CLONE64(this._hash[7]);

        // Computation
        var t1,t2,r;
        t1 = UINT64(); 
        t2 = UINT64();
        r  = UINT64();
        for (var j = 0; j<80; j++) {
   
            /* for j in 16 to 80, Xj <- (Sigma_1_512( Xj-2) + Xj-7 + Sigma_0_512(Xj-15) + Xj-16 ). */
            if (j >= 16) {
                //sigma1(M[(j-2)  & 0xF])
                ASSIGN64(t2, M[(j-2) & 0xF]);
                sigma1(t2);
                //+ M[(j-7)  & 0xF]
                ADD64(t2, M[(j-7)  & 0xF]);
                //+ sigma0(M[(j-15) & 0xF]
                ASSIGN64(t1, M[(j-15) & 0xF]);
                sigma0(t1);
                ADD64(t2, t1);
                //+ M[(j-16) & 0xF])
                ADD64(t2, M[(j-16) & 0xF]);
                //assign
                ASSIGN64(M[j&0xF],t2);
            }      
            /// t1 =  H + sum1(E) + ch(E,F,G) + primeSqrt[j] + M[j&0xF];
            //H
            ASSIGN64(t1, H);
            //+sum1(E)
            ASSIGN64(r,E);
            sum1(r);
            ADD64(t1, r);
            //+ch(E,F,G)
            ch(r, E,F,G);
            ADD64(t1,r);
            //+primeSqrt[j]
            ADD64(t1,primeSqrt[j]);
            //+M[j&0xF]
            ADD64(t1,M[j&0xF]);
            
            /// t2 = sum0(A) + maj(A,B,C);
            // sum0(A)
            ASSIGN64(t2,A);
            sum0(t2);
            //+maj(A,B,C);
            maj(r,A,B,C);
            ADD64(t2,r);

            ASSIGN64(H, G) ;
            ASSIGN64(G, F);
            ASSIGN64(F, E);
            ASSIGN64(E, D); ADD64(E, t1);// E = (D+t1)|0;
            ASSIGN64(D, C);
            ASSIGN64(C, B);
            ASSIGN64(B, A);
            ASSIGN64(A,t1);ADD64(A, t2);//A = (t1+t2)|0;
        }

        ADD64(this._hash[0],A);
        ADD64(this._hash[1],B);
        ADD64(this._hash[2],C);
        ADD64(this._hash[3],D);
        ADD64(this._hash[4],E);
        ADD64(this._hash[5],F);
        ADD64(this._hash[6],G);
        ADD64(this._hash[7],H);

    }

    // --- Set it ---
    JSUCrypt.hash.SHA512 = SHA512;
    JSUCrypt.hash.SHA384 = SHA384;
}());
   
