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



JSUCrypt.hash.HASHNONE || (function(undefined) {

    /** 
     * An HASHNONE hasher
     *
     * Just accumulate data and give them back on finalize. 
     * Useful for signing arbitrary data without hashing them.
     *
     * @lends  JSUCrypt.hash.HASHNONE
     * @class 
     */
    var HASHNONE = function() {
        this.reset();
    };

    /**
     * @see JSUCrypt.hash#reset
     * @function
     */
    HASHNONE.prototype.reset        = function() { 
        this._block = []; 
    };
    /**
     * @see JSUCrypt.hash#update
     * @function
     */
    HASHNONE.prototype.update       = function(block) {
        block  = JSUCrypt.utils.anyToByteArray(block);
        if (block == undefined)  {
            block = [];
        }
        this._block =  this._block.concat(block);
    };
    /**
     * @see JSUCrypt.hash#finalize
     * @function
     */
    HASHNONE.prototype.finalize     = function (block) {
        this.update(block);
        var res = this._block;
        this.reset(block);
        return res;
    };

    HASHNONE.prototype.length       = 0;
    HASHNONE.prototype.blockSize    = 1;
    HASHNONE.prototype.wordSize     = 1;
    
    // --- Set it ---
    JSUCrypt.hash.HASHNONE = HASHNONE;
}());
