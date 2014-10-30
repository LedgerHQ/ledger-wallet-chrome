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
 * ## ECDH SVDP
 *
 *  ECDH Key Agreement without any KDF, as specified in IEEE p1363-2000
 * 
 * #### Example:
 *        //secp256k1
 *       ecdhdomain =  JSUCrypt.ECFp.getEcDomainByName("secp256k1");
 *       ecdhprivkey = new JSUCrypt.key.EcFpPrivateKey(
 *           256, ecdhdomain, 
 *           "fb26a4e75eec75544c0f44e937dcf5ee6355c7176600b9688c667e5c283b43c5"
 *       );**
 *
 *       ecdhpubkey = new JSUCrypt.key.EcFpPublicKey(
 *           256, ecdhdomain, 
 *           new JSUCrypt.ECFp.AffinePoint("65d5b8bf9ab1801c9f168d4815994ad35f1dcb6ae6c7a1a303966b677b813b00",
 *                                       "e6b865e529b8ecbf71cf966e900477d49ced5846d7662dd2dd11ccd55c0aff7f")
 *       );
 *
 *       //other party public point....
 *       otherpoint = new JSUCrypt.ECFp.AffinePoint("edc8530038d1186b9054acb75aef1419e78ae29b7ee86d42d2dc675504367421",
 *                                                "70b4c38a9eb95587f88c3ca33ae760cc0118dcc453d25c1653a54d920f1debe5",
 *                                                ecdhdomain.curve);
 *       //generate secret
 *       var ecdh = new JSUCrypt.keyagreement.ECDH_SVDP(ecdhprivkey);
 *       var secret = ecdh.generate(otherpoint);
 *
 */
JSUCrypt.keyagreement.ECDH_SVDP  ||  (function (undefined) {

    /**
     * @param {anyBN}           private ECDH key
     * @class
     * @lends  JSUCrypt.keyagreement.ECDH_SVDP
     */
    JSUCrypt.keyagreement.ECDH_SVDP = function (key) {
        if (!(key instanceof JSUCrypt.key.EcFpPrivateKey)){ 
            throw new JSUCrypt.JSUCryptException("Invalid parameter type");
        }
        this.key = key;
    };

    /**
     * Compute a ECDH shared secret according to IEEE p1363 SVDP scheme.
     * No key derivation function (KDF) is performed.
     *
     * @param {AffinePoint|ProjectivePoint} otherPoint  other party public point
     *
     * @return {BigInteger}     shared secret (x ccordinate of computer point)
     */
    JSUCrypt.keyagreement.ECDH_SVDP.prototype.generate = function(otherPoint) {
        if (!(otherPoint instanceof JSUCrypt.ECFp.AffinePoint) &&
            !(otherPoint instanceof JSUCrypt.ECFp.ProjectivePoint)) {
            throw new JSUCrypt.JSUCryptException("Invalid parameter type");
        }
        
        var point = otherPoint.multiply(this.key.d);
        return JSUCrypt.utils.normalizeByteArrayUL(point.x.toByteArray(),this.key.size/8) ;
    };
    
}());
