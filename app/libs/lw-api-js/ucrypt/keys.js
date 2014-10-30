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
 * ## DES
 *
 * TBD
 *
 * ## AES
 *
 * TBD
 *
 * ## RSA
 *
 * TBD
 *
 * ## ECDSA 
 *
 *  ECDSA key can be build explicitly or randomly generated.
 * 
 * Explicit constructor are:
 * 
 *       - EcFpPublicKey(size, domain, point)
 *       - EcFpPublicKey(size, domain, scalar)
 * 
 * where :
 * 
 *   - size is number
 *   - domain is an ECFpDomain as defined above
 *   - point is either a Affine or Jacobian point
 *   - scalar is a big integer
 * 
 *  
 * ---------------------------------------------------------
 * @namespace JSUCrypt.key 
 */

JSUCrypt.key  || (function (undefined) {

    /** 
     * @lends JSUCrypt.key
     */
     var key = {
     };
    
    // --- Set it ---
    JSUCrypt.key = key;

}());
