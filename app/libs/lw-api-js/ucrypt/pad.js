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
 * A padder is any object provinding the following interface
 *
 *   - pdata pad(data, modLen)
 *   - udata unpad(data, modLen)
 *
 * where:
 * 
 *   - _data_  is the byte array data to pad
 *   - _modLen_, after padding pdata is expected to have length which is a multiple of modLen.
 * 
 * Known padders are:
 * 
 *   - JSUCrypt.padder.None
 *   - JSUCrypt.padder.9797M1
 *   - JSUCrypt.padder.9797M2
 *   - JSUCrypt.padder.PKCS1_V1_5
 *   - JSUCrypt.padder.PKCS5
 * 
 * --------------------------------------------------------------------------
 * @namespace JSUCrypt.padder
 */
JSUCrypt.padder || (function (undefined) {

    /** 
     * Padders
     * @lends  JSUCrypt.padder
     */      
    JSUCrypt.padder = {

        /** 
         * Pad data
         * @name JSUCrypt.padder#pad
         * @function
         * @memberof  JSUCrypt.padder
         * @abstract
         * @param  {anyBA}    data       data to pad
         * @param  {number}   modlen     final lenght of padded data will be a mutiple of modlen
         * @return {byte[]}   padded data
         */       
        /** 
         * Unpad data
         * @name JSUCrypt.padder#unpad
         * @function
         * @memberof  JSUCrypt.padder
         * @abstract
         * @param  {anyBA}    data       data to unpad
         * @param  {number}   modlen     initial length of input padded data shall be a mutiple of modlen
         * @return {byte[]}   unpadded data
         */


        /** None Padder */
        None : {
            pad: function(data, modlen) {
                data = JSUCrypt.utils.anyToByteArray(data);
                if ((data.length % modlen) != 0) {
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'None'");
                }
                data = [].concat(data);
                return data;
            },
            
            unpad: function(data, modlen) {
                data = JSUCrypt.utils.anyToByteArray(data);
                return data;
            }
        },
        
        /** ISO9797 Method 1 Padder */
        ISO9797M1 : {
            pad: function(data, modlen) {
                data = JSUCrypt.utils.anyToByteArray(data);
                data = [].concat(data);
                if ((data.length % modlen) == 0) {
                    return data;
                }
                while(data.length%modlen!=0) {
                    data.push(0);
                }
                return data;
            },
            
            unpad: function(data, modlen) {
                data = JSUCrypt.utils.anyToByteArray(data);
                if ((data.length % modlen) != 0) {
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'ISO9797M1'");
                }
                return [].concat(data);
            }
            
        },

        /** ISO9797 Method 2 Padder */
        ISO9797M2 : {
            pad: function(data, modlen) {
                data = JSUCrypt.utils.anyToByteArray(data);
                data = data.concat(0x80);
                while(data.length%modlen!=0) {
                    data.push(0);
                }
                return data;
            },
            
            unpad: function(data, modlen) {
                var offset;
                data = JSUCrypt.utils.anyToByteArray(data);
                if ((data.length % modlen) != 0) {
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'ISO9797M2'");
                }
                offset = data.length-1;
                while (modlen && (data[offset] == 0)) {
                    offset--;
                }
                if (!modlen) {
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'ISO9797M2'");
                }
                if (data[offset] != 0x80) {
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'ISO9797M2'");
                }
                return data.slice(0, offset);            
            }
            
        },
    
        /** PKCS1 V1.5 Padder */
        PKCS1_V1_5: {
            pad: function(data, len, rnd) {
                data = JSUCrypt.utils.anyToByteArray(data);
                var plen = len - data.length;
                if (plen < 3) {
                    throw new JSUCrypt.JSUCryptException("Cant pad 'PKCS1_V1_5'");
                }
                
                var padded = [0];
                if (rnd) {
                    padded[1] = 2;
                    for (i = 2; i< plen-1; i++) {
                        padded[i] = rand8()&0xff;
                    }
                } else {
                    padded[1] = 1;
                    for (i = 2; i< plen-1; i++) {
                        padded[i] = 0xFF;
                    }             
                }
                padded[plen-1] = 0;
                padded.append(data);
                return padded;
            },
            
            unpad: function(data, modlen, rnd) {
                data = JSUCrypt.utils.anyToByteArray(data);
                modlen = data.length;
                if (data[0] != 0) {
                    print('A'+data[0]);
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'PKCS1_V1_5'");
                }
                var offset;
                if (rnd) {
                    if (data[1] != 2) {
                        print('B');
                        throw new JSUCrypt.JSUCryptException("Cant unpad 'PKCS1_V1_5'");
                    }
                    for (offset = 2; offset< modlen-1; offset++) {
                        if(data[offset] == 0) break;
                    }
                } else {
                    if (data[1] != 1) {
                        throw new JSUCrypt.JSUCryptException("Cant unpad 'PKCS1_V1_5'");
                    }
                    for (offset = 2; offset< modlen-1; offset++) {
                        if ((data[offset] != 0xFF) && (data[offset] != -1)) {
                            break;
                        }
                    }
                }
                if (data[offset] != 0) {
                    print('C');
                    throw new JSUCrypt.JSUCryptException("Cant unpad 'PKCS1_V1_5'");
                }
                offset++;
                return data.slice(offset);
            }
        
        }
    };
    
    function rand8() {
        return Math.floor((Math.random()*255)+1);
    }
    

}());
