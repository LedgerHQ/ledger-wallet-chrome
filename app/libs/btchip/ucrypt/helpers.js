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


/** @namespace JSUCrypt.utils */
JSUCrypt.utils ||  (function (undefined) {

    /** 
     * @lends JSUCrypt.utils
     */
    JSUCrypt.utils = {};

    /** 
     * Convert a string to byte array. 
     *
     * Each value at index 'i' in the created byte array is char code at the character at the same index in the given string.
     *
     * @param {string} str 
     */
    JSUCrypt.utils.strToByteArray = function(str) {
        var b=[];
        var len = str.length;
        for (var i=0; i<len; i++) {
            b[i] = str.charCodeAt(i);
        }
        return b;
    };

    /** 
     * Convert an hex decimal string to byte arrat.
     *
     * Exemple "0A10" will be converted to [10, 16]
     *
     * @param {string} hex string
     */
   JSUCrypt.utils.hexStrToByteArray = function(str) {
        if (str.length & 1 ) {
            str = "0"+str;
        }
        var b=[];
        var len = str.length/2;
        for (var i=0; i<len; i++) {
            b[i] = parseInt(str.substr(2*i,2),16);
        }
        return b;
    };

    /** 
     * Convert a byte array to hex string. 
     *
     * Exemple [10, 16] will be converted to "0A10".
     *
     * @param {byte[]} arr
     */
    JSUCrypt.utils.byteArrayToHexStr = function(arr) {
        var len = arr.length;
        var str = "";
        for (var i = 0; i<len; i++) {
            var x = (arr[i]&0x00FF).toString(16);
            if (x.length&1) {
                str  = str+"0"+x;
            } else {
                str  = str+x;
            }
        }
        return str;
    };

    /** 
     * Convert the given argument to a big Integer.
     *
     * @param {byte[]|hexstring|number} arr
     */
    JSUCrypt.utils.anyToBigInteger = function(any) {
        if (any instanceof BigInteger) {
            return any;
        }
        if (typeof any =="string") {
            return new BigInteger(any,16);
        }
        if (any instanceof Array) {
            return new BigInteger(JSUCrypt.utils.byteArrayToHexStr(any),16);
        }
        if (typeof any=="number") {
            return new BigInteger(any.toStringf(16));
        }
        throw new JSUCrypt.JSUCryptException("Invalid parameter type:"+any);
    };

    /** 
     * Convert the given argument to a byte array.
     *
     * @param {byte[]|hexstring|number} arr
     */
    JSUCrypt.utils.anyToByteArray = function(any) {    
        
        if (any == undefined) {
            return [];
        }
        if (typeof any =="string") {
            return JSUCrypt.utils.hexStrToByteArray(any);
        }
        if (any instanceof Array) {
            return any;
        }
        if (typeof any=="number") {
            return [any&0xFF];
        }
        throw new JSUCrypt.JSUCryptException("Invalid paramerter type:"+any);
    };

    /** 
     * Given a byte array, it removes or adds leading zero to reach the given length.
     * Moreover all byte are masked with 0xFF, to convert all byte to range [0-255]
     * 
     * @param {byte[]} input byte array
     * @param {number} expected length
     */
    JSUCrypt.utils.normalizeByteArrayUL = function(ba,len) {
        if (len == undefined) {
            len = ba.length;
        }
        var a = [];
        for (var i = 0; i< ba.length; i++) {
            a[i] = ba[i]&0xFF;
        }
        if (a.length<len) {
            while (a.length != len) {
                a.unshift(0);
            }
        } else if  (a.length > len) {
            while ((a.length != len) && (a[0] == 0)) {
                a.shift();
            }
        }
        return a;
    };

    /**
     * @private
     */
    JSUCrypt.utils.upper8 = function (x) {
        return (x+7)& (~7); 
    };


    /**
     * @private
     */
    JSUCrypt.utils.UINT64  = function (h,l) {
        if (h == undefined) h = 0;
        if (l == undefined) l = 0;
        return {h:h, l:l};
    };

    /**
     * @private
     */
    JSUCrypt.utils.CLONE64  = function (x) {
        return {h:x.h, l:x.l};
    };

    /**
     * @private
     */
    JSUCrypt.utils.ASSIGN64  = function (x,y) {
        x.h = y.h; x.l = y.l;
        return x;
    };

    /**
     * @private
     */
    JSUCrypt.utils.ADD64  = function (x,y) {
        var carry, addl;

        //option 1
        addl = (x.l+y.l)|0;
        addl = ~addl;
        carry = ((((x.l & y.l) | (x.l & ~y.l & addl) | (~x.l & y.l & addl)) >> 31) & 1);  
        //option 2
        /*
          carry = (x.l&1)&&(y.l&1)?1:0;
          carry = (((x.l>>1)+(y.l>>1)+carry) & 0x80000000)?1:0;   
        */
        x.l = (x.l + y.l);
        x.h = (x.h + y.h);
        if (carry) {
            x.h = (x.h+1);
        }
        x.h = x.h|0;
        x.l = x.l|0;
    };


}());
