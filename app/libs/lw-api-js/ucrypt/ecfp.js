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
 * Elliptic Curver over Fp is used for ECDSA. The _JSUCrypt.ECFp_ provide APIs to deals with curves, point and keys over Fp.
 * The _JSUCrypt.ECFp_ deals with curve of the form y³ = a.x²+b.x+c over Fp.
 * 
 * 
 * ## Curve
 * 
 * Curve can created with the constructor  JSUCrypt.ECFp.EcFpCurve(a,b,p),
 * where a,b,p are big-number defining the curve parameter 
 * 
 * 
 * ## Domain
 * 
 * Curve domain is the 4-tuple (curve, generator, order co-factor).
 * 
 * Domain can be either explicitly build or retrieved from the well known domain set. 
 * 
 * The well known domain list is given by _JSUCrypt.ECFp.curveNames_ and specific domain can be
 * retrieved with the _JSUCrypt.ECFp.getEcDomainByName_ function.
 * 
 *         
 *         domain =  JSUCrypt.ECFp.getEcDomainByName("secp256k1");
 *         
 * 
 * Domain specification details can is available in _JSUCrypt.ECFp.curveSpecs_
 * 
 *        
 *         domainSpec =  JSUCrypt.ECFp.curveSpec("secp256k1");
 *         
 * 
 * For building your own domain, use the JSUCrypt.ECFp.ECFpDomain(curve, G,order,cofactor) constructor.
 * 
 * 
 * ## Point on curve
 * 
 * JSUCrypt.ECFp provide both Affine and Projective point :
 * 
 *   - JSUCrypt.ECFp.AffinPoint
 *   - JSUCrypt.ECFp.ProjectivePoint
 * 
 * Note: Jacobian point will be added later.
 * 
 * Point are created with point constructor:
 *    - new JSUCrypt.ECFp.AffinPoint(x,y,curve)      
 *    - new JSUCrypt.ECFp.ProjectivePoint(x,y,z,curve)      
 * 
 * 
 * Both Affine and Projective point provide the following APis:
 * 
 *     - AffinePoint   toAffine()    
 *     - ProjectPoint  toProjective()
 *     - Point         multiply(k)
 *     - Point         add(point)
 *     - bool          isInfinityPoint()
 * 
 * _multiply_ and _add_ return the same kind of point as "this". +
 * _add_ accept both Affine and Projective point.
 * 
 *
 * --------------------------------------------------------------------------
 *
 *@namespace JSUCrypt.ECFp 
 */

JSUCrypt.ECFp ||  (function (undefined) {

    /** 
     * @lends JSUCrypt.ECFp
     */
    var ecfp = {};

    // --------------------------------------------------------------------------
    //                                    Curves
    // --------------------------------------------------------------------------
    

    /**
     * List of wellknown curve. This name can be used with "getEcDomainByName"
     */
    ecfp.curveNames = [
        "secp256k1",
        "secp256r1",
        "secp224k1",
        "secp224r1",
        "secp192k1",
        "secp192r1",
        "secp160k1",
        "secp160r2",
        "secp160r1",
        "brainpoolp256r1",
        "brainpoolp256t1",
        "brainpoolp224r1",
        "brainpoolp224t1",
        "brainpoolp192r1",
        "brainpoolp192t1",
        "brainpoolp160r1",
        "brainpoolp160t1",
        "P_256",
        "P_224",
        "P_192",
    ];
    
    /**
     * Well know Elliptic Curce Domain over Fp specification. 
     * Each domain is associative object defining:
     *
     *   - a,b,p : the weierstrass parameter of y² = x³+ax+b
     *   - Gx,Gy : the affine coordinate of the G base point.
     *   - n     : the order of G
     *   - h     : the cofactor of n
     *   - size  : the bit size of p
     *   - name  : the curve domain name
     * 
     */
    ecfp.curveDomainSpecs = {
        /** secp256k1 */
        secp256k1: {
            name:  "secp256k1",
            size:  256,
            a:     "000",
            b:     "007",
            p:     "00fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
            Gx:    "0079be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
            Gy:    "00483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8",
            n:     "00fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
            h:     "001"
        },
        /** secp256r1*/
        secp256r1: {
            name:  "secp256r1",
            size:  256,
            a:     "00ffffffff00000001000000000000000000000000fffffffffffffffffffffffc",
            b:     "005ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b",
            p:     "00ffffffff00000001000000000000000000000000ffffffffffffffffffffffff",
            Gx:    "006b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
            Gy:    "004fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5",
            n:     "00ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551",
            h:     "001"
        },
        /** secp224k1*/
        secp224k1: {
            name:  "secp224k1",
            size:  224,
            a:     "000",
            b:     "005",
            p:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFE56D",
            Gx:    "00A1455B334DF099DF30FC28A169A467E9E47075A90F7E650EB6B7A45C",
            Gy:    "007E089FED7FBA344282CAFBD6F7E319F7C0B0BD59E2CA4BDB556D61A5",
            n:     "010000000000000000000000000001DCE8D2EC6184CAF0A971769FB1F7",
            h:     "001"
        },
        /** secp224r1 */
        secp224r1: {
            name:  "secp224r1",
            size:  224,
            a:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE",
            b:     "00B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4",
            p:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001",
            Gx:    "00B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21 ",
            Gy:    "00BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34",
            n:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D",
            h:     "001"
        },
        /** secp192k1*/
        secp192k1: {
            name:  "secp192k1",
            size:  192,
            a:     "000",
            b:     "003",
            p:     "00fffffffffffffffffffffffffffffffffffffffeffffee37",
            Gx:    "00db4ff10ec057e9ae26b07d0280b7f4341da5d1b1eae06c7d",
            Gy:    "009b2f2f6d9c5628a7844163d015be86344082aa88d95e2f9d",
            n:     "00fffffffffffffffffffffffe26f2fc170f69466a74defd8d",
            h:     "001"
        },
        /** secp192r1 */
        secp192r1: {
            name:  "secp192r1",
            size:  256,
            a:     "00fffffffffffffffffffffffffffffffefffffffffffffffc",
            b:     "0064210519e59c80e70fa7e9ab72243049feb8deecc146b9b1",
            p:     "00fffffffffffffffffffffffffffffffeffffffffffffffff",
            Gx:    "00188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012",
            Gy:    "007192b95ffc8da78631011ed6b24cdd573f977a11e794811",
            n:     "00ffffffffffffffffffffffff99def836146bc9b1b4d22831",
            h:     "001"
        },
        /** secp160k1 */
        secp160k1: {
            name:  "secp160k1",
            size:  160,
            a:     "000",
            b:     "007",
            p:     "00fffffffffffffffffffffffffffffffeffffac73",
            Gx:    "003b4c382ce37aa192a4019e763036f4f5dd4d7ebb",
            Gy:    "00938cf935318fdced6bc28286531733c3f03c4fee",
            n:     "00100000000000000000001b8fa16dfab9aca16b6b3",
            h:     "001"
        },
        /** secp160r1*/
        secp160r1: {
            name:  "secp160r1",
            size:  160,
            a:     "00ffffffffffffffffffffffffffffffff7ffffffc",
            b:     "001c97befc54bd7a8b65acf89f81d4d4adc565fa45",
            p:     "00ffffffffffffffffffffffffffffffff7fffffff",
            Gx:    "004a96b5688ef573284664698968c38bb913cbfc82",
            Gy:    "0023a628553168947d59dcc912042351377ac5fb32",
            n:     "00100000000000000000001f4c8f927aed3ca752257",
            h:     "001"
        },
        /** secp160r2*/
        secp160r2: {
            name:  "secp160r2",
            size:  160,
            a:     "00fffffffffffffffffffffffffffffffeffffac70",
            b:     "00b4e134d3fb59eb8bab57274904664d5af50388ba",
            p:     "00fffffffffffffffffffffffffffffffeffffac73",
            Gx:    "0052dcb034293a117e1f4ff11b30f7199d3144ce6d",
            Gy:    "00feaffef2e331f296e071fa0df9982cfea7d43f2e",
            n:     "00100000000000000000000351ee786a818f3a1a16b",
            h:     "001"
        },

        /** brainpoolp256r1*/
        brainpoolp256r1: {
            name:  "brainpoolp256r1",
            size:  256,
            a:     "007d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9",
            b:     "0026dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b6",
            p:     "00a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377",
            Gx:    "008bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262",
            Gy:    "00547ef835c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f046997",
            n:     "00a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7",
            h:     "001"
        },
        /** brainpoolp224r1*/
        brainpoolp224r1: {
            name:  "brainpoolp224r1",
            size:  224,
            a:     "0068A5E62CA9CE6C1C299803A6C1530B514E182AD8B0042A59CAD29F43",
            b:     "002580F63CCFE44138870713B1A92369E33E2135D266DBB372386C400B",
            p:     "00D7C134AA264366862A18302575D1D787B09F075797DA89F57EC8C0FF",
            Gx:    "000D9029AD2C7E5CF4340823B2A87DC68C9E4CE3174C1E6EFDEE12C07D",
            Gy:    "0058AA56F772C0726F24C6B89E4ECDAC24354B9E99CAA3F6D3761402CD",
            n:     "00D7C134AA264366862A18302575D0FB98D116BC4B6DDEBCA3A5A7939F",
            h:     "001"
        },
        /** brainpoolp192r1*/
        brainpoolp192r1: {
            name:  "brainpoolp192r1",
            size:  192,
            a:     "006a91174076b1e0e19c39c031fe8685c1cae040e5c69a28ef",
            b:     "00469a28ef7c28cca3dc721d044f4496bcca7ef4146fbf25c9",
            p:     "00c302f41d932a36cda7a3463093d18db78fce476de1a86297",
            Gx:    "00c0a0647eaab6a48753b033c56cb0f0900a2f5c4853375fd6",
            Gy:    "0014b690866abd5bb88b5f4828c1490002e6773fa2fa299b8f",
            n:     "00c302f41d932a36cda7a3462f9e9e916b5be8f1029ac4acc1",
            h:     "001"
        },
        /** brainpoolp256t1*/
        brainpoolp256t1: {
            name:  "brainpoolp256t1",
            size:  256,
            a:     "00a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5374",
            b:     "00662c61c430d84ea4fe66a7733d0b76b7bf93ebc4af2f49256ae58101fee92b04",
            p:     "00a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377",
            Gx:    "00a3e8eb3cc1cfe7b7732213b23a656149afa142c47aafbc2b79a191562e1305f4",
            Gy:    "002d996c823439c56d7f7b22e14644417e69bcb6de39d027001dabe8f35b25c9be",
            n:     "00a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7",
            h:     "001"
        },
        /** brainpoolp224t1*/
        brainpoolp192t1: {
            name:  "brainpoolp224t1",
            size:  192,
            a:     "00D7C134AA264366862A18302575D1D787B09F075797DA89F57EC8C0FC",
            b:     "004B337D934104CD7BEF271BF60CED1ED20DA14C08B3BB64F18A60888D",
            p:     "002DF271E14427A346910CF7A2E6CFA7B3F484E5C2CCE1C8B730E28B3F",
            Gx:    "006AB1E344CE25FF3896424E7FFE14762ECB49F8928AC0C76029B4D580",
            Gy:    "000374E9F5143E568CD23F3F4D7C0D4B1E41C8CC0D1C6ABD5F1A46DB4C",
            n:     "00D7C134AA264366862A18302575D0FB98D116BC4B6DDEBCA3A5A7939F",
            h:     "001"
        },
        /** brainpoolp192t1*/
        brainpoolp192t1: {
            name:  "brainpoolp192t1",
            size:  192,
            a:     "00c302f41d932a36cda7a3463093d18db78fce476de1a86294",
            b:     "0013d56ffaec78681e68f9deb43b35bec2fb68542e27897b79",
            p:     "00c302f41d932a36cda7a3463093d18db78fce476de1a86297",
            Gx:    "003ae9e58c82f63c30282e1fe7bbf43fa72c446af6f4618129",
            Gy:    "0097e2c5667c2223a902ab5ca449d0084b7e5b3de7ccc01c9",
            n:     "00c302f41d932a36cda7a3462f9e9e916b5be8f1029ac4acc1",
            h:     "001"
        },
        /** brainpoolp160r1*/
        brainpoolp160r1: {
            name:  "brainpoolp160r1",
            size:  160,
            a:     "00340e7be2a280eb74e2be61bada745d97e8f7c300",
            b:     "001e589a8595423412134faa2dbdec95c8d8675e58",
            p:     "00e95e4a5f737059dc60dfc7ad95b3d8139515620f",
            Gx:    "00bed5af16ea3f6a4f62938c4631eb5af7bdbcdbc3",
            Gy:    "001667cb477a1a8ec338f94741669c976316da6321",
            n:     "00e95e4a5f737059dc60df5991d45029409e60fc09",
            h:     "001"
        },
        /** brainpoolp160t1*/
        brainpoolp160t1: {
            name:  "brainpoolp160t1",
            size:  160,
            a:     "00e95e4a5f737059dc60dfc7ad95b3d8139515620c",
            b:     "007a556b6dae535b7b51ed2c4d7daa7a0b5c55f380",
            p:     "00e95e4a5f737059dc60dfc7ad95b3d8139515620f",
            Gx:    "00b199b13b9b34efc1397e64baeb05acc265ff2378",
            Gy:    "00add6718b7c7c1961f0991b842443772152c9e0ad",
            n:     "00e95e4a5f737059dc60df5991d45029409e60fc09",
            h:     "001"
        },

        /** P_256*/
        P_256: {
            name:  "P_256",
            size:  256,
            a:     "00ffffffff00000001000000000000000000000000fffffffffffffffffffffffc",
            b:     "005ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b",
            p:     "00ffffffff00000001000000000000000000000000ffffffffffffffffffffffff",
            Gx:    "006b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
            Gy:    "004fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5",
            n:     "00ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551",
            h:     "001"
        },
        /** P_224*/
        P_224: {
            name:  "P_224",
            size:  224,
            a:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFE",
            b:     "00B4050A850C04B3ABF54132565044B0B7D7BFD8BA270B39432355FFB4",
            p:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000001",
            Gx:    "00B70E0CBD6BB4BF7F321390B94A03C1D356C21122343280D6115C1D21 ",
            Gy:    "00BD376388B5F723FB4C22DFE6CD4375A05A07476444D5819985007E34",
            n:     "00FFFFFFFFFFFFFFFFFFFFFFFFFFFF16A2E0B8F03E13DD29455C5C2A3D",
            h:     "001"
        },
        /** P_192*/
        P_192: {
            name:  "P_192",
            size:  192,
            a:     "00fffffffffffffffffffffffffffffffefffffffffffffffc",
            b:     "0064210519e59c80e70fa7e9ab72243049feb8deecc146b9b1",
            p:     "00fffffffffffffffffffffffffffffffeffffffffffffffff",
            Gx:    "00188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012",
            Gy:    "0007192b95ffc8da78631011ed6b24cdd573f977a11e794811",
            n:     "00ffffffffffffffffffffffff99def836146bc9b1b4d22831",
            h:     "001"
        },
    };
    
    /**
     * class container for a,b,p.
     *
     * @param {anyBN} a
     * @param {anyBN} b
     * @param {anyBN} p
     *
     * @public
     * @class
     */
    ecfp.EcFpCurve = function(a,b,field) {
            this.a        = JSUCrypt.utils.anyToBigInteger(a);
            this.b        = JSUCrypt.utils.anyToBigInteger(b);
            this.field    = JSUCrypt.utils.anyToBigInteger(field);
    };
    
    /**
     * class container for a,b,p.
     *
     * @param {JSUCrypt.ECFp.EcFpCurve}     curve
     * @param {JSUCrypt.ECFp.AffinePoint}   G
     * @param {anyBN}           order
     * @param {anyBN}           cofactor
     *
     * @public
     * @class
     */
    ecfp.EcFpDomain = function(curve, G,order,cofactor) {
        if ((!(curve instanceof ecfp.EcFpCurve)) ||
            (!(G instanceof ecfp.AffinePoint))) {
            throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
        }
        /** {EcFpCurve} curve */
        this.curve    = curve;
        /** {AFfinePoint} curve */
        this.G        = G;
        /** {BigInteger} order */
        this.order    = JSUCrypt.utils.anyToBigInteger(order);
        /** {BigInteger} cofactor */
        this.cofactor = JSUCrypt.utils.anyToBigInteger(cofactor);    
    };
    
    /**
     * Build the EcFpDomain correpondig to the specification.
     *
     * @param {JSUCrypt.ECFp.curveDomainSpecs} spec curve domain specification
     * @see  JSUCrypt.ECFp.EcFpDomain
     */
    ecfp.getEcDomainBySpec = function(spec) {
        if (!spec) {
            throw new JSUCrypt.JSUCryptException("Invalid undefined domain specification");
        }
        var curve = new ecfp.EcFpCurve( new BigInteger(spec.a,16),
                                        new BigInteger(spec.b,16),
                                        new BigInteger(spec.p,16));
        var point = new ecfp.AffinePoint(new BigInteger(spec.Gx,16),
                                    new BigInteger(spec.Gy,16),
                                    curve);
        return new ecfp.EcFpDomain(curve,
                              point,
                              new BigInteger(spec.n,16),
                              new BigInteger(spec.h,16));
    };
    
    /**
     * Build the EcFpDomain correpondig to the given name.
     *
     * @param {string} name   curve name
     * @see  JSUCrypt.ECFp.curveNames
     */
    ecfp.getEcDomainByName = function (name) {        
        return  ecfp.getEcDomainBySpec(ecfp.curveDomainSpecs[name]);
    };


    // --------------------------------------------------------------------------
    //                                    Affine Point
    // --------------------------------------------------------------------------
    
    /**
     * An Affine point
     *
     * @param {anyBN}         x
     * @param {anyBN}         y
     * @param {JSUCrypt.ECFp.EcFpCurve}     curve
     *
     * @class
     */
    ecfp.AffinePoint = function (x, y, curve) {
        if ((curve != undefined) &&
            !(curve instanceof ecfp.EcFpCurve)) {
            throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
        }
        
        /**
         * x coordinate.
         * @public
         * @property {BigInteger} x
         */
        this.x = JSUCrypt.utils.anyToBigInteger(x);
        /**
         * y coordinate.
         * @property {BigInteger} y
         */
        this.y = JSUCrypt.utils.anyToBigInteger(y);

        this._curve = curve;
        
        /**
         * Convert this Affine point to a new Homogenous Projective point.
         * me
         */
        this.toProjective = function() {
            return new ecfp.ProjectivePoint(this.x, this.y, BigInteger.ONE, this._curve);
        };

        /**
         * Identity cboversion
         */
        this.toAffine = function() {
            return affine;
        };
        
        /**
         * Multiply this point by the given scalar
         * Return a new affin point.
         *
         * @param {anyBN} k scalar
         */
        this.multiply = function(k) {
            k = JSUCrypt.utils.anyToBigInteger(k);
            var    kproj = this.toProjective();
            kproj = kproj.multiply(k);
            return kproj.toAffine();
        };
        
        /**
         * Return a new AffinePoint which is the sum of this and the given parameter.
         * This method assume that the 'curve' properties  of each point is defined
         *
         * @param {JSUCrypt.ECFp.AffinePoint|JSUCrypt.ECFp.ProjectivePoint} point  the point to add
         */
        this.add = function(point) {
            var thisProj    = this.toProjective();
            point    = point.toProjective();
            if (!(point instanceof ecfp.ProjectivePoint)) {
                throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
            }
            thisProj = thisProj.add(point);
            return thisProj.toAffine();
        };

        /**
         * Return the compressed form of this point: [04 x y].
         *
         * @return  {byte[]} uncompressed point form
         */
        this.getUncompressedForm = function() {
            if (this._curve == undefined) {
                throw new JSUCrypt.JSUCryptException("Curve not set");
            }
            var l = JSUCrypt.utils.upper8(this._curve.field.bitLength);
            var compressed = [];
            compressed.append([4]);
            compressed.append(JSUCrypt.utils.normalizeByteArrayUL(this.x.toByteArray(), l));
            compressed.append(JSUCrypt.utils.normalizeByteArrayUL(this.y.toByteArray(), l));
            return compressed;
        };
        
        

    };

    // --------------------------------------------------------------------------
    //                                 Projective Point
    // --------------------------------------------------------------------------
    
    /**
     * 
     * @param {anyBN}           x
     * @param {anyBN}           y
     * @param {JSUCrypt.ECFp.EcFpCurve}     curve
     *
     * @class
     */
    ecfp.ProjectivePoint = function(x,y,z,curve) {
        if ((curve != undefined) &&
            !(curve instanceof ecfp.EcFpCurve)) {
            throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
        }
        
        /**
         * x coordinate.
         * @property {BigInteger} 
         */
        this.x      = JSUCrypt.utils.anyToBigInteger(x);
        /**
         * y coordinate.
         * @property {BigInteger} 
         */
        this.y      = JSUCrypt.utils.anyToBigInteger(y);
        /**
         * z coordinate.
         * @property {BigInteger} 
         */
        this.z      = JSUCrypt.utils.anyToBigInteger(z);

        this._curve = curve;

        // --- Projective Point ---
        
        /**
         * @param {JSUCrypt.ECFp.AffinePoint|JSUCrypt.ECFp.ProjectivePoint} point to add to this
         */
        this.add  = function(point) {
            /*
             *  U1 = X1*Z2
             *  U2 = X2*Z1
             *  S1 = Y1*Z2
             *  S2 = Y2*Z1
             *  ZZ = Z1*Z2
             *  T = U1+U2
             *  TT = T^2
             *  M = S1+S2
             *  R = TT-U1*U2+a*ZZ^2
             *  F = ZZ*M
             *  L = M*F
             *  LL = L2
             *  G = (T+L)2-TT-LL
             *  W = 2*R2-G
             *  X3 = 2*F*W
             *  Y3 = R*(G-2*W)-2*LL
             *  Z3 = 4*F*F^2
             */
            point    = point.toProjective();
            if (!(point instanceof ecfp.ProjectivePoint)) {
                throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
            }
            var p = this._curve.field;
            
            //infinity as input?
            if (this.isInfinityPoint()) {
                return new ecfp.ProjectivePoint(point.x,point.y, point.z, this._curve);
            }
            if (point.isInfinityPoint()) {
                return new ecfp.ProjectivePoint(this.x,this.y, this.z, this._curve);
            }
            
            //go on
            var U1 = this.x.multiply(point.z).mod(p);
            var U2 = point.x.multiply(this.z).mod(p);
            var S1 = this.y.multiply(point.z).mod(p);
            var S2 = point.y.multiply(this.z).mod(p);
            
            if (U1.equals(U2) &&  !S1.equals(S2)) {
                return new  ecfp.ProjectivePoint(BigInteger.ZERO,BigInteger.ONE, BigInteger.ZERO, this._curve);
            }
            
            
            var ZZ = this.z.multiply(point.z).mod(p);
            var T  = U1.add(U2).mod(p);
            var TT = T.multiply(T).mod(p);
            var M  = S1.add(S2).mod(p);
            var R1 = U1.multiply(U2).mod(p);
            var R2 = this._curve.a.multiply(ZZ).multiply(ZZ).mod(p);
            var R  = TT.subtract(R1).add(R2).mod(p);
            var F  = ZZ.multiply(M).mod(p);
            var L  = M.multiply(F).mod(p);
            var LL = L.multiply(L).mod(p);
            var G  = T.add(L).mod(p);       G  = G.multiply(G).mod(p);         G = G.subtract(TT).subtract(LL).mod(p);
            var W  = R.multiply(R).mod(p);  W  = W.add(W).subtract(G).mod(p);
            var X3 = F.multiply(W).mod(p);  X3 = X3.add(X3).mod(p);
            var t  = LL.add(LL).mod(p);
            var Y3 = W.add(W).mod(p);       Y3 = G.subtract(Y3).mod(p);        Y3 = R.multiply(Y3).mod(p);                 Y3 = Y3.subtract(t).mod(p);
            var Z3 = F.multiply(F).mod(p);  Z3 = Z3.multiply(F).mod(p);        Z3 = (Z3.add(Z3).add(Z3).add(Z3)).mod(p);
            
            return new ecfp.ProjectivePoint(X3,Y3,Z3, this._curve);
        };
        
        /**
         * Multiply this point by the given scalar. 
         * Return a new projective point.
         * 
         * @param {anyBN} scalar
         */
        this.multiply= function(k) {
            k = JSUCrypt.utils.anyToBigInteger(k);
            var R0 = this;
            var R1 = this;
            var nbbit = k.bitLength()-1;
            while(nbbit-- != 0) {
                R0 = R0.add(R0);
                if (k.testBit(nbbit)) {
                    R0 = R0.add(R1);
                }
            }
            return R0;
        };

        /**
         * Convert this Homogenous Projective point to a new point Affine point.
         * me
         */
        this.toAffine = function() {
            var p = this._curve.field;
            var zinv = this.z.modInverse(p);
            var X = this.x.multiply(zinv).mod(p);
            var Y = this.y.multiply(zinv).mod(p);
            return new ecfp.AffinePoint(X,Y,this._curve);
        };

        /**
         * Identity cboversion
         */
        this.toProjective = function() {
            return this;
        };
        
        /** Tell if this point is Infinity or not */
        this.isInfinityPoint = function() {
            return this.z.equals(BigInteger.ZERO);
        };

        /**
         * Return the uncompressed form of this point: [04 x y].
         *
         * @return  {byte[]} uncompressed point form
         */
        this.getUncompressedForm = function() {
            return this.toAffine().getUncompressedForm();
        };
    };


    // --- Set it ---
    JSUCrypt.ECFp = ecfp;


    // --------------------------------------------------------------------------
    //                                   Keys
    // --------------------------------------------------------------------------

    /**
     * Public EC key container.
     *
     * @param {number}      size     key size in bits 
     * @param {JSUCrypt.ECFp.EcFpDomain}  domain   curve Domain
     * @param {JSUCrypt.ECFp.AffinePoint} W        public key W
     * @class
     */
     JSUCrypt.key.EcFpPublicKey = function (size, domain, point) {
         if (!(domain instanceof JSUCrypt.ECFp.EcFpDomain)) {
             throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
         }

         /**
          * key size in biits
          * @property {number} 
          */
         this.size     = size;
         /**
          * domain  
          * @property {JSUCrypt.ECFp.EcFpDomain} 
          */
         this.domain   = domain;
         
         if (point) {
             /**
              * Public key value 
              * @property {JSUCrypt.ECFp.AffinePoint} public point
              */
             this.W        = new JSUCrypt.ECFp.AffinePoint(point.x, point.y, domain.curve);
        }
     };
    
    /**
     * Private EC key container.
     *
     * @param {number}      size     key size in bits 
     * @param {JSUCrypt.ECFp.EcFpDomain}  domain   curve Domain
     * @param {anyBN}       scalar   private key scalar
     * @class
     */
     JSUCrypt.key.EcFpPrivateKey = function(size,domain, scalar) {
        if (!(domain instanceof JSUCrypt.ECFp.EcFpDomain)) {
            throw new JSUCrypt.JSUCryptException("Invalid paramerter type");
        }
        /**
          * key size in bits
          * @property {number} 
          */
         this.size   = size;
         /**
          * domain  
          * @property JSUCrypt.ECFp.{EcFpDomain} 
          */
         this.domain = domain;
         
         if (scalar) {
             /**
              * Private key value 
              * @property {number} private scalar
              */
             this.d      = JSUCrypt.utils.anyToBigInteger(scalar);
         }
    };

    /**
     * Generate EC Key pair.
     * @params {number}                   size     key size in bits
     * @param {JSUCrypt.ECFp.EcFpDomain}  domain   curve Domain
     * @param {anyBN}                     priv     private key (optional)
     */
    JSUCrypt.key.generateECFpPair = function(size, domain, priv) {        
        size = size/8;
        //gen priv scalar
        var scal;
        if (priv == undefined) {
            scal = [];
            for (var i = 0; i<size; i++) {
                scal[i] = (Math.floor(Math.random()*255));
            }
            scal = JSUCrypt.utils.anyToBigInteger(scal);
        } else {
            scal = JSUCrypt.utils.anyToBigInteger(priv);
        }
        scal = scal.mod(domain.order);

        //gen public point
        var W = domain.G.multiply(scal);

        //build and give pair 
        return [new JSUCrypt.key.EcFpPublicKey(size, domain, W),
                new JSUCrypt.key.EcFpPrivateKey(size, domain, scal)];
    };


}());


