! function(e) {
  if ("object" == typeof exports && "undefined" != typeof module) module.exports = e();
  else if ("function" == typeof define && define.amd) define([], e);
  else {
    var f;
    "undefined" != typeof window ? f = window : "undefined" != typeof global ? f = global : "undefined" != typeof self && (f = self), f.bitcoin = e()
  }
}(function() {
  var define, module, exports;
  return function e(t, n, r) {
    function s(o, u) {
      if (!n[o]) {
        if (!t[o]) {
          var a = typeof require == "function" && require;
          if (!u && a) return a(o, !0);
          if (i) return i(o, !0);
          var f = new Error("Cannot find module '" + o + "'");
          throw f.code = "MODULE_NOT_FOUND", f
        }
        var l = n[o] = {
          exports: {}
        };
        t[o][0].call(l.exports, function(e) {
          var n = t[o][1][e];
          return s(n ? n : e)
        }, l, l.exports, e, t, n, r)
      }
      return n[o].exports
    }
    var i = typeof require == "function" && require;
    for (var o = 0; o < r.length; o++) s(r[o]);
    return s
  }({
    1: [function(require, module, exports) {
      function BigInteger(a, b, c) {
        if (!(this instanceof BigInteger)) return new BigInteger(a, b, c);
        if (a != null) {
          if ("number" == typeof a) this.fromNumber(a, b, c);
          else if (b == null && "string" != typeof a) this.fromString(a, 256);
          else this.fromString(a, b)
        }
      }
      var proto = BigInteger.prototype;
      proto.__bigi = require("../package.json").version;
      BigInteger.isBigInteger = function(obj, check_ver) {
        return obj && obj.__bigi && (!check_ver || obj.__bigi === proto.__bigi)
      };
      var dbits;

      function am1(i, x, w, j, c, n) {
        while (--n >= 0) {
          var v = x * this[i++] + w[j] + c;
          c = Math.floor(v / 67108864);
          w[j++] = v & 67108863
        }
        return c
      }

      function am2(i, x, w, j, c, n) {
        var xl = x & 32767,
            xh = x >> 15;
        while (--n >= 0) {
          var l = this[i] & 32767;
          var h = this[i++] >> 15;
          var m = xh * l + h * xl;
          l = xl * l + ((m & 32767) << 15) + w[j] + (c & 1073741823);
          c = (l >>> 30) + (m >>> 15) + xh * h + (c >>> 30);
          w[j++] = l & 1073741823
        }
        return c
      }

      function am3(i, x, w, j, c, n) {
        var xl = x & 16383,
            xh = x >> 14;
        while (--n >= 0) {
          var l = this[i] & 16383;
          var h = this[i++] >> 14;
          var m = xh * l + h * xl;
          l = xl * l + ((m & 16383) << 14) + w[j] + c;
          c = (l >> 28) + (m >> 14) + xh * h;
          w[j++] = l & 268435455
        }
        return c
      }
      BigInteger.prototype.am = am1;
      dbits = 26;
      BigInteger.prototype.DB = dbits;
      BigInteger.prototype.DM = (1 << dbits) - 1;
      var DV = BigInteger.prototype.DV = 1 << dbits;
      var BI_FP = 52;
      BigInteger.prototype.FV = Math.pow(2, BI_FP);
      BigInteger.prototype.F1 = BI_FP - dbits;
      BigInteger.prototype.F2 = 2 * dbits - BI_FP;
      var BI_RM = "0123456789abcdefghijklmnopqrstuvwxyz";
      var BI_RC = new Array;
      var rr, vv;
      rr = "0".charCodeAt(0);
      for (vv = 0; vv <= 9; ++vv) BI_RC[rr++] = vv;
      rr = "a".charCodeAt(0);
      for (vv = 10; vv < 36; ++vv) BI_RC[rr++] = vv;
      rr = "A".charCodeAt(0);
      for (vv = 10; vv < 36; ++vv) BI_RC[rr++] = vv;

      function int2char(n) {
        return BI_RM.charAt(n)
      }

      function intAt(s, i) {
        var c = BI_RC[s.charCodeAt(i)];
        return c == null ? -1 : c
      }

      function bnpCopyTo(r) {
        for (var i = this.t - 1; i >= 0; --i) r[i] = this[i];
        r.t = this.t;
        r.s = this.s
      }

      function bnpFromInt(x) {
        this.t = 1;
        this.s = x < 0 ? -1 : 0;
        if (x > 0) this[0] = x;
        else if (x < -1) this[0] = x + DV;
        else this.t = 0
      }

      function nbv(i) {
        var r = new BigInteger;
        r.fromInt(i);
        return r
      }

      function bnpFromString(s, b) {
        var self = this;
        var k;
        if (b == 16) k = 4;
        else if (b == 8) k = 3;
        else if (b == 256) k = 8;
        else if (b == 2) k = 1;
        else if (b == 32) k = 5;
        else if (b == 4) k = 2;
        else {
          self.fromRadix(s, b);
          return
        }
        self.t = 0;
        self.s = 0;
        var i = s.length,
            mi = false,
            sh = 0;
        while (--i >= 0) {
          var x = k == 8 ? s[i] & 255 : intAt(s, i);
          if (x < 0) {
            if (s.charAt(i) == "-") mi = true;
            continue
          }
          mi = false;
          if (sh == 0) self[self.t++] = x;
          else if (sh + k > self.DB) {
            self[self.t - 1] |= (x & (1 << self.DB - sh) - 1) << sh;
            self[self.t++] = x >> self.DB - sh
          } else self[self.t - 1] |= x << sh;
          sh += k;
          if (sh >= self.DB) sh -= self.DB
        }
        if (k == 8 && (s[0] & 128) != 0) {
          self.s = -1;
          if (sh > 0) self[self.t - 1] |= (1 << self.DB - sh) - 1 << sh
        }
        self.clamp();
        if (mi) BigInteger.ZERO.subTo(self, self)
      }

      function bnpClamp() {
        var c = this.s & this.DM;
        while (this.t > 0 && this[this.t - 1] == c) --this.t
      }

      function bnToString(b) {
        var self = this;
        if (self.s < 0) return "-" + self.negate().toString(b);
        var k;
        if (b == 16) k = 4;
        else if (b == 8) k = 3;
        else if (b == 2) k = 1;
        else if (b == 32) k = 5;
        else if (b == 4) k = 2;
        else return self.toRadix(b);
        var km = (1 << k) - 1,
            d, m = false,
            r = "",
            i = self.t;
        var p = self.DB - i * self.DB % k;
        if (i-- > 0) {
          if (p < self.DB && (d = self[i] >> p) > 0) {
            m = true;
            r = int2char(d)
          }
          while (i >= 0) {
            if (p < k) {
              d = (self[i] & (1 << p) - 1) << k - p;
              d |= self[--i] >> (p += self.DB - k)
            } else {
              d = self[i] >> (p -= k) & km;
              if (p <= 0) {
                p += self.DB;
                --i
              }
            }
            if (d > 0) m = true;
            if (m) r += int2char(d)
          }
        }
        return m ? r : "0"
      }

      function bnNegate() {
        var r = new BigInteger;
        BigInteger.ZERO.subTo(this, r);
        return r
      }

      function bnAbs() {
        return this.s < 0 ? this.negate() : this
      }

      function bnCompareTo(a) {
        var r = this.s - a.s;
        if (r != 0) return r;
        var i = this.t;
        r = i - a.t;
        if (r != 0) return this.s < 0 ? -r : r;
        while (--i >= 0)
          if ((r = this[i] - a[i]) != 0) return r;
        return 0
      }

      function nbits(x) {
        var r = 1,
            t;
        if ((t = x >>> 16) != 0) {
          x = t;
          r += 16
        }
        if ((t = x >> 8) != 0) {
          x = t;
          r += 8
        }
        if ((t = x >> 4) != 0) {
          x = t;
          r += 4
        }
        if ((t = x >> 2) != 0) {
          x = t;
          r += 2
        }
        if ((t = x >> 1) != 0) {
          x = t;
          r += 1
        }
        return r
      }

      function bnBitLength() {
        if (this.t <= 0) return 0;
        return this.DB * (this.t - 1) + nbits(this[this.t - 1] ^ this.s & this.DM)
      }

      function bnByteLength() {
        return this.bitLength() >> 3
      }

      function bnpDLShiftTo(n, r) {
        var i;
        for (i = this.t - 1; i >= 0; --i) r[i + n] = this[i];
        for (i = n - 1; i >= 0; --i) r[i] = 0;
        r.t = this.t + n;
        r.s = this.s
      }

      function bnpDRShiftTo(n, r) {
        for (var i = n; i < this.t; ++i) r[i - n] = this[i];
        r.t = Math.max(this.t - n, 0);
        r.s = this.s
      }

      function bnpLShiftTo(n, r) {
        var self = this;
        var bs = n % self.DB;
        var cbs = self.DB - bs;
        var bm = (1 << cbs) - 1;
        var ds = Math.floor(n / self.DB),
            c = self.s << bs & self.DM,
            i;
        for (i = self.t - 1; i >= 0; --i) {
          r[i + ds + 1] = self[i] >> cbs | c;
          c = (self[i] & bm) << bs
        }
        for (i = ds - 1; i >= 0; --i) r[i] = 0;
        r[ds] = c;
        r.t = self.t + ds + 1;
        r.s = self.s;
        r.clamp()
      }

      function bnpRShiftTo(n, r) {
        var self = this;
        r.s = self.s;
        var ds = Math.floor(n / self.DB);
        if (ds >= self.t) {
          r.t = 0;
          return
        }
        var bs = n % self.DB;
        var cbs = self.DB - bs;
        var bm = (1 << bs) - 1;
        r[0] = self[ds] >> bs;
        for (var i = ds + 1; i < self.t; ++i) {
          r[i - ds - 1] |= (self[i] & bm) << cbs;
          r[i - ds] = self[i] >> bs
        }
        if (bs > 0) r[self.t - ds - 1] |= (self.s & bm) << cbs;
        r.t = self.t - ds;
        r.clamp()
      }

      function bnpSubTo(a, r) {
        var self = this;
        var i = 0,
            c = 0,
            m = Math.min(a.t, self.t);
        while (i < m) {
          c += self[i] - a[i];
          r[i++] = c & self.DM;
          c >>= self.DB
        }
        if (a.t < self.t) {
          c -= a.s;
          while (i < self.t) {
            c += self[i];
            r[i++] = c & self.DM;
            c >>= self.DB
          }
          c += self.s
        } else {
          c += self.s;
          while (i < a.t) {
            c -= a[i];
            r[i++] = c & self.DM;
            c >>= self.DB
          }
          c -= a.s
        }
        r.s = c < 0 ? -1 : 0;
        if (c < -1) r[i++] = self.DV + c;
        else if (c > 0) r[i++] = c;
        r.t = i;
        r.clamp()
      }

      function bnpMultiplyTo(a, r) {
        var x = this.abs(),
            y = a.abs();
        var i = x.t;
        r.t = i + y.t;
        while (--i >= 0) r[i] = 0;
        for (i = 0; i < y.t; ++i) r[i + x.t] = x.am(0, y[i], r, i, 0, x.t);
        r.s = 0;
        r.clamp();
        if (this.s != a.s) BigInteger.ZERO.subTo(r, r)
      }

      function bnpSquareTo(r) {
        var x = this.abs();
        var i = r.t = 2 * x.t;
        while (--i >= 0) r[i] = 0;
        for (i = 0; i < x.t - 1; ++i) {
          var c = x.am(i, x[i], r, 2 * i, 0, 1);
          if ((r[i + x.t] += x.am(i + 1, 2 * x[i], r, 2 * i + 1, c, x.t - i - 1)) >= x.DV) {
            r[i + x.t] -= x.DV;
            r[i + x.t + 1] = 1
          }
        }
        if (r.t > 0) r[r.t - 1] += x.am(i, x[i], r, 2 * i, 0, 1);
        r.s = 0;
        r.clamp()
      }

      function bnpDivRemTo(m, q, r) {
        var self = this;
        var pm = m.abs();
        if (pm.t <= 0) return;
        var pt = self.abs();
        if (pt.t < pm.t) {
          if (q != null) q.fromInt(0);
          if (r != null) self.copyTo(r);
          return
        }
        if (r == null) r = new BigInteger;
        var y = new BigInteger,
            ts = self.s,
            ms = m.s;
        var nsh = self.DB - nbits(pm[pm.t - 1]);
        if (nsh > 0) {
          pm.lShiftTo(nsh, y);
          pt.lShiftTo(nsh, r)
        } else {
          pm.copyTo(y);
          pt.copyTo(r)
        }
        var ys = y.t;
        var y0 = y[ys - 1];
        if (y0 == 0) return;
        var yt = y0 * (1 << self.F1) + (ys > 1 ? y[ys - 2] >> self.F2 : 0);
        var d1 = self.FV / yt,
            d2 = (1 << self.F1) / yt,
            e = 1 << self.F2;
        var i = r.t,
            j = i - ys,
            t = q == null ? new BigInteger : q;
        y.dlShiftTo(j, t);
        if (r.compareTo(t) >= 0) {
          r[r.t++] = 1;
          r.subTo(t, r)
        }
        BigInteger.ONE.dlShiftTo(ys, t);
        t.subTo(y, y);
        while (y.t < ys) y[y.t++] = 0;
        while (--j >= 0) {
          var qd = r[--i] == y0 ? self.DM : Math.floor(r[i] * d1 + (r[i - 1] + e) * d2);
          if ((r[i] += y.am(0, qd, r, j, 0, ys)) < qd) {
            y.dlShiftTo(j, t);
            r.subTo(t, r);
            while (r[i] < --qd) r.subTo(t, r)
          }
        }
        if (q != null) {
          r.drShiftTo(ys, q);
          if (ts != ms) BigInteger.ZERO.subTo(q, q)
        }
        r.t = ys;
        r.clamp();
        if (nsh > 0) r.rShiftTo(nsh, r);
        if (ts < 0) BigInteger.ZERO.subTo(r, r)
      }

      function bnMod(a) {
        var r = new BigInteger;
        this.abs().divRemTo(a, null, r);
        if (this.s < 0 && r.compareTo(BigInteger.ZERO) > 0) a.subTo(r, r);
        return r
      }

      function Classic(m) {
        this.m = m
      }

      function cConvert(x) {
        if (x.s < 0 || x.compareTo(this.m) >= 0) return x.mod(this.m);
        else return x
      }

      function cRevert(x) {
        return x
      }

      function cReduce(x) {
        x.divRemTo(this.m, null, x)
      }

      function cMulTo(x, y, r) {
        x.multiplyTo(y, r);
        this.reduce(r)
      }

      function cSqrTo(x, r) {
        x.squareTo(r);
        this.reduce(r)
      }
      Classic.prototype.convert = cConvert;
      Classic.prototype.revert = cRevert;
      Classic.prototype.reduce = cReduce;
      Classic.prototype.mulTo = cMulTo;
      Classic.prototype.sqrTo = cSqrTo;

      function bnpInvDigit() {
        if (this.t < 1) return 0;
        var x = this[0];
        if ((x & 1) == 0) return 0;
        var y = x & 3;
        y = y * (2 - (x & 15) * y) & 15;
        y = y * (2 - (x & 255) * y) & 255;
        y = y * (2 - ((x & 65535) * y & 65535)) & 65535;
        y = y * (2 - x * y % this.DV) % this.DV;
        return y > 0 ? this.DV - y : -y
      }

      function Montgomery(m) {
        this.m = m;
        this.mp = m.invDigit();
        this.mpl = this.mp & 32767;
        this.mph = this.mp >> 15;
        this.um = (1 << m.DB - 15) - 1;
        this.mt2 = 2 * m.t
      }

      function montConvert(x) {
        var r = new BigInteger;
        x.abs().dlShiftTo(this.m.t, r);
        r.divRemTo(this.m, null, r);
        if (x.s < 0 && r.compareTo(BigInteger.ZERO) > 0) this.m.subTo(r, r);
        return r
      }

      function montRevert(x) {
        var r = new BigInteger;
        x.copyTo(r);
        this.reduce(r);
        return r
      }

      function montReduce(x) {
        while (x.t <= this.mt2) x[x.t++] = 0;
        for (var i = 0; i < this.m.t; ++i) {
          var j = x[i] & 32767;
          var u0 = j * this.mpl + ((j * this.mph + (x[i] >> 15) * this.mpl & this.um) << 15) & x.DM;
          j = i + this.m.t;
          x[j] += this.m.am(0, u0, x, i, 0, this.m.t);
          while (x[j] >= x.DV) {
            x[j] -= x.DV;
            x[++j]++
          }
        }
        x.clamp();
        x.drShiftTo(this.m.t, x);
        if (x.compareTo(this.m) >= 0) x.subTo(this.m, x)
      }

      function montSqrTo(x, r) {
        x.squareTo(r);
        this.reduce(r)
      }

      function montMulTo(x, y, r) {
        x.multiplyTo(y, r);
        this.reduce(r)
      }
      Montgomery.prototype.convert = montConvert;
      Montgomery.prototype.revert = montRevert;
      Montgomery.prototype.reduce = montReduce;
      Montgomery.prototype.mulTo = montMulTo;
      Montgomery.prototype.sqrTo = montSqrTo;

      function bnpIsEven() {
        return (this.t > 0 ? this[0] & 1 : this.s) == 0
      }

      function bnpExp(e, z) {
        if (e > 4294967295 || e < 1) return BigInteger.ONE;
        var r = new BigInteger,
            r2 = new BigInteger,
            g = z.convert(this),
            i = nbits(e) - 1;
        g.copyTo(r);
        while (--i >= 0) {
          z.sqrTo(r, r2);
          if ((e & 1 << i) > 0) z.mulTo(r2, g, r);
          else {
            var t = r;
            r = r2;
            r2 = t
          }
        }
        return z.revert(r)
      }

      function bnModPowInt(e, m) {
        var z;
        if (e < 256 || m.isEven()) z = new Classic(m);
        else z = new Montgomery(m);
        return this.exp(e, z)
      }
      proto.copyTo = bnpCopyTo;
      proto.fromInt = bnpFromInt;
      proto.fromString = bnpFromString;
      proto.clamp = bnpClamp;
      proto.dlShiftTo = bnpDLShiftTo;
      proto.drShiftTo = bnpDRShiftTo;
      proto.lShiftTo = bnpLShiftTo;
      proto.rShiftTo = bnpRShiftTo;
      proto.subTo = bnpSubTo;
      proto.multiplyTo = bnpMultiplyTo;
      proto.squareTo = bnpSquareTo;
      proto.divRemTo = bnpDivRemTo;
      proto.invDigit = bnpInvDigit;
      proto.isEven = bnpIsEven;
      proto.exp = bnpExp;
      proto.toString = bnToString;
      proto.negate = bnNegate;
      proto.abs = bnAbs;
      proto.compareTo = bnCompareTo;
      proto.bitLength = bnBitLength;
      proto.byteLength = bnByteLength;
      proto.mod = bnMod;
      proto.modPowInt = bnModPowInt;

      function bnClone() {
        var r = new BigInteger;
        this.copyTo(r);
        return r
      }

      function bnIntValue() {
        if (this.s < 0) {
          if (this.t == 1) return this[0] - this.DV;
          else if (this.t == 0) return -1
        } else if (this.t == 1) return this[0];
        else if (this.t == 0) return 0;
        return (this[1] & (1 << 32 - this.DB) - 1) << this.DB | this[0]
      }

      function bnByteValue() {
        return this.t == 0 ? this.s : this[0] << 24 >> 24
      }

      function bnShortValue() {
        return this.t == 0 ? this.s : this[0] << 16 >> 16
      }

      function bnpChunkSize(r) {
        return Math.floor(Math.LN2 * this.DB / Math.log(r))
      }

      function bnSigNum() {
        if (this.s < 0) return -1;
        else if (this.t <= 0 || this.t == 1 && this[0] <= 0) return 0;
        else return 1
      }

      function bnpToRadix(b) {
        if (b == null) b = 10;
        if (this.signum() == 0 || b < 2 || b > 36) return "0";
        var cs = this.chunkSize(b);
        var a = Math.pow(b, cs);
        var d = nbv(a),
            y = new BigInteger,
            z = new BigInteger,
            r = "";
        this.divRemTo(d, y, z);
        while (y.signum() > 0) {
          r = (a + z.intValue()).toString(b).substr(1) + r;
          y.divRemTo(d, y, z)
        }
        return z.intValue().toString(b) + r
      }

      function bnpFromRadix(s, b) {
        var self = this;
        self.fromInt(0);
        if (b == null) b = 10;
        var cs = self.chunkSize(b);
        var d = Math.pow(b, cs),
            mi = false,
            j = 0,
            w = 0;
        for (var i = 0; i < s.length; ++i) {
          var x = intAt(s, i);
          if (x < 0) {
            if (s.charAt(i) == "-" && self.signum() == 0) mi = true;
            continue
          }
          w = b * w + x;
          if (++j >= cs) {
            self.dMultiply(d);
            self.dAddOffset(w, 0);
            j = 0;
            w = 0
          }
        }
        if (j > 0) {
          self.dMultiply(Math.pow(b, j));
          self.dAddOffset(w, 0)
        }
        if (mi) BigInteger.ZERO.subTo(self, self)
      }

      function bnpFromNumber(a, b, c) {
        var self = this;
        if ("number" == typeof b) {
          if (a < 2) self.fromInt(1);
          else {
            self.fromNumber(a, c);
            if (!self.testBit(a - 1)) self.bitwiseTo(BigInteger.ONE.shiftLeft(a - 1), op_or, self);
            if (self.isEven()) self.dAddOffset(1, 0);
            while (!self.isProbablePrime(b)) {
              self.dAddOffset(2, 0);
              if (self.bitLength() > a) self.subTo(BigInteger.ONE.shiftLeft(a - 1), self)
            }
          }
        } else {
          var x = new Array,
              t = a & 7;
          x.length = (a >> 3) + 1;
          b.nextBytes(x);
          if (t > 0) x[0] &= (1 << t) - 1;
          else x[0] = 0;
          self.fromString(x, 256)
        }
      }

      function bnToByteArray() {
        var self = this;
        var i = self.t,
            r = new Array;
        r[0] = self.s;
        var p = self.DB - i * self.DB % 8,
            d, k = 0;
        if (i-- > 0) {
          if (p < self.DB && (d = self[i] >> p) != (self.s & self.DM) >> p) r[k++] = d | self.s << self.DB - p;
          while (i >= 0) {
            if (p < 8) {
              d = (self[i] & (1 << p) - 1) << 8 - p;
              d |= self[--i] >> (p += self.DB - 8)
            } else {
              d = self[i] >> (p -= 8) & 255;
              if (p <= 0) {
                p += self.DB;
                --i
              }
            }
            if ((d & 128) != 0) d |= -256;
            if (k === 0 && (self.s & 128) != (d & 128)) ++k;
            if (k > 0 || d != self.s) r[k++] = d
          }
        }
        return r
      }

      function bnEquals(a) {
        return this.compareTo(a) == 0
      }

      function bnMin(a) {
        return this.compareTo(a) < 0 ? this : a
      }

      function bnMax(a) {
        return this.compareTo(a) > 0 ? this : a
      }

      function bnpBitwiseTo(a, op, r) {
        var self = this;
        var i, f, m = Math.min(a.t, self.t);
        for (i = 0; i < m; ++i) r[i] = op(self[i], a[i]);
        if (a.t < self.t) {
          f = a.s & self.DM;
          for (i = m; i < self.t; ++i) r[i] = op(self[i], f);
          r.t = self.t
        } else {
          f = self.s & self.DM;
          for (i = m; i < a.t; ++i) r[i] = op(f, a[i]);
          r.t = a.t
        }
        r.s = op(self.s, a.s);
        r.clamp()
      }

      function op_and(x, y) {
        return x & y
      }

      function bnAnd(a) {
        var r = new BigInteger;
        this.bitwiseTo(a, op_and, r);
        return r
      }

      function op_or(x, y) {
        return x | y
      }

      function bnOr(a) {
        var r = new BigInteger;
        this.bitwiseTo(a, op_or, r);
        return r
      }

      function op_xor(x, y) {
        return x ^ y
      }

      function bnXor(a) {
        var r = new BigInteger;
        this.bitwiseTo(a, op_xor, r);
        return r
      }

      function op_andnot(x, y) {
        return x & ~y
      }

      function bnAndNot(a) {
        var r = new BigInteger;
        this.bitwiseTo(a, op_andnot, r);
        return r
      }

      function bnNot() {
        var r = new BigInteger;
        for (var i = 0; i < this.t; ++i) r[i] = this.DM & ~this[i];
        r.t = this.t;
        r.s = ~this.s;
        return r
      }

      function bnShiftLeft(n) {
        var r = new BigInteger;
        if (n < 0) this.rShiftTo(-n, r);
        else this.lShiftTo(n, r);
        return r
      }

      function bnShiftRight(n) {
        var r = new BigInteger;
        if (n < 0) this.lShiftTo(-n, r);
        else this.rShiftTo(n, r);
        return r
      }

      function lbit(x) {
        if (x == 0) return -1;
        var r = 0;
        if ((x & 65535) == 0) {
          x >>= 16;
          r += 16
        }
        if ((x & 255) == 0) {
          x >>= 8;
          r += 8
        }
        if ((x & 15) == 0) {
          x >>= 4;
          r += 4
        }
        if ((x & 3) == 0) {
          x >>= 2;
          r += 2
        }
        if ((x & 1) == 0) ++r;
        return r
      }

      function bnGetLowestSetBit() {
        for (var i = 0; i < this.t; ++i)
          if (this[i] != 0) return i * this.DB + lbit(this[i]);
        if (this.s < 0) return this.t * this.DB;
        return -1
      }

      function cbit(x) {
        var r = 0;
        while (x != 0) {
          x &= x - 1;
          ++r
        }
        return r
      }

      function bnBitCount() {
        var r = 0,
            x = this.s & this.DM;
        for (var i = 0; i < this.t; ++i) r += cbit(this[i] ^ x);
        return r
      }

      function bnTestBit(n) {
        var j = Math.floor(n / this.DB);
        if (j >= this.t) return this.s != 0;
        return (this[j] & 1 << n % this.DB) != 0
      }

      function bnpChangeBit(n, op) {
        var r = BigInteger.ONE.shiftLeft(n);
        this.bitwiseTo(r, op, r);
        return r
      }

      function bnSetBit(n) {
        return this.changeBit(n, op_or)
      }

      function bnClearBit(n) {
        return this.changeBit(n, op_andnot)
      }

      function bnFlipBit(n) {
        return this.changeBit(n, op_xor)
      }

      function bnpAddTo(a, r) {
        var self = this;
        var i = 0,
            c = 0,
            m = Math.min(a.t, self.t);
        while (i < m) {
          c += self[i] + a[i];
          r[i++] = c & self.DM;
          c >>= self.DB
        }
        if (a.t < self.t) {
          c += a.s;
          while (i < self.t) {
            c += self[i];
            r[i++] = c & self.DM;
            c >>= self.DB
          }
          c += self.s
        } else {
          c += self.s;
          while (i < a.t) {
            c += a[i];
            r[i++] = c & self.DM;
            c >>= self.DB
          }
          c += a.s
        }
        r.s = c < 0 ? -1 : 0;
        if (c > 0) r[i++] = c;
        else if (c < -1) r[i++] = self.DV + c;
        r.t = i;
        r.clamp()
      }

      function bnAdd(a) {
        var r = new BigInteger;
        this.addTo(a, r);
        return r
      }

      function bnSubtract(a) {
        var r = new BigInteger;
        this.subTo(a, r);
        return r
      }

      function bnMultiply(a) {
        var r = new BigInteger;
        this.multiplyTo(a, r);
        return r
      }

      function bnSquare() {
        var r = new BigInteger;
        this.squareTo(r);
        return r
      }

      function bnDivide(a) {
        var r = new BigInteger;
        this.divRemTo(a, r, null);
        return r
      }

      function bnRemainder(a) {
        var r = new BigInteger;
        this.divRemTo(a, null, r);
        return r
      }

      function bnDivideAndRemainder(a) {
        var q = new BigInteger,
            r = new BigInteger;
        this.divRemTo(a, q, r);
        return new Array(q, r)
      }

      function bnpDMultiply(n) {
        this[this.t] = this.am(0, n - 1, this, 0, 0, this.t);
        ++this.t;
        this.clamp()
      }

      function bnpDAddOffset(n, w) {
        if (n == 0) return;
        while (this.t <= w) this[this.t++] = 0;
        this[w] += n;
        while (this[w] >= this.DV) {
          this[w] -= this.DV;
          if (++w >= this.t) this[this.t++] = 0;
          ++this[w]
        }
      }

      function NullExp() {}

      function nNop(x) {
        return x
      }

      function nMulTo(x, y, r) {
        x.multiplyTo(y, r)
      }

      function nSqrTo(x, r) {
        x.squareTo(r)
      }
      NullExp.prototype.convert = nNop;
      NullExp.prototype.revert = nNop;
      NullExp.prototype.mulTo = nMulTo;
      NullExp.prototype.sqrTo = nSqrTo;

      function bnPow(e) {
        return this.exp(e, new NullExp)
      }

      function bnpMultiplyLowerTo(a, n, r) {
        var i = Math.min(this.t + a.t, n);
        r.s = 0;
        r.t = i;
        while (i > 0) r[--i] = 0;
        var j;
        for (j = r.t - this.t; i < j; ++i) r[i + this.t] = this.am(0, a[i], r, i, 0, this.t);
        for (j = Math.min(a.t, n); i < j; ++i) this.am(0, a[i], r, i, 0, n - i);
        r.clamp()
      }

      function bnpMultiplyUpperTo(a, n, r) {
        --n;
        var i = r.t = this.t + a.t - n;
        r.s = 0;
        while (--i >= 0) r[i] = 0;
        for (i = Math.max(n - this.t, 0); i < a.t; ++i) r[this.t + i - n] = this.am(n - i, a[i], r, 0, 0, this.t + i - n);
        r.clamp();
        r.drShiftTo(1, r)
      }

      function Barrett(m) {
        this.r2 = new BigInteger;
        this.q3 = new BigInteger;
        BigInteger.ONE.dlShiftTo(2 * m.t, this.r2);
        this.mu = this.r2.divide(m);
        this.m = m
      }

      function barrettConvert(x) {
        if (x.s < 0 || x.t > 2 * this.m.t) return x.mod(this.m);
        else if (x.compareTo(this.m) < 0) return x;
        else {
          var r = new BigInteger;
          x.copyTo(r);
          this.reduce(r);
          return r
        }
      }

      function barrettRevert(x) {
        return x
      }

      function barrettReduce(x) {
        var self = this;
        x.drShiftTo(self.m.t - 1, self.r2);
        if (x.t > self.m.t + 1) {
          x.t = self.m.t + 1;
          x.clamp()
        }
        self.mu.multiplyUpperTo(self.r2, self.m.t + 1, self.q3);
        self.m.multiplyLowerTo(self.q3, self.m.t + 1, self.r2);
        while (x.compareTo(self.r2) < 0) x.dAddOffset(1, self.m.t + 1);
        x.subTo(self.r2, x);
        while (x.compareTo(self.m) >= 0) x.subTo(self.m, x)
      }

      function barrettSqrTo(x, r) {
        x.squareTo(r);
        this.reduce(r)
      }

      function barrettMulTo(x, y, r) {
        x.multiplyTo(y, r);
        this.reduce(r)
      }
      Barrett.prototype.convert = barrettConvert;
      Barrett.prototype.revert = barrettRevert;
      Barrett.prototype.reduce = barrettReduce;
      Barrett.prototype.mulTo = barrettMulTo;
      Barrett.prototype.sqrTo = barrettSqrTo;

      function bnModPow(e, m) {
        var i = e.bitLength(),
            k, r = nbv(1),
            z;
        if (i <= 0) return r;
        else if (i < 18) k = 1;
        else if (i < 48) k = 3;
        else if (i < 144) k = 4;
        else if (i < 768) k = 5;
        else k = 6;
        if (i < 8) z = new Classic(m);
        else if (m.isEven()) z = new Barrett(m);
        else z = new Montgomery(m);
        var g = new Array,
            n = 3,
            k1 = k - 1,
            km = (1 << k) - 1;
        g[1] = z.convert(this);
        if (k > 1) {
          var g2 = new BigInteger;
          z.sqrTo(g[1], g2);
          while (n <= km) {
            g[n] = new BigInteger;
            z.mulTo(g2, g[n - 2], g[n]);
            n += 2
          }
        }
        var j = e.t - 1,
            w, is1 = true,
            r2 = new BigInteger,
            t;
        i = nbits(e[j]) - 1;
        while (j >= 0) {
          if (i >= k1) w = e[j] >> i - k1 & km;
          else {
            w = (e[j] & (1 << i + 1) - 1) << k1 - i;
            if (j > 0) w |= e[j - 1] >> this.DB + i - k1
          }
          n = k;
          while ((w & 1) == 0) {
            w >>= 1;
            --n
          }
          if ((i -= n) < 0) {
            i += this.DB;
            --j
          }
          if (is1) {
            g[w].copyTo(r);
            is1 = false
          } else {
            while (n > 1) {
              z.sqrTo(r, r2);
              z.sqrTo(r2, r);
              n -= 2
            }
            if (n > 0) z.sqrTo(r, r2);
            else {
              t = r;
              r = r2;
              r2 = t
            }
            z.mulTo(r2, g[w], r)
          }
          while (j >= 0 && (e[j] & 1 << i) == 0) {
            z.sqrTo(r, r2);
            t = r;
            r = r2;
            r2 = t;
            if (--i < 0) {
              i = this.DB - 1;
              --j
            }
          }
        }
        return z.revert(r)
      }

      function bnGCD(a) {
        var x = this.s < 0 ? this.negate() : this.clone();
        var y = a.s < 0 ? a.negate() : a.clone();
        if (x.compareTo(y) < 0) {
          var t = x;
          x = y;
          y = t
        }
        var i = x.getLowestSetBit(),
            g = y.getLowestSetBit();
        if (g < 0) return x;
        if (i < g) g = i;
        if (g > 0) {
          x.rShiftTo(g, x);
          y.rShiftTo(g, y)
        }
        while (x.signum() > 0) {
          if ((i = x.getLowestSetBit()) > 0) x.rShiftTo(i, x);
          if ((i = y.getLowestSetBit()) > 0) y.rShiftTo(i, y);
          if (x.compareTo(y) >= 0) {
            x.subTo(y, x);
            x.rShiftTo(1, x)
          } else {
            y.subTo(x, y);
            y.rShiftTo(1, y)
          }
        }
        if (g > 0) y.lShiftTo(g, y);
        return y
      }

      function bnpModInt(n) {
        if (n <= 0) return 0;
        var d = this.DV % n,
            r = this.s < 0 ? n - 1 : 0;
        if (this.t > 0)
          if (d == 0) r = this[0] % n;
          else
            for (var i = this.t - 1; i >= 0; --i) r = (d * r + this[i]) % n;
        return r
      }

      function bnModInverse(m) {
        var ac = m.isEven();
        if (this.isEven() && ac || m.signum() == 0) return BigInteger.ZERO;
        var u = m.clone(),
            v = this.clone();
        var a = nbv(1),
            b = nbv(0),
            c = nbv(0),
            d = nbv(1);
        while (u.signum() != 0) {
          while (u.isEven()) {
            u.rShiftTo(1, u);
            if (ac) {
              if (!a.isEven() || !b.isEven()) {
                a.addTo(this, a);
                b.subTo(m, b)
              }
              a.rShiftTo(1, a)
            } else if (!b.isEven()) b.subTo(m, b);
            b.rShiftTo(1, b)
          }
          while (v.isEven()) {
            v.rShiftTo(1, v);
            if (ac) {
              if (!c.isEven() || !d.isEven()) {
                c.addTo(this, c);
                d.subTo(m, d)
              }
              c.rShiftTo(1, c)
            } else if (!d.isEven()) d.subTo(m, d);
            d.rShiftTo(1, d)
          }
          if (u.compareTo(v) >= 0) {
            u.subTo(v, u);
            if (ac) a.subTo(c, a);
            b.subTo(d, b)
          } else {
            v.subTo(u, v);
            if (ac) c.subTo(a, c);
            d.subTo(b, d)
          }
        }
        if (v.compareTo(BigInteger.ONE) != 0) return BigInteger.ZERO;
        if (d.compareTo(m) >= 0) return d.subtract(m);
        if (d.signum() < 0) d.addTo(m, d);
        else return d;
        if (d.signum() < 0) return d.add(m);
        else return d
      }
      var lowprimes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521, 523, 541, 547, 557, 563, 569, 571, 577, 587, 593, 599, 601, 607, 613, 617, 619, 631, 641, 643, 647, 653, 659, 661, 673, 677, 683, 691, 701, 709, 719, 727, 733, 739, 743, 751, 757, 761, 769, 773, 787, 797, 809, 811, 821, 823, 827, 829, 839, 853, 857, 859, 863, 877, 881, 883, 887, 907, 911, 919, 929, 937, 941, 947, 953, 967, 971, 977, 983, 991, 997];
      var lplim = (1 << 26) / lowprimes[lowprimes.length - 1];

      function bnIsProbablePrime(t) {
        var i, x = this.abs();
        if (x.t == 1 && x[0] <= lowprimes[lowprimes.length - 1]) {
          for (i = 0; i < lowprimes.length; ++i)
            if (x[0] == lowprimes[i]) return true;
          return false
        }
        if (x.isEven()) return false;
        i = 1;
        while (i < lowprimes.length) {
          var m = lowprimes[i],
              j = i + 1;
          while (j < lowprimes.length && m < lplim) m *= lowprimes[j++];
          m = x.modInt(m);
          while (i < j)
            if (m % lowprimes[i++] == 0) return false
        }
        return x.millerRabin(t)
      }

      function bnpMillerRabin(t) {
        var n1 = this.subtract(BigInteger.ONE);
        var k = n1.getLowestSetBit();
        if (k <= 0) return false;
        var r = n1.shiftRight(k);
        t = t + 1 >> 1;
        if (t > lowprimes.length) t = lowprimes.length;
        var a = new BigInteger(null);
        var j, bases = [];
        for (var i = 0; i < t; ++i) {
          for (;;) {
            j = lowprimes[Math.floor(Math.random() * lowprimes.length)];
            if (bases.indexOf(j) == -1) break
          }
          bases.push(j);
          a.fromInt(j);
          var y = a.modPow(r, this);
          if (y.compareTo(BigInteger.ONE) != 0 && y.compareTo(n1) != 0) {
            var j = 1;
            while (j++ < k && y.compareTo(n1) != 0) {
              y = y.modPowInt(2, this);
              if (y.compareTo(BigInteger.ONE) == 0) return false
            }
            if (y.compareTo(n1) != 0) return false
          }
        }
        return true
      }
      proto.chunkSize = bnpChunkSize;
      proto.toRadix = bnpToRadix;
      proto.fromRadix = bnpFromRadix;
      proto.fromNumber = bnpFromNumber;
      proto.bitwiseTo = bnpBitwiseTo;
      proto.changeBit = bnpChangeBit;
      proto.addTo = bnpAddTo;
      proto.dMultiply = bnpDMultiply;
      proto.dAddOffset = bnpDAddOffset;
      proto.multiplyLowerTo = bnpMultiplyLowerTo;
      proto.multiplyUpperTo = bnpMultiplyUpperTo;
      proto.modInt = bnpModInt;
      proto.millerRabin = bnpMillerRabin;
      proto.clone = bnClone;
      proto.intValue = bnIntValue;
      proto.byteValue = bnByteValue;
      proto.shortValue = bnShortValue;
      proto.signum = bnSigNum;
      proto.toByteArray = bnToByteArray;
      proto.equals = bnEquals;
      proto.min = bnMin;
      proto.max = bnMax;
      proto.and = bnAnd;
      proto.or = bnOr;
      proto.xor = bnXor;
      proto.andNot = bnAndNot;
      proto.not = bnNot;
      proto.shiftLeft = bnShiftLeft;
      proto.shiftRight = bnShiftRight;
      proto.getLowestSetBit = bnGetLowestSetBit;
      proto.bitCount = bnBitCount;
      proto.testBit = bnTestBit;
      proto.setBit = bnSetBit;
      proto.clearBit = bnClearBit;
      proto.flipBit = bnFlipBit;
      proto.add = bnAdd;
      proto.subtract = bnSubtract;
      proto.multiply = bnMultiply;
      proto.divide = bnDivide;
      proto.remainder = bnRemainder;
      proto.divideAndRemainder = bnDivideAndRemainder;
      proto.modPow = bnModPow;
      proto.modInverse = bnModInverse;
      proto.pow = bnPow;
      proto.gcd = bnGCD;
      proto.isProbablePrime = bnIsProbablePrime;
      proto.square = bnSquare;
      BigInteger.ZERO = nbv(0);
      BigInteger.ONE = nbv(1);
      BigInteger.valueOf = nbv;
      module.exports = BigInteger
    }, {
      "../package.json": 4
    }],
    2: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var BigInteger = require("./bigi");
        BigInteger.fromByteArrayUnsigned = function(byteArray) {
          if (byteArray[0] & 128) {
            return new BigInteger([0].concat(byteArray))
          }
          return new BigInteger(byteArray)
        };
        BigInteger.prototype.toByteArrayUnsigned = function() {
          var byteArray = this.toByteArray();
          return byteArray[0] === 0 ? byteArray.slice(1) : byteArray
        };
        BigInteger.fromDERInteger = function(byteArray) {
          return new BigInteger(byteArray)
        };
        BigInteger.prototype.toDERInteger = BigInteger.prototype.toByteArray;
        BigInteger.fromBuffer = function(buffer) {
          if (buffer[0] & 128) {
            var byteArray = Array.prototype.slice.call(buffer);
            return new BigInteger([0].concat(byteArray))
          }
          return new BigInteger(buffer)
        };
        BigInteger.fromHex = function(hex) {
          if (hex === "") return BigInteger.ZERO;
          assert.equal(hex, hex.match(/^[A-Fa-f0-9]+/), "Invalid hex string");
          assert.equal(hex.length % 2, 0, "Incomplete hex");
          return new BigInteger(hex, 16)
        };
        BigInteger.prototype.toBuffer = function(size) {
          var byteArray = this.toByteArrayUnsigned();
          var zeros = [];
          var padding = size - byteArray.length;
          while (zeros.length < padding) zeros.push(0);
          return new Buffer(zeros.concat(byteArray))
        };
        BigInteger.prototype.toHex = function(size) {
          return this.toBuffer(size).toString("hex")
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./bigi": 1,
      assert: 5,
      buffer: 7
    }],
    3: [function(require, module, exports) {
      var BigInteger = require("./bigi");
      require("./convert");
      module.exports = BigInteger
    }, {
      "./bigi": 1,
      "./convert": 2
    }],
    4: [function(require, module, exports) {
      module.exports = {
        name: "bigi",
        version: "1.4.0",
        description: "Big integers.",
        keywords: ["cryptography", "math", "bitcoin", "arbitrary", "precision", "arithmetic", "big", "integer", "int", "number", "biginteger", "bigint", "bignumber", "decimal", "float"],
        devDependencies: {
          mocha: "^1.20.1",
          jshint: "^2.5.1",
          coveralls: "^2.10.0",
          istanbul: "^0.2.11"
        },
        repository: {
          url: "https://github.com/cryptocoinjs/bigi",
          type: "git"
        },
        main: "./lib/index.js",
        scripts: {
          test: "_mocha -- test/*.js",
          jshint: "jshint --config jshint.json lib/*.js ; true",
          unit: "mocha",
          coverage: "istanbul cover ./node_modules/.bin/_mocha -- --reporter list test/*.js",
          coveralls: "npm run-script coverage && node ./node_modules/.bin/coveralls < coverage/lcov.info"
        },
        dependencies: {},
        testling: {
          files: "test/*.js",
          harness: "mocha",
          browsers: ["ie/9..latest", "firefox/latest", "chrome/latest", "safari/6.0..latest", "iphone/6.0..latest", "android-browser/4.2..latest"]
        },
        bugs: {
          url: "https://github.com/cryptocoinjs/bigi/issues"
        },
        homepage: "https://github.com/cryptocoinjs/bigi",
        _id: "bigi@1.4.0",
        dist: {
          shasum: "90ac1aeac0a531216463bdb58f42c1e05c8407ac",
          tarball: "http://registry.npmjs.org/bigi/-/bigi-1.4.0.tgz"
        },
        _from: "bigi@^1.1.0",
        _npmVersion: "1.4.3",
        _npmUser: {
          name: "jp",
          email: "jprichardson@gmail.com"
        },
        maintainers: [{
          name: "jp",
          email: "jprichardson@gmail.com"
        }, {
          name: "midnightlightning",
          email: "boydb@midnightdesign.ws"
        }, {
          name: "sidazhang",
          email: "sidazhang89@gmail.com"
        }, {
          name: "nadav",
          email: "npm@shesek.info"
        }],
        directories: {},
        _shasum: "90ac1aeac0a531216463bdb58f42c1e05c8407ac",
        _resolved: "https://registry.npmjs.org/bigi/-/bigi-1.4.0.tgz"
      }
    }, {}],
    5: [function(require, module, exports) {
      var util = require("util/");
      var pSlice = Array.prototype.slice;
      var hasOwn = Object.prototype.hasOwnProperty;
      var assert = module.exports = ok;
      assert.AssertionError = function AssertionError(options) {
        this.name = "AssertionError";
        this.actual = options.actual;
        this.expected = options.expected;
        this.operator = options.operator;
        if (options.message) {
          this.message = options.message;
          this.generatedMessage = false
        } else {
          this.message = getMessage(this);
          this.generatedMessage = true
        }
        var stackStartFunction = options.stackStartFunction || fail;
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, stackStartFunction)
        } else {
          var err = new Error;
          if (err.stack) {
            var out = err.stack;
            var fn_name = stackStartFunction.name;
            var idx = out.indexOf("\n" + fn_name);
            if (idx >= 0) {
              var next_line = out.indexOf("\n", idx + 1);
              out = out.substring(next_line + 1)
            }
            this.stack = out
          }
        }
      };
      util.inherits(assert.AssertionError, Error);

      function replacer(key, value) {
        if (util.isUndefined(value)) {
          return "" + value
        }
        if (util.isNumber(value) && (isNaN(value) || !isFinite(value))) {
          return value.toString()
        }
        if (util.isFunction(value) || util.isRegExp(value)) {
          return value.toString()
        }
        return value
      }

      function truncate(s, n) {
        if (util.isString(s)) {
          return s.length < n ? s : s.slice(0, n)
        } else {
          return s
        }
      }

      function getMessage(self) {
        return truncate(JSON.stringify(self.actual, replacer), 128) + " " + self.operator + " " + truncate(JSON.stringify(self.expected, replacer), 128)
      }

      function fail(actual, expected, message, operator, stackStartFunction) {
        throw new assert.AssertionError({
          message: message,
          actual: actual,
          expected: expected,
          operator: operator,
          stackStartFunction: stackStartFunction
        })
      }
      assert.fail = fail;

      function ok(value, message) {
        if (!value) fail(value, true, message, "==", assert.ok)
      }
      assert.ok = ok;
      assert.equal = function equal(actual, expected, message) {
        if (actual != expected) fail(actual, expected, message, "==", assert.equal)
      };
      assert.notEqual = function notEqual(actual, expected, message) {
        if (actual == expected) {
          fail(actual, expected, message, "!=", assert.notEqual)
        }
      };
      assert.deepEqual = function deepEqual(actual, expected, message) {
        if (!_deepEqual(actual, expected)) {
          fail(actual, expected, message, "deepEqual", assert.deepEqual)
        }
      };

      function _deepEqual(actual, expected) {
        if (actual === expected) {
          return true
        } else if (util.isBuffer(actual) && util.isBuffer(expected)) {
          if (actual.length != expected.length) return false;
          for (var i = 0; i < actual.length; i++) {
            if (actual[i] !== expected[i]) return false
          }
          return true
        } else if (util.isDate(actual) && util.isDate(expected)) {
          return actual.getTime() === expected.getTime()
        } else if (util.isRegExp(actual) && util.isRegExp(expected)) {
          return actual.source === expected.source && actual.global === expected.global && actual.multiline === expected.multiline && actual.lastIndex === expected.lastIndex && actual.ignoreCase === expected.ignoreCase
        } else if (!util.isObject(actual) && !util.isObject(expected)) {
          return actual == expected
        } else {
          return objEquiv(actual, expected)
        }
      }

      function isArguments(object) {
        return Object.prototype.toString.call(object) == "[object Arguments]"
      }

      function objEquiv(a, b) {
        if (util.isNullOrUndefined(a) || util.isNullOrUndefined(b)) return false;
        if (a.prototype !== b.prototype) return false;
        if (isArguments(a)) {
          if (!isArguments(b)) {
            return false
          }
          a = pSlice.call(a);
          b = pSlice.call(b);
          return _deepEqual(a, b)
        }
        try {
          var ka = objectKeys(a),
              kb = objectKeys(b),
              key, i
        } catch (e) {
          return false
        }
        if (ka.length != kb.length) return false;
        ka.sort();
        kb.sort();
        for (i = ka.length - 1; i >= 0; i--) {
          if (ka[i] != kb[i]) return false
        }
        for (i = ka.length - 1; i >= 0; i--) {
          key = ka[i];
          if (!_deepEqual(a[key], b[key])) return false
        }
        return true
      }
      assert.notDeepEqual = function notDeepEqual(actual, expected, message) {
        if (_deepEqual(actual, expected)) {
          fail(actual, expected, message, "notDeepEqual", assert.notDeepEqual)
        }
      };
      assert.strictEqual = function strictEqual(actual, expected, message) {
        if (actual !== expected) {
          fail(actual, expected, message, "===", assert.strictEqual)
        }
      };
      assert.notStrictEqual = function notStrictEqual(actual, expected, message) {
        if (actual === expected) {
          fail(actual, expected, message, "!==", assert.notStrictEqual)
        }
      };

      function expectedException(actual, expected) {
        if (!actual || !expected) {
          return false
        }
        if (Object.prototype.toString.call(expected) == "[object RegExp]") {
          return expected.test(actual)
        } else if (actual instanceof expected) {
          return true
        } else if (expected.call({}, actual) === true) {
          return true
        }
        return false
      }

      function _throws(shouldThrow, block, expected, message) {
        var actual;
        if (util.isString(expected)) {
          message = expected;
          expected = null
        }
        try {
          block()
        } catch (e) {
          actual = e
        }
        message = (expected && expected.name ? " (" + expected.name + ")." : ".") + (message ? " " + message : ".");
        if (shouldThrow && !actual) {
          fail(actual, expected, "Missing expected exception" + message)
        }
        if (!shouldThrow && expectedException(actual, expected)) {
          fail(actual, expected, "Got unwanted exception" + message)
        }
        if (shouldThrow && actual && expected && !expectedException(actual, expected) || !shouldThrow && actual) {
          throw actual
        }
      }
      assert.throws = function(block, error, message) {
        _throws.apply(this, [true].concat(pSlice.call(arguments)))
      };
      assert.doesNotThrow = function(block, message) {
        _throws.apply(this, [false].concat(pSlice.call(arguments)))
      };
      assert.ifError = function(err) {
        if (err) {
          throw err
        }
      };
      var objectKeys = Object.keys || function(obj) {
            var keys = [];
            for (var key in obj) {
              if (hasOwn.call(obj, key)) keys.push(key)
            }
            return keys
          }
    }, {
      "util/": 29
    }],
    6: [function(require, module, exports) {}, {}],
    7: [function(require, module, exports) {
      var base64 = require("base64-js");
      var ieee754 = require("ieee754");
      var isArray = require("is-array");
      exports.Buffer = Buffer;
      exports.SlowBuffer = Buffer;
      exports.INSPECT_MAX_BYTES = 50;
      Buffer.poolSize = 8192;
      var kMaxLength = 1073741823;
      Buffer.TYPED_ARRAY_SUPPORT = function() {
        try {
          var buf = new ArrayBuffer(0);
          var arr = new Uint8Array(buf);
          arr.foo = function() {
            return 42
          };
          return 42 === arr.foo() && typeof arr.subarray === "function" && new Uint8Array(1).subarray(1, 1).byteLength === 0
        } catch (e) {
          return false
        }
      }();

      function Buffer(subject, encoding, noZero) {
        if (!(this instanceof Buffer)) return new Buffer(subject, encoding, noZero);
        var type = typeof subject;
        var length;
        if (type === "number") length = subject > 0 ? subject >>> 0 : 0;
        else if (type === "string") {
          if (encoding === "base64") subject = base64clean(subject);
          length = Buffer.byteLength(subject, encoding)
        } else if (type === "object" && subject !== null) {
          if (subject.type === "Buffer" && isArray(subject.data)) subject = subject.data;
          length = +subject.length > 0 ? Math.floor(+subject.length) : 0
        } else throw new TypeError("must start with number, buffer, array or string");
        if (this.length > kMaxLength) throw new RangeError("Attempt to allocate Buffer larger than maximum " + "size: 0x" + kMaxLength.toString(16) + " bytes");
        var buf;
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          buf = Buffer._augment(new Uint8Array(length))
        } else {
          buf = this;
          buf.length = length;
          buf._isBuffer = true
        }
        var i;
        if (Buffer.TYPED_ARRAY_SUPPORT && typeof subject.byteLength === "number") {
          buf._set(subject)
        } else if (isArrayish(subject)) {
          if (Buffer.isBuffer(subject)) {
            for (i = 0; i < length; i++) buf[i] = subject.readUInt8(i)
          } else {
            for (i = 0; i < length; i++) buf[i] = (subject[i] % 256 + 256) % 256
          }
        } else if (type === "string") {
          buf.write(subject, 0, encoding)
        } else if (type === "number" && !Buffer.TYPED_ARRAY_SUPPORT && !noZero) {
          for (i = 0; i < length; i++) {
            buf[i] = 0
          }
        }
        return buf
      }
      Buffer.isBuffer = function(b) {
        return !!(b != null && b._isBuffer)
      };
      Buffer.compare = function(a, b) {
        if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b)) throw new TypeError("Arguments must be Buffers");
        var x = a.length;
        var y = b.length;
        for (var i = 0, len = Math.min(x, y); i < len && a[i] === b[i]; i++) {}
        if (i !== len) {
          x = a[i];
          y = b[i]
        }
        if (x < y) return -1;
        if (y < x) return 1;
        return 0
      };
      Buffer.isEncoding = function(encoding) {
        switch (String(encoding).toLowerCase()) {
          case "hex":
          case "utf8":
          case "utf-8":
          case "ascii":
          case "binary":
          case "base64":
          case "raw":
          case "ucs2":
          case "ucs-2":
          case "utf16le":
          case "utf-16le":
            return true;
          default:
            return false
        }
      };
      Buffer.concat = function(list, totalLength) {
        if (!isArray(list)) throw new TypeError("Usage: Buffer.concat(list[, length])");
        if (list.length === 0) {
          return new Buffer(0)
        } else if (list.length === 1) {
          return list[0]
        }
        var i;
        if (totalLength === undefined) {
          totalLength = 0;
          for (i = 0; i < list.length; i++) {
            totalLength += list[i].length
          }
        }
        var buf = new Buffer(totalLength);
        var pos = 0;
        for (i = 0; i < list.length; i++) {
          var item = list[i];
          item.copy(buf, pos);
          pos += item.length
        }
        return buf
      };
      Buffer.byteLength = function(str, encoding) {
        var ret;
        str = str + "";
        switch (encoding || "utf8") {
          case "ascii":
          case "binary":
          case "raw":
            ret = str.length;
            break;
          case "ucs2":
          case "ucs-2":
          case "utf16le":
          case "utf-16le":
            ret = str.length * 2;
            break;
          case "hex":
            ret = str.length >>> 1;
            break;
          case "utf8":
          case "utf-8":
            ret = utf8ToBytes(str).length;
            break;
          case "base64":
            ret = base64ToBytes(str).length;
            break;
          default:
            ret = str.length
        }
        return ret
      };
      Buffer.prototype.length = undefined;
      Buffer.prototype.parent = undefined;
      Buffer.prototype.toString = function(encoding, start, end) {
        var loweredCase = false;
        start = start >>> 0;
        end = end === undefined || end === Infinity ? this.length : end >>> 0;
        if (!encoding) encoding = "utf8";
        if (start < 0) start = 0;
        if (end > this.length) end = this.length;
        if (end <= start) return "";
        while (true) {
          switch (encoding) {
            case "hex":
              return hexSlice(this, start, end);
            case "utf8":
            case "utf-8":
              return utf8Slice(this, start, end);
            case "ascii":
              return asciiSlice(this, start, end);
            case "binary":
              return binarySlice(this, start, end);
            case "base64":
              return base64Slice(this, start, end);
            case "ucs2":
            case "ucs-2":
            case "utf16le":
            case "utf-16le":
              return utf16leSlice(this, start, end);
            default:
              if (loweredCase) throw new TypeError("Unknown encoding: " + encoding);
              encoding = (encoding + "").toLowerCase();
              loweredCase = true
          }
        }
      };
      Buffer.prototype.equals = function(b) {
        if (!Buffer.isBuffer(b)) throw new TypeError("Argument must be a Buffer");
        return Buffer.compare(this, b) === 0
      };
      Buffer.prototype.inspect = function() {
        var str = "";
        var max = exports.INSPECT_MAX_BYTES;
        if (this.length > 0) {
          str = this.toString("hex", 0, max).match(/.{2}/g).join(" ");
          if (this.length > max) str += " ... "
        }
        return "<Buffer " + str + ">"
      };
      Buffer.prototype.compare = function(b) {
        if (!Buffer.isBuffer(b)) throw new TypeError("Argument must be a Buffer");
        return Buffer.compare(this, b)
      };
      Buffer.prototype.get = function(offset) {
        console.log(".get() is deprecated. Access using array indexes instead.");
        return this.readUInt8(offset)
      };
      Buffer.prototype.set = function(v, offset) {
        console.log(".set() is deprecated. Access using array indexes instead.");
        return this.writeUInt8(v, offset)
      };

      function hexWrite(buf, string, offset, length) {
        offset = Number(offset) || 0;
        var remaining = buf.length - offset;
        if (!length) {
          length = remaining
        } else {
          length = Number(length);
          if (length > remaining) {
            length = remaining
          }
        }
        var strLen = string.length;
        if (strLen % 2 !== 0) throw new Error("Invalid hex string");
        if (length > strLen / 2) {
          length = strLen / 2
        }
        for (var i = 0; i < length; i++) {
          var byte = parseInt(string.substr(i * 2, 2), 16);
          if (isNaN(byte)) throw new Error("Invalid hex string");
          buf[offset + i] = byte
        }
        return i
      }

      function utf8Write(buf, string, offset, length) {
        var charsWritten = blitBuffer(utf8ToBytes(string), buf, offset, length);
        return charsWritten
      }

      function asciiWrite(buf, string, offset, length) {
        var charsWritten = blitBuffer(asciiToBytes(string), buf, offset, length);
        return charsWritten
      }

      function binaryWrite(buf, string, offset, length) {
        return asciiWrite(buf, string, offset, length)
      }

      function base64Write(buf, string, offset, length) {
        var charsWritten = blitBuffer(base64ToBytes(string), buf, offset, length);
        return charsWritten
      }

      function utf16leWrite(buf, string, offset, length) {
        var charsWritten = blitBuffer(utf16leToBytes(string), buf, offset, length, 2);
        return charsWritten
      }
      Buffer.prototype.write = function(string, offset, length, encoding) {
        if (isFinite(offset)) {
          if (!isFinite(length)) {
            encoding = length;
            length = undefined
          }
        } else {
          var swap = encoding;
          encoding = offset;
          offset = length;
          length = swap
        }
        offset = Number(offset) || 0;
        var remaining = this.length - offset;
        if (!length) {
          length = remaining
        } else {
          length = Number(length);
          if (length > remaining) {
            length = remaining
          }
        }
        encoding = String(encoding || "utf8").toLowerCase();
        var ret;
        switch (encoding) {
          case "hex":
            ret = hexWrite(this, string, offset, length);
            break;
          case "utf8":
          case "utf-8":
            ret = utf8Write(this, string, offset, length);
            break;
          case "ascii":
            ret = asciiWrite(this, string, offset, length);
            break;
          case "binary":
            ret = binaryWrite(this, string, offset, length);
            break;
          case "base64":
            ret = base64Write(this, string, offset, length);
            break;
          case "ucs2":
          case "ucs-2":
          case "utf16le":
          case "utf-16le":
            ret = utf16leWrite(this, string, offset, length);
            break;
          default:
            throw new TypeError("Unknown encoding: " + encoding)
        }
        return ret
      };
      Buffer.prototype.toJSON = function() {
        return {
          type: "Buffer",
          data: Array.prototype.slice.call(this._arr || this, 0)
        }
      };

      function base64Slice(buf, start, end) {
        if (start === 0 && end === buf.length) {
          return base64.fromByteArray(buf)
        } else {
          return base64.fromByteArray(buf.slice(start, end))
        }
      }

      function utf8Slice(buf, start, end) {
        var res = "";
        var tmp = "";
        end = Math.min(buf.length, end);
        for (var i = start; i < end; i++) {
          if (buf[i] <= 127) {
            res += decodeUtf8Char(tmp) + String.fromCharCode(buf[i]);
            tmp = ""
          } else {
            tmp += "%" + buf[i].toString(16)
          }
        }
        return res + decodeUtf8Char(tmp)
      }

      function asciiSlice(buf, start, end) {
        var ret = "";
        end = Math.min(buf.length, end);
        for (var i = start; i < end; i++) {
          ret += String.fromCharCode(buf[i])
        }
        return ret
      }

      function binarySlice(buf, start, end) {
        return asciiSlice(buf, start, end)
      }

      function hexSlice(buf, start, end) {
        var len = buf.length;
        if (!start || start < 0) start = 0;
        if (!end || end < 0 || end > len) end = len;
        var out = "";
        for (var i = start; i < end; i++) {
          out += toHex(buf[i])
        }
        return out
      }

      function utf16leSlice(buf, start, end) {
        var bytes = buf.slice(start, end);
        var res = "";
        for (var i = 0; i < bytes.length; i += 2) {
          res += String.fromCharCode(bytes[i] + bytes[i + 1] * 256)
        }
        return res
      }
      Buffer.prototype.slice = function(start, end) {
        var len = this.length;
        start = ~~start;
        end = end === undefined ? len : ~~end;
        if (start < 0) {
          start += len;
          if (start < 0) start = 0
        } else if (start > len) {
          start = len
        }
        if (end < 0) {
          end += len;
          if (end < 0) end = 0
        } else if (end > len) {
          end = len
        }
        if (end < start) end = start;
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          return Buffer._augment(this.subarray(start, end))
        } else {
          var sliceLen = end - start;
          var newBuf = new Buffer(sliceLen, undefined, true);
          for (var i = 0; i < sliceLen; i++) {
            newBuf[i] = this[i + start]
          }
          return newBuf
        }
      };

      function checkOffset(offset, ext, length) {
        if (offset % 1 !== 0 || offset < 0) throw new RangeError("offset is not uint");
        if (offset + ext > length) throw new RangeError("Trying to access beyond buffer length")
      }
      Buffer.prototype.readUInt8 = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 1, this.length);
        return this[offset]
      };
      Buffer.prototype.readUInt16LE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 2, this.length);
        return this[offset] | this[offset + 1] << 8
      };
      Buffer.prototype.readUInt16BE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 2, this.length);
        return this[offset] << 8 | this[offset + 1]
      };
      Buffer.prototype.readUInt32LE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 4, this.length);
        return (this[offset] | this[offset + 1] << 8 | this[offset + 2] << 16) + this[offset + 3] * 16777216
      };
      Buffer.prototype.readUInt32BE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 4, this.length);
        return this[offset] * 16777216 + (this[offset + 1] << 16 | this[offset + 2] << 8 | this[offset + 3])
      };
      Buffer.prototype.readInt8 = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 1, this.length);
        if (!(this[offset] & 128)) return this[offset];
        return (255 - this[offset] + 1) * -1
      };
      Buffer.prototype.readInt16LE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 2, this.length);
        var val = this[offset] | this[offset + 1] << 8;
        return val & 32768 ? val | 4294901760 : val
      };
      Buffer.prototype.readInt16BE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 2, this.length);
        var val = this[offset + 1] | this[offset] << 8;
        return val & 32768 ? val | 4294901760 : val
      };
      Buffer.prototype.readInt32LE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 4, this.length);
        return this[offset] | this[offset + 1] << 8 | this[offset + 2] << 16 | this[offset + 3] << 24
      };
      Buffer.prototype.readInt32BE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 4, this.length);
        return this[offset] << 24 | this[offset + 1] << 16 | this[offset + 2] << 8 | this[offset + 3]
      };
      Buffer.prototype.readFloatLE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 4, this.length);
        return ieee754.read(this, offset, true, 23, 4)
      };
      Buffer.prototype.readFloatBE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 4, this.length);
        return ieee754.read(this, offset, false, 23, 4)
      };
      Buffer.prototype.readDoubleLE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 8, this.length);
        return ieee754.read(this, offset, true, 52, 8)
      };
      Buffer.prototype.readDoubleBE = function(offset, noAssert) {
        if (!noAssert) checkOffset(offset, 8, this.length);
        return ieee754.read(this, offset, false, 52, 8)
      };

      function checkInt(buf, value, offset, ext, max, min) {
        if (!Buffer.isBuffer(buf)) throw new TypeError("buffer must be a Buffer instance");
        if (value > max || value < min) throw new TypeError("value is out of bounds");
        if (offset + ext > buf.length) throw new TypeError("index out of range")
      }
      Buffer.prototype.writeUInt8 = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 1, 255, 0);
        if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value);
        this[offset] = value;
        return offset + 1
      };

      function objectWriteUInt16(buf, value, offset, littleEndian) {
        if (value < 0) value = 65535 + value + 1;
        for (var i = 0, j = Math.min(buf.length - offset, 2); i < j; i++) {
          buf[offset + i] = (value & 255 << 8 * (littleEndian ? i : 1 - i)) >>> (littleEndian ? i : 1 - i) * 8
        }
      }
      Buffer.prototype.writeUInt16LE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 2, 65535, 0);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value;
          this[offset + 1] = value >>> 8
        } else objectWriteUInt16(this, value, offset, true);
        return offset + 2
      };
      Buffer.prototype.writeUInt16BE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 2, 65535, 0);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value >>> 8;
          this[offset + 1] = value
        } else objectWriteUInt16(this, value, offset, false);
        return offset + 2
      };

      function objectWriteUInt32(buf, value, offset, littleEndian) {
        if (value < 0) value = 4294967295 + value + 1;
        for (var i = 0, j = Math.min(buf.length - offset, 4); i < j; i++) {
          buf[offset + i] = value >>> (littleEndian ? i : 3 - i) * 8 & 255
        }
      }
      Buffer.prototype.writeUInt32LE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 4, 4294967295, 0);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset + 3] = value >>> 24;
          this[offset + 2] = value >>> 16;
          this[offset + 1] = value >>> 8;
          this[offset] = value
        } else objectWriteUInt32(this, value, offset, true);
        return offset + 4
      };
      Buffer.prototype.writeUInt32BE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 4, 4294967295, 0);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value >>> 24;
          this[offset + 1] = value >>> 16;
          this[offset + 2] = value >>> 8;
          this[offset + 3] = value
        } else objectWriteUInt32(this, value, offset, false);
        return offset + 4
      };
      Buffer.prototype.writeInt8 = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 1, 127, -128);
        if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value);
        if (value < 0) value = 255 + value + 1;
        this[offset] = value;
        return offset + 1
      };
      Buffer.prototype.writeInt16LE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 2, 32767, -32768);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value;
          this[offset + 1] = value >>> 8
        } else objectWriteUInt16(this, value, offset, true);
        return offset + 2
      };
      Buffer.prototype.writeInt16BE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 2, 32767, -32768);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value >>> 8;
          this[offset + 1] = value
        } else objectWriteUInt16(this, value, offset, false);
        return offset + 2
      };
      Buffer.prototype.writeInt32LE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 4, 2147483647, -2147483648);
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value;
          this[offset + 1] = value >>> 8;
          this[offset + 2] = value >>> 16;
          this[offset + 3] = value >>> 24
        } else objectWriteUInt32(this, value, offset, true);
        return offset + 4
      };
      Buffer.prototype.writeInt32BE = function(value, offset, noAssert) {
        value = +value;
        offset = offset >>> 0;
        if (!noAssert) checkInt(this, value, offset, 4, 2147483647, -2147483648);
        if (value < 0) value = 4294967295 + value + 1;
        if (Buffer.TYPED_ARRAY_SUPPORT) {
          this[offset] = value >>> 24;
          this[offset + 1] = value >>> 16;
          this[offset + 2] = value >>> 8;
          this[offset + 3] = value
        } else objectWriteUInt32(this, value, offset, false);
        return offset + 4
      };

      function checkIEEE754(buf, value, offset, ext, max, min) {
        if (value > max || value < min) throw new TypeError("value is out of bounds");
        if (offset + ext > buf.length) throw new TypeError("index out of range")
      }

      function writeFloat(buf, value, offset, littleEndian, noAssert) {
        if (!noAssert) checkIEEE754(buf, value, offset, 4, 3.4028234663852886e38, -3.4028234663852886e38);
        ieee754.write(buf, value, offset, littleEndian, 23, 4);
        return offset + 4
      }
      Buffer.prototype.writeFloatLE = function(value, offset, noAssert) {
        return writeFloat(this, value, offset, true, noAssert)
      };
      Buffer.prototype.writeFloatBE = function(value, offset, noAssert) {
        return writeFloat(this, value, offset, false, noAssert)
      };

      function writeDouble(buf, value, offset, littleEndian, noAssert) {
        if (!noAssert) checkIEEE754(buf, value, offset, 8, 1.7976931348623157e308, -1.7976931348623157e308);
        ieee754.write(buf, value, offset, littleEndian, 52, 8);
        return offset + 8
      }
      Buffer.prototype.writeDoubleLE = function(value, offset, noAssert) {
        return writeDouble(this, value, offset, true, noAssert)
      };
      Buffer.prototype.writeDoubleBE = function(value, offset, noAssert) {
        return writeDouble(this, value, offset, false, noAssert)
      };
      Buffer.prototype.copy = function(target, target_start, start, end) {
        var source = this;
        if (!start) start = 0;
        if (!end && end !== 0) end = this.length;
        if (!target_start) target_start = 0;
        if (end === start) return;
        if (target.length === 0 || source.length === 0) return;
        if (end < start) throw new TypeError("sourceEnd < sourceStart");
        if (target_start < 0 || target_start >= target.length) throw new TypeError("targetStart out of bounds");
        if (start < 0 || start >= source.length) throw new TypeError("sourceStart out of bounds");
        if (end < 0 || end > source.length) throw new TypeError("sourceEnd out of bounds");
        if (end > this.length) end = this.length;
        if (target.length - target_start < end - start) end = target.length - target_start + start;
        var len = end - start;
        if (len < 1e3 || !Buffer.TYPED_ARRAY_SUPPORT) {
          for (var i = 0; i < len; i++) {
            target[i + target_start] = this[i + start]
          }
        } else {
          target._set(this.subarray(start, start + len), target_start)
        }
      };
      Buffer.prototype.fill = function(value, start, end) {
        if (!value) value = 0;
        if (!start) start = 0;
        if (!end) end = this.length;
        if (end < start) throw new TypeError("end < start");
        if (end === start) return;
        if (this.length === 0) return;
        if (start < 0 || start >= this.length) throw new TypeError("start out of bounds");
        if (end < 0 || end > this.length) throw new TypeError("end out of bounds");
        var i;
        if (typeof value === "number") {
          for (i = start; i < end; i++) {
            this[i] = value
          }
        } else {
          var bytes = utf8ToBytes(value.toString());
          var len = bytes.length;
          for (i = start; i < end; i++) {
            this[i] = bytes[i % len]
          }
        }
        return this
      };
      Buffer.prototype.toArrayBuffer = function() {
        if (typeof Uint8Array !== "undefined") {
          if (Buffer.TYPED_ARRAY_SUPPORT) {
            return new Buffer(this).buffer
          } else {
            var buf = new Uint8Array(this.length);
            for (var i = 0, len = buf.length; i < len; i += 1) {
              buf[i] = this[i]
            }
            return buf.buffer
          }
        } else {
          throw new TypeError("Buffer.toArrayBuffer not supported in this browser")
        }
      };
      var BP = Buffer.prototype;
      Buffer._augment = function(arr) {
        arr.constructor = Buffer;
        arr._isBuffer = true;
        arr._get = arr.get;
        arr._set = arr.set;
        arr.get = BP.get;
        arr.set = BP.set;
        arr.write = BP.write;
        arr.toString = BP.toString;
        arr.toLocaleString = BP.toString;
        arr.toJSON = BP.toJSON;
        arr.equals = BP.equals;
        arr.compare = BP.compare;
        arr.copy = BP.copy;
        arr.slice = BP.slice;
        arr.readUInt8 = BP.readUInt8;
        arr.readUInt16LE = BP.readUInt16LE;
        arr.readUInt16BE = BP.readUInt16BE;
        arr.readUInt32LE = BP.readUInt32LE;
        arr.readUInt32BE = BP.readUInt32BE;
        arr.readInt8 = BP.readInt8;
        arr.readInt16LE = BP.readInt16LE;
        arr.readInt16BE = BP.readInt16BE;
        arr.readInt32LE = BP.readInt32LE;
        arr.readInt32BE = BP.readInt32BE;
        arr.readFloatLE = BP.readFloatLE;
        arr.readFloatBE = BP.readFloatBE;
        arr.readDoubleLE = BP.readDoubleLE;
        arr.readDoubleBE = BP.readDoubleBE;
        arr.writeUInt8 = BP.writeUInt8;
        arr.writeUInt16LE = BP.writeUInt16LE;
        arr.writeUInt16BE = BP.writeUInt16BE;
        arr.writeUInt32LE = BP.writeUInt32LE;
        arr.writeUInt32BE = BP.writeUInt32BE;
        arr.writeInt8 = BP.writeInt8;
        arr.writeInt16LE = BP.writeInt16LE;
        arr.writeInt16BE = BP.writeInt16BE;
        arr.writeInt32LE = BP.writeInt32LE;
        arr.writeInt32BE = BP.writeInt32BE;
        arr.writeFloatLE = BP.writeFloatLE;
        arr.writeFloatBE = BP.writeFloatBE;
        arr.writeDoubleLE = BP.writeDoubleLE;
        arr.writeDoubleBE = BP.writeDoubleBE;
        arr.fill = BP.fill;
        arr.inspect = BP.inspect;
        arr.toArrayBuffer = BP.toArrayBuffer;
        return arr
      };
      var INVALID_BASE64_RE = /[^+\/0-9A-z]/g;

      function base64clean(str) {
        str = stringtrim(str).replace(INVALID_BASE64_RE, "");
        while (str.length % 4 !== 0) {
          str = str + "="
        }
        return str
      }

      function stringtrim(str) {
        if (str.trim) return str.trim();
        return str.replace(/^\s+|\s+$/g, "")
      }

      function isArrayish(subject) {
        return isArray(subject) || Buffer.isBuffer(subject) || subject && typeof subject === "object" && typeof subject.length === "number"
      }

      function toHex(n) {
        if (n < 16) return "0" + n.toString(16);
        return n.toString(16)
      }

      function utf8ToBytes(str) {
        var byteArray = [];
        for (var i = 0; i < str.length; i++) {
          var b = str.charCodeAt(i);
          if (b <= 127) {
            byteArray.push(b)
          } else {
            var start = i;
            if (b >= 55296 && b <= 57343) i++;
            var h = encodeURIComponent(str.slice(start, i + 1)).substr(1).split("%");
            for (var j = 0; j < h.length; j++) {
              byteArray.push(parseInt(h[j], 16))
            }
          }
        }
        return byteArray
      }

      function asciiToBytes(str) {
        var byteArray = [];
        for (var i = 0; i < str.length; i++) {
          byteArray.push(str.charCodeAt(i) & 255)
        }
        return byteArray
      }

      function utf16leToBytes(str) {
        var c, hi, lo;
        var byteArray = [];
        for (var i = 0; i < str.length; i++) {
          c = str.charCodeAt(i);
          hi = c >> 8;
          lo = c % 256;
          byteArray.push(lo);
          byteArray.push(hi)
        }
        return byteArray
      }

      function base64ToBytes(str) {
        return base64.toByteArray(str)
      }

      function blitBuffer(src, dst, offset, length, unitSize) {
        if (unitSize) length -= length % unitSize;
        for (var i = 0; i < length; i++) {
          if (i + offset >= dst.length || i >= src.length) break;
          dst[i + offset] = src[i]
        }
        return i
      }

      function decodeUtf8Char(str) {
        try {
          return decodeURIComponent(str)
        } catch (err) {
          return String.fromCharCode(65533)
        }
      }
    }, {
      "base64-js": 8,
      ieee754: 9,
      "is-array": 10
    }],
    8: [function(require, module, exports) {
      var lookup = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      (function(exports) {
        "use strict";
        var Arr = typeof Uint8Array !== "undefined" ? Uint8Array : Array;
        var PLUS = "+".charCodeAt(0);
        var SLASH = "/".charCodeAt(0);
        var NUMBER = "0".charCodeAt(0);
        var LOWER = "a".charCodeAt(0);
        var UPPER = "A".charCodeAt(0);

        function decode(elt) {
          var code = elt.charCodeAt(0);
          if (code === PLUS) return 62;
          if (code === SLASH) return 63;
          if (code < NUMBER) return -1;
          if (code < NUMBER + 10) return code - NUMBER + 26 + 26;
          if (code < UPPER + 26) return code - UPPER;
          if (code < LOWER + 26) return code - LOWER + 26
        }

        function b64ToByteArray(b64) {
          var i, j, l, tmp, placeHolders, arr;
          if (b64.length % 4 > 0) {
            throw new Error("Invalid string. Length must be a multiple of 4")
          }
          var len = b64.length;
          placeHolders = "=" === b64.charAt(len - 2) ? 2 : "=" === b64.charAt(len - 1) ? 1 : 0;
          arr = new Arr(b64.length * 3 / 4 - placeHolders);
          l = placeHolders > 0 ? b64.length - 4 : b64.length;
          var L = 0;

          function push(v) {
            arr[L++] = v
          }
          for (i = 0, j = 0; i < l; i += 4, j += 3) {
            tmp = decode(b64.charAt(i)) << 18 | decode(b64.charAt(i + 1)) << 12 | decode(b64.charAt(i + 2)) << 6 | decode(b64.charAt(i + 3));
            push((tmp & 16711680) >> 16);
            push((tmp & 65280) >> 8);
            push(tmp & 255)
          }
          if (placeHolders === 2) {
            tmp = decode(b64.charAt(i)) << 2 | decode(b64.charAt(i + 1)) >> 4;
            push(tmp & 255)
          } else if (placeHolders === 1) {
            tmp = decode(b64.charAt(i)) << 10 | decode(b64.charAt(i + 1)) << 4 | decode(b64.charAt(i + 2)) >> 2;
            push(tmp >> 8 & 255);
            push(tmp & 255)
          }
          return arr
        }

        function uint8ToBase64(uint8) {
          var i, extraBytes = uint8.length % 3,
              output = "",
              temp, length;

          function encode(num) {
            return lookup.charAt(num)
          }

          function tripletToBase64(num) {
            return encode(num >> 18 & 63) + encode(num >> 12 & 63) + encode(num >> 6 & 63) + encode(num & 63)
          }
          for (i = 0, length = uint8.length - extraBytes; i < length; i += 3) {
            temp = (uint8[i] << 16) + (uint8[i + 1] << 8) + uint8[i + 2];
            output += tripletToBase64(temp)
          }
          switch (extraBytes) {
            case 1:
              temp = uint8[uint8.length - 1];
              output += encode(temp >> 2);
              output += encode(temp << 4 & 63);
              output += "==";
              break;
            case 2:
              temp = (uint8[uint8.length - 2] << 8) + uint8[uint8.length - 1];
              output += encode(temp >> 10);
              output += encode(temp >> 4 & 63);
              output += encode(temp << 2 & 63);
              output += "=";
              break
          }
          return output
        }
        exports.toByteArray = b64ToByteArray;
        exports.fromByteArray = uint8ToBase64
      })(typeof exports === "undefined" ? this.base64js = {} : exports)
    }, {}],
    9: [function(require, module, exports) {
      exports.read = function(buffer, offset, isLE, mLen, nBytes) {
        var e, m, eLen = nBytes * 8 - mLen - 1,
            eMax = (1 << eLen) - 1,
            eBias = eMax >> 1,
            nBits = -7,
            i = isLE ? nBytes - 1 : 0,
            d = isLE ? -1 : 1,
            s = buffer[offset + i];
        i += d;
        e = s & (1 << -nBits) - 1;
        s >>= -nBits;
        nBits += eLen;
        for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8);
        m = e & (1 << -nBits) - 1;
        e >>= -nBits;
        nBits += mLen;
        for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8);
        if (e === 0) {
          e = 1 - eBias
        } else if (e === eMax) {
          return m ? NaN : (s ? -1 : 1) * Infinity
        } else {
          m = m + Math.pow(2, mLen);
          e = e - eBias
        }
        return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
      };
      exports.write = function(buffer, value, offset, isLE, mLen, nBytes) {
        var e, m, c, eLen = nBytes * 8 - mLen - 1,
            eMax = (1 << eLen) - 1,
            eBias = eMax >> 1,
            rt = mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0,
            i = isLE ? 0 : nBytes - 1,
            d = isLE ? 1 : -1,
            s = value < 0 || value === 0 && 1 / value < 0 ? 1 : 0;
        value = Math.abs(value);
        if (isNaN(value) || value === Infinity) {
          m = isNaN(value) ? 1 : 0;
          e = eMax
        } else {
          e = Math.floor(Math.log(value) / Math.LN2);
          if (value * (c = Math.pow(2, -e)) < 1) {
            e--;
            c *= 2
          }
          if (e + eBias >= 1) {
            value += rt / c
          } else {
            value += rt * Math.pow(2, 1 - eBias)
          }
          if (value * c >= 2) {
            e++;
            c /= 2
          }
          if (e + eBias >= eMax) {
            m = 0;
            e = eMax
          } else if (e + eBias >= 1) {
            m = (value * c - 1) * Math.pow(2, mLen);
            e = e + eBias
          } else {
            m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen);
            e = 0
          }
        }
        for (; mLen >= 8; buffer[offset + i] = m & 255, i += d, m /= 256, mLen -= 8);
        e = e << mLen | m;
        eLen += mLen;
        for (; eLen > 0; buffer[offset + i] = e & 255, i += d, e /= 256, eLen -= 8);
        buffer[offset + i - d] |= s * 128
      }
    }, {}],
    10: [function(require, module, exports) {
      var isArray = Array.isArray;
      var str = Object.prototype.toString;
      module.exports = isArray || function(val) {
            return !!val && "[object Array]" == str.call(val)
          }
    }, {}],
    11: [function(require, module, exports) {
      function EventEmitter() {
        this._events = this._events || {};
        this._maxListeners = this._maxListeners || undefined
      }
      module.exports = EventEmitter;
      EventEmitter.EventEmitter = EventEmitter;
      EventEmitter.prototype._events = undefined;
      EventEmitter.prototype._maxListeners = undefined;
      EventEmitter.defaultMaxListeners = 10;
      EventEmitter.prototype.setMaxListeners = function(n) {
        if (!isNumber(n) || n < 0 || isNaN(n)) throw TypeError("n must be a positive number");
        this._maxListeners = n;
        return this
      };
      EventEmitter.prototype.emit = function(type) {
        var er, handler, len, args, i, listeners;
        if (!this._events) this._events = {};
        if (type === "error") {
          if (!this._events.error || isObject(this._events.error) && !this._events.error.length) {
            er = arguments[1];
            if (er instanceof Error) {
              throw er
            }
            throw TypeError('Uncaught, unspecified "error" event.')
          }
        }
        handler = this._events[type];
        if (isUndefined(handler)) return false;
        if (isFunction(handler)) {
          switch (arguments.length) {
            case 1:
              handler.call(this);
              break;
            case 2:
              handler.call(this, arguments[1]);
              break;
            case 3:
              handler.call(this, arguments[1], arguments[2]);
              break;
            default:
              len = arguments.length;
              args = new Array(len - 1);
              for (i = 1; i < len; i++) args[i - 1] = arguments[i];
              handler.apply(this, args)
          }
        } else if (isObject(handler)) {
          len = arguments.length;
          args = new Array(len - 1);
          for (i = 1; i < len; i++) args[i - 1] = arguments[i];
          listeners = handler.slice();
          len = listeners.length;
          for (i = 0; i < len; i++) listeners[i].apply(this, args)
        }
        return true
      };
      EventEmitter.prototype.addListener = function(type, listener) {
        var m;
        if (!isFunction(listener)) throw TypeError("listener must be a function");
        if (!this._events) this._events = {};
        if (this._events.newListener) this.emit("newListener", type, isFunction(listener.listener) ? listener.listener : listener);
        if (!this._events[type]) this._events[type] = listener;
        else if (isObject(this._events[type])) this._events[type].push(listener);
        else this._events[type] = [this._events[type], listener];
        if (isObject(this._events[type]) && !this._events[type].warned) {
          var m;
          if (!isUndefined(this._maxListeners)) {
            m = this._maxListeners
          } else {
            m = EventEmitter.defaultMaxListeners
          }
          if (m && m > 0 && this._events[type].length > m) {
            this._events[type].warned = true;
            console.error("(node) warning: possible EventEmitter memory " + "leak detected. %d listeners added. " + "Use emitter.setMaxListeners() to increase limit.", this._events[type].length);
            if (typeof console.trace === "function") {
              console.trace()
            }
          }
        }
        return this
      };
      EventEmitter.prototype.on = EventEmitter.prototype.addListener;
      EventEmitter.prototype.once = function(type, listener) {
        if (!isFunction(listener)) throw TypeError("listener must be a function");
        var fired = false;

        function g() {
          this.removeListener(type, g);
          if (!fired) {
            fired = true;
            listener.apply(this, arguments)
          }
        }
        g.listener = listener;
        this.on(type, g);
        return this
      };
      EventEmitter.prototype.removeListener = function(type, listener) {
        var list, position, length, i;
        if (!isFunction(listener)) throw TypeError("listener must be a function");
        if (!this._events || !this._events[type]) return this;
        list = this._events[type];
        length = list.length;
        position = -1;
        if (list === listener || isFunction(list.listener) && list.listener === listener) {
          delete this._events[type];
          if (this._events.removeListener) this.emit("removeListener", type, listener)
        } else if (isObject(list)) {
          for (i = length; i-- > 0;) {
            if (list[i] === listener || list[i].listener && list[i].listener === listener) {
              position = i;
              break
            }
          }
          if (position < 0) return this;
          if (list.length === 1) {
            list.length = 0;
            delete this._events[type]
          } else {
            list.splice(position, 1)
          }
          if (this._events.removeListener) this.emit("removeListener", type, listener)
        }
        return this
      };
      EventEmitter.prototype.removeAllListeners = function(type) {
        var key, listeners;
        if (!this._events) return this;
        if (!this._events.removeListener) {
          if (arguments.length === 0) this._events = {};
          else if (this._events[type]) delete this._events[type];
          return this
        }
        if (arguments.length === 0) {
          for (key in this._events) {
            if (key === "removeListener") continue;
            this.removeAllListeners(key)
          }
          this.removeAllListeners("removeListener");
          this._events = {};
          return this
        }
        listeners = this._events[type];
        if (isFunction(listeners)) {
          this.removeListener(type, listeners)
        } else {
          while (listeners.length) this.removeListener(type, listeners[listeners.length - 1])
        }
        delete this._events[type];
        return this
      };
      EventEmitter.prototype.listeners = function(type) {
        var ret;
        if (!this._events || !this._events[type]) ret = [];
        else if (isFunction(this._events[type])) ret = [this._events[type]];
        else ret = this._events[type].slice();
        return ret
      };
      EventEmitter.listenerCount = function(emitter, type) {
        var ret;
        if (!emitter._events || !emitter._events[type]) ret = 0;
        else if (isFunction(emitter._events[type])) ret = 1;
        else ret = emitter._events[type].length;
        return ret
      };

      function isFunction(arg) {
        return typeof arg === "function"
      }

      function isNumber(arg) {
        return typeof arg === "number"
      }

      function isObject(arg) {
        return typeof arg === "object" && arg !== null
      }

      function isUndefined(arg) {
        return arg === void 0
      }
    }, {}],
    12: [function(require, module, exports) {
      if (typeof Object.create === "function") {
        module.exports = function inherits(ctor, superCtor) {
          ctor.super_ = superCtor;
          ctor.prototype = Object.create(superCtor.prototype, {
            constructor: {
              value: ctor,
              enumerable: false,
              writable: true,
              configurable: true
            }
          })
        }
      } else {
        module.exports = function inherits(ctor, superCtor) {
          ctor.super_ = superCtor;
          var TempCtor = function() {};
          TempCtor.prototype = superCtor.prototype;
          ctor.prototype = new TempCtor;
          ctor.prototype.constructor = ctor
        }
      }
    }, {}],
    13: [function(require, module, exports) {
      module.exports = Array.isArray || function(arr) {
            return Object.prototype.toString.call(arr) == "[object Array]"
          }
    }, {}],
    14: [function(require, module, exports) {
      var process = module.exports = {};
      process.nextTick = function() {
        var canSetImmediate = typeof window !== "undefined" && window.setImmediate;
        var canPost = typeof window !== "undefined" && window.postMessage && window.addEventListener;
        if (canSetImmediate) {
          return function(f) {
            return window.setImmediate(f)
          }
        }
        if (canPost) {
          var queue = [];
          window.addEventListener("message", function(ev) {
            var source = ev.source;
            if ((source === window || source === null) && ev.data === "process-tick") {
              ev.stopPropagation();
              if (queue.length > 0) {
                var fn = queue.shift();
                fn()
              }
            }
          }, true);
          return function nextTick(fn) {
            queue.push(fn);
            window.postMessage("process-tick", "*")
          }
        }
        return function nextTick(fn) {
          setTimeout(fn, 0)
        }
      }();
      process.title = "browser";
      process.browser = true;
      process.env = {};
      process.argv = [];

      function noop() {}
      process.on = noop;
      process.addListener = noop;
      process.once = noop;
      process.off = noop;
      process.removeListener = noop;
      process.removeAllListeners = noop;
      process.emit = noop;
      process.binding = function(name) {
        throw new Error("process.binding is not supported")
      };
      process.cwd = function() {
        return "/"
      };
      process.chdir = function(dir) {
        throw new Error("process.chdir is not supported")
      }
    }, {}],
    15: [function(require, module, exports) {
      module.exports = require("./lib/_stream_duplex.js")
    }, {
      "./lib/_stream_duplex.js": 16
    }],
    16: [function(require, module, exports) {
      (function(process) {
        module.exports = Duplex;
        var objectKeys = Object.keys || function(obj) {
              var keys = [];
              for (var key in obj) keys.push(key);
              return keys
            };
        var util = require("core-util-is");
        util.inherits = require("inherits");
        var Readable = require("./_stream_readable");
        var Writable = require("./_stream_writable");
        util.inherits(Duplex, Readable);
        forEach(objectKeys(Writable.prototype), function(method) {
          if (!Duplex.prototype[method]) Duplex.prototype[method] = Writable.prototype[method]
        });

        function Duplex(options) {
          if (!(this instanceof Duplex)) return new Duplex(options);
          Readable.call(this, options);
          Writable.call(this, options);
          if (options && options.readable === false) this.readable = false;
          if (options && options.writable === false) this.writable = false;
          this.allowHalfOpen = true;
          if (options && options.allowHalfOpen === false) this.allowHalfOpen = false;
          this.once("end", onend)
        }

        function onend() {
          if (this.allowHalfOpen || this._writableState.ended) return;
          process.nextTick(this.end.bind(this))
        }

        function forEach(xs, f) {
          for (var i = 0, l = xs.length; i < l; i++) {
            f(xs[i], i)
          }
        }
      }).call(this, require("_process"))
    }, {
      "./_stream_readable": 18,
      "./_stream_writable": 20,
      _process: 14,
      "core-util-is": 21,
      inherits: 12
    }],
    17: [function(require, module, exports) {
      module.exports = PassThrough;
      var Transform = require("./_stream_transform");
      var util = require("core-util-is");
      util.inherits = require("inherits");
      util.inherits(PassThrough, Transform);

      function PassThrough(options) {
        if (!(this instanceof PassThrough)) return new PassThrough(options);
        Transform.call(this, options)
      }
      PassThrough.prototype._transform = function(chunk, encoding, cb) {
        cb(null, chunk)
      }
    }, {
      "./_stream_transform": 19,
      "core-util-is": 21,
      inherits: 12
    }],
    18: [function(require, module, exports) {
      (function(process) {
        module.exports = Readable;
        var isArray = require("isarray");
        var Buffer = require("buffer").Buffer;
        Readable.ReadableState = ReadableState;
        var EE = require("events").EventEmitter;
        if (!EE.listenerCount) EE.listenerCount = function(emitter, type) {
          return emitter.listeners(type).length
        };
        var Stream = require("stream");
        var util = require("core-util-is");
        util.inherits = require("inherits");
        var StringDecoder;
        util.inherits(Readable, Stream);

        function ReadableState(options, stream) {
          options = options || {};
          var hwm = options.highWaterMark;
          this.highWaterMark = hwm || hwm === 0 ? hwm : 16 * 1024;
          this.highWaterMark = ~~this.highWaterMark;
          this.buffer = [];
          this.length = 0;
          this.pipes = null;
          this.pipesCount = 0;
          this.flowing = false;
          this.ended = false;
          this.endEmitted = false;
          this.reading = false;
          this.calledRead = false;
          this.sync = true;
          this.needReadable = false;
          this.emittedReadable = false;
          this.readableListening = false;
          this.objectMode = !!options.objectMode;
          this.defaultEncoding = options.defaultEncoding || "utf8";
          this.ranOut = false;
          this.awaitDrain = 0;
          this.readingMore = false;
          this.decoder = null;
          this.encoding = null;
          if (options.encoding) {
            if (!StringDecoder) StringDecoder = require("string_decoder/").StringDecoder;
            this.decoder = new StringDecoder(options.encoding);
            this.encoding = options.encoding
          }
        }

        function Readable(options) {
          if (!(this instanceof Readable)) return new Readable(options);
          this._readableState = new ReadableState(options, this);
          this.readable = true;
          Stream.call(this)
        }
        Readable.prototype.push = function(chunk, encoding) {
          var state = this._readableState;
          if (typeof chunk === "string" && !state.objectMode) {
            encoding = encoding || state.defaultEncoding;
            if (encoding !== state.encoding) {
              chunk = new Buffer(chunk, encoding);
              encoding = ""
            }
          }
          return readableAddChunk(this, state, chunk, encoding, false)
        };
        Readable.prototype.unshift = function(chunk) {
          var state = this._readableState;
          return readableAddChunk(this, state, chunk, "", true)
        };

        function readableAddChunk(stream, state, chunk, encoding, addToFront) {
          var er = chunkInvalid(state, chunk);
          if (er) {
            stream.emit("error", er)
          } else if (chunk === null || chunk === undefined) {
            state.reading = false;
            if (!state.ended) onEofChunk(stream, state)
          } else if (state.objectMode || chunk && chunk.length > 0) {
            if (state.ended && !addToFront) {
              var e = new Error("stream.push() after EOF");
              stream.emit("error", e)
            } else if (state.endEmitted && addToFront) {
              var e = new Error("stream.unshift() after end event");
              stream.emit("error", e)
            } else {
              if (state.decoder && !addToFront && !encoding) chunk = state.decoder.write(chunk);
              state.length += state.objectMode ? 1 : chunk.length;
              if (addToFront) {
                state.buffer.unshift(chunk)
              } else {
                state.reading = false;
                state.buffer.push(chunk)
              }
              if (state.needReadable) emitReadable(stream);
              maybeReadMore(stream, state)
            }
          } else if (!addToFront) {
            state.reading = false
          }
          return needMoreData(state)
        }

        function needMoreData(state) {
          return !state.ended && (state.needReadable || state.length < state.highWaterMark || state.length === 0)
        }
        Readable.prototype.setEncoding = function(enc) {
          if (!StringDecoder) StringDecoder = require("string_decoder/").StringDecoder;
          this._readableState.decoder = new StringDecoder(enc);
          this._readableState.encoding = enc
        };
        var MAX_HWM = 8388608;

        function roundUpToNextPowerOf2(n) {
          if (n >= MAX_HWM) {
            n = MAX_HWM
          } else {
            n--;
            for (var p = 1; p < 32; p <<= 1) n |= n >> p;
            n++
          }
          return n
        }

        function howMuchToRead(n, state) {
          if (state.length === 0 && state.ended) return 0;
          if (state.objectMode) return n === 0 ? 0 : 1;
          if (n === null || isNaN(n)) {
            if (state.flowing && state.buffer.length) return state.buffer[0].length;
            else return state.length
          }
          if (n <= 0) return 0;
          if (n > state.highWaterMark) state.highWaterMark = roundUpToNextPowerOf2(n);
          if (n > state.length) {
            if (!state.ended) {
              state.needReadable = true;
              return 0
            } else return state.length
          }
          return n
        }
        Readable.prototype.read = function(n) {
          var state = this._readableState;
          state.calledRead = true;
          var nOrig = n;
          var ret;
          if (typeof n !== "number" || n > 0) state.emittedReadable = false;
          if (n === 0 && state.needReadable && (state.length >= state.highWaterMark || state.ended)) {
            emitReadable(this);
            return null
          }
          n = howMuchToRead(n, state);
          if (n === 0 && state.ended) {
            ret = null;
            if (state.length > 0 && state.decoder) {
              ret = fromList(n, state);
              state.length -= ret.length
            }
            if (state.length === 0) endReadable(this);
            return ret
          }
          var doRead = state.needReadable;
          if (state.length - n <= state.highWaterMark) doRead = true;
          if (state.ended || state.reading) doRead = false;
          if (doRead) {
            state.reading = true;
            state.sync = true;
            if (state.length === 0) state.needReadable = true;
            this._read(state.highWaterMark);
            state.sync = false
          }
          if (doRead && !state.reading) n = howMuchToRead(nOrig, state);
          if (n > 0) ret = fromList(n, state);
          else ret = null;
          if (ret === null) {
            state.needReadable = true;
            n = 0
          }
          state.length -= n;
          if (state.length === 0 && !state.ended) state.needReadable = true;
          if (state.ended && !state.endEmitted && state.length === 0) endReadable(this);
          return ret
        };

        function chunkInvalid(state, chunk) {
          var er = null;
          if (!Buffer.isBuffer(chunk) && "string" !== typeof chunk && chunk !== null && chunk !== undefined && !state.objectMode) {
            er = new TypeError("Invalid non-string/buffer chunk")
          }
          return er
        }

        function onEofChunk(stream, state) {
          if (state.decoder && !state.ended) {
            var chunk = state.decoder.end();
            if (chunk && chunk.length) {
              state.buffer.push(chunk);
              state.length += state.objectMode ? 1 : chunk.length
            }
          }
          state.ended = true;
          if (state.length > 0) emitReadable(stream);
          else endReadable(stream)
        }

        function emitReadable(stream) {
          var state = stream._readableState;
          state.needReadable = false;
          if (state.emittedReadable) return;
          state.emittedReadable = true;
          if (state.sync) process.nextTick(function() {
            emitReadable_(stream)
          });
          else emitReadable_(stream)
        }

        function emitReadable_(stream) {
          stream.emit("readable")
        }

        function maybeReadMore(stream, state) {
          if (!state.readingMore) {
            state.readingMore = true;
            process.nextTick(function() {
              maybeReadMore_(stream, state)
            })
          }
        }

        function maybeReadMore_(stream, state) {
          var len = state.length;
          while (!state.reading && !state.flowing && !state.ended && state.length < state.highWaterMark) {
            stream.read(0);
            if (len === state.length) break;
            else len = state.length
          }
          state.readingMore = false
        }
        Readable.prototype._read = function(n) {
          this.emit("error", new Error("not implemented"))
        };
        Readable.prototype.pipe = function(dest, pipeOpts) {
          var src = this;
          var state = this._readableState;
          switch (state.pipesCount) {
            case 0:
              state.pipes = dest;
              break;
            case 1:
              state.pipes = [state.pipes, dest];
              break;
            default:
              state.pipes.push(dest);
              break
          }
          state.pipesCount += 1;
          var doEnd = (!pipeOpts || pipeOpts.end !== false) && dest !== process.stdout && dest !== process.stderr;
          var endFn = doEnd ? onend : cleanup;
          if (state.endEmitted) process.nextTick(endFn);
          else src.once("end", endFn);
          dest.on("unpipe", onunpipe);

          function onunpipe(readable) {
            if (readable !== src) return;
            cleanup()
          }

          function onend() {
            dest.end()
          }
          var ondrain = pipeOnDrain(src);
          dest.on("drain", ondrain);

          function cleanup() {
            dest.removeListener("close", onclose);
            dest.removeListener("finish", onfinish);
            dest.removeListener("drain", ondrain);
            dest.removeListener("error", onerror);
            dest.removeListener("unpipe", onunpipe);
            src.removeListener("end", onend);
            src.removeListener("end", cleanup);
            if (!dest._writableState || dest._writableState.needDrain) ondrain()
          }

          function onerror(er) {
            unpipe();
            dest.removeListener("error", onerror);
            if (EE.listenerCount(dest, "error") === 0) dest.emit("error", er)
          }
          if (!dest._events || !dest._events.error) dest.on("error", onerror);
          else if (isArray(dest._events.error)) dest._events.error.unshift(onerror);
          else dest._events.error = [onerror, dest._events.error];

          function onclose() {
            dest.removeListener("finish", onfinish);
            unpipe()
          }
          dest.once("close", onclose);

          function onfinish() {
            dest.removeListener("close", onclose);
            unpipe()
          }
          dest.once("finish", onfinish);

          function unpipe() {
            src.unpipe(dest)
          }
          dest.emit("pipe", src);
          if (!state.flowing) {
            this.on("readable", pipeOnReadable);
            state.flowing = true;
            process.nextTick(function() {
              flow(src)
            })
          }
          return dest
        };

        function pipeOnDrain(src) {
          return function() {
            var dest = this;
            var state = src._readableState;
            state.awaitDrain--;
            if (state.awaitDrain === 0) flow(src)
          }
        }

        function flow(src) {
          var state = src._readableState;
          var chunk;
          state.awaitDrain = 0;

          function write(dest, i, list) {
            var written = dest.write(chunk);
            if (false === written) {
              state.awaitDrain++
            }
          }
          while (state.pipesCount && null !== (chunk = src.read())) {
            if (state.pipesCount === 1) write(state.pipes, 0, null);
            else forEach(state.pipes, write);
            src.emit("data", chunk);
            if (state.awaitDrain > 0) return
          }
          if (state.pipesCount === 0) {
            state.flowing = false;
            if (EE.listenerCount(src, "data") > 0) emitDataEvents(src);
            return
          }
          state.ranOut = true
        }

        function pipeOnReadable() {
          if (this._readableState.ranOut) {
            this._readableState.ranOut = false;
            flow(this)
          }
        }
        Readable.prototype.unpipe = function(dest) {
          var state = this._readableState;
          if (state.pipesCount === 0) return this;
          if (state.pipesCount === 1) {
            if (dest && dest !== state.pipes) return this;
            if (!dest) dest = state.pipes;
            state.pipes = null;
            state.pipesCount = 0;
            this.removeListener("readable", pipeOnReadable);
            state.flowing = false;
            if (dest) dest.emit("unpipe", this);
            return this
          }
          if (!dest) {
            var dests = state.pipes;
            var len = state.pipesCount;
            state.pipes = null;
            state.pipesCount = 0;
            this.removeListener("readable", pipeOnReadable);
            state.flowing = false;
            for (var i = 0; i < len; i++) dests[i].emit("unpipe", this);
            return this
          }
          var i = indexOf(state.pipes, dest);
          if (i === -1) return this;
          state.pipes.splice(i, 1);
          state.pipesCount -= 1;
          if (state.pipesCount === 1) state.pipes = state.pipes[0];
          dest.emit("unpipe", this);
          return this
        };
        Readable.prototype.on = function(ev, fn) {
          var res = Stream.prototype.on.call(this, ev, fn);
          if (ev === "data" && !this._readableState.flowing) emitDataEvents(this);
          if (ev === "readable" && this.readable) {
            var state = this._readableState;
            if (!state.readableListening) {
              state.readableListening = true;
              state.emittedReadable = false;
              state.needReadable = true;
              if (!state.reading) {
                this.read(0)
              } else if (state.length) {
                emitReadable(this, state)
              }
            }
          }
          return res
        };
        Readable.prototype.addListener = Readable.prototype.on;
        Readable.prototype.resume = function() {
          emitDataEvents(this);
          this.read(0);
          this.emit("resume")
        };
        Readable.prototype.pause = function() {
          emitDataEvents(this, true);
          this.emit("pause")
        };

        function emitDataEvents(stream, startPaused) {
          var state = stream._readableState;
          if (state.flowing) {
            throw new Error("Cannot switch to old mode now.")
          }
          var paused = startPaused || false;
          var readable = false;
          stream.readable = true;
          stream.pipe = Stream.prototype.pipe;
          stream.on = stream.addListener = Stream.prototype.on;
          stream.on("readable", function() {
            readable = true;
            var c;
            while (!paused && null !== (c = stream.read())) stream.emit("data", c);
            if (c === null) {
              readable = false;
              stream._readableState.needReadable = true
            }
          });
          stream.pause = function() {
            paused = true;
            this.emit("pause")
          };
          stream.resume = function() {
            paused = false;
            if (readable) process.nextTick(function() {
              stream.emit("readable")
            });
            else this.read(0);
            this.emit("resume")
          };
          stream.emit("readable")
        }
        Readable.prototype.wrap = function(stream) {
          var state = this._readableState;
          var paused = false;
          var self = this;
          stream.on("end", function() {
            if (state.decoder && !state.ended) {
              var chunk = state.decoder.end();
              if (chunk && chunk.length) self.push(chunk)
            }
            self.push(null)
          });
          stream.on("data", function(chunk) {
            if (state.decoder) chunk = state.decoder.write(chunk);
            if (state.objectMode && (chunk === null || chunk === undefined)) return;
            else if (!state.objectMode && (!chunk || !chunk.length)) return;
            var ret = self.push(chunk);
            if (!ret) {
              paused = true;
              stream.pause()
            }
          });
          for (var i in stream) {
            if (typeof stream[i] === "function" && typeof this[i] === "undefined") {
              this[i] = function(method) {
                return function() {
                  return stream[method].apply(stream, arguments)
                }
              }(i)
            }
          }
          var events = ["error", "close", "destroy", "pause", "resume"];
          forEach(events, function(ev) {
            stream.on(ev, self.emit.bind(self, ev))
          });
          self._read = function(n) {
            if (paused) {
              paused = false;
              stream.resume()
            }
          };
          return self
        };
        Readable._fromList = fromList;

        function fromList(n, state) {
          var list = state.buffer;
          var length = state.length;
          var stringMode = !!state.decoder;
          var objectMode = !!state.objectMode;
          var ret;
          if (list.length === 0) return null;
          if (length === 0) ret = null;
          else if (objectMode) ret = list.shift();
          else if (!n || n >= length) {
            if (stringMode) ret = list.join("");
            else ret = Buffer.concat(list, length);
            list.length = 0
          } else {
            if (n < list[0].length) {
              var buf = list[0];
              ret = buf.slice(0, n);
              list[0] = buf.slice(n)
            } else if (n === list[0].length) {
              ret = list.shift()
            } else {
              if (stringMode) ret = "";
              else ret = new Buffer(n);
              var c = 0;
              for (var i = 0, l = list.length; i < l && c < n; i++) {
                var buf = list[0];
                var cpy = Math.min(n - c, buf.length);
                if (stringMode) ret += buf.slice(0, cpy);
                else buf.copy(ret, c, 0, cpy);
                if (cpy < buf.length) list[0] = buf.slice(cpy);
                else list.shift();
                c += cpy
              }
            }
          }
          return ret
        }

        function endReadable(stream) {
          var state = stream._readableState;
          if (state.length > 0) throw new Error("endReadable called on non-empty stream");
          if (!state.endEmitted && state.calledRead) {
            state.ended = true;
            process.nextTick(function() {
              if (!state.endEmitted && state.length === 0) {
                state.endEmitted = true;
                stream.readable = false;
                stream.emit("end")
              }
            })
          }
        }

        function forEach(xs, f) {
          for (var i = 0, l = xs.length; i < l; i++) {
            f(xs[i], i)
          }
        }

        function indexOf(xs, x) {
          for (var i = 0, l = xs.length; i < l; i++) {
            if (xs[i] === x) return i
          }
          return -1
        }
      }).call(this, require("_process"))
    }, {
      _process: 14,
      buffer: 7,
      "core-util-is": 21,
      events: 11,
      inherits: 12,
      isarray: 13,
      stream: 26,
      "string_decoder/": 27
    }],
    19: [function(require, module, exports) {
      module.exports = Transform;
      var Duplex = require("./_stream_duplex");
      var util = require("core-util-is");
      util.inherits = require("inherits");
      util.inherits(Transform, Duplex);

      function TransformState(options, stream) {
        this.afterTransform = function(er, data) {
          return afterTransform(stream, er, data)
        };
        this.needTransform = false;
        this.transforming = false;
        this.writecb = null;
        this.writechunk = null
      }

      function afterTransform(stream, er, data) {
        var ts = stream._transformState;
        ts.transforming = false;
        var cb = ts.writecb;
        if (!cb) return stream.emit("error", new Error("no writecb in Transform class"));
        ts.writechunk = null;
        ts.writecb = null;
        if (data !== null && data !== undefined) stream.push(data);
        if (cb) cb(er);
        var rs = stream._readableState;
        rs.reading = false;
        if (rs.needReadable || rs.length < rs.highWaterMark) {
          stream._read(rs.highWaterMark)
        }
      }

      function Transform(options) {
        if (!(this instanceof Transform)) return new Transform(options);
        Duplex.call(this, options);
        var ts = this._transformState = new TransformState(options, this);
        var stream = this;
        this._readableState.needReadable = true;
        this._readableState.sync = false;
        this.once("finish", function() {
          if ("function" === typeof this._flush) this._flush(function(er) {
            done(stream, er)
          });
          else done(stream)
        })
      }
      Transform.prototype.push = function(chunk, encoding) {
        this._transformState.needTransform = false;
        return Duplex.prototype.push.call(this, chunk, encoding)
      };
      Transform.prototype._transform = function(chunk, encoding, cb) {
        throw new Error("not implemented")
      };
      Transform.prototype._write = function(chunk, encoding, cb) {
        var ts = this._transformState;
        ts.writecb = cb;
        ts.writechunk = chunk;
        ts.writeencoding = encoding;
        if (!ts.transforming) {
          var rs = this._readableState;
          if (ts.needTransform || rs.needReadable || rs.length < rs.highWaterMark) this._read(rs.highWaterMark)
        }
      };
      Transform.prototype._read = function(n) {
        var ts = this._transformState;
        if (ts.writechunk !== null && ts.writecb && !ts.transforming) {
          ts.transforming = true;
          this._transform(ts.writechunk, ts.writeencoding, ts.afterTransform)
        } else {
          ts.needTransform = true
        }
      };

      function done(stream, er) {
        if (er) return stream.emit("error", er);
        var ws = stream._writableState;
        var rs = stream._readableState;
        var ts = stream._transformState;
        if (ws.length) throw new Error("calling transform done when ws.length != 0");
        if (ts.transforming) throw new Error("calling transform done when still transforming");
        return stream.push(null)
      }
    }, {
      "./_stream_duplex": 16,
      "core-util-is": 21,
      inherits: 12
    }],
    20: [function(require, module, exports) {
      (function(process) {
        module.exports = Writable;
        var Buffer = require("buffer").Buffer;
        Writable.WritableState = WritableState;
        var util = require("core-util-is");
        util.inherits = require("inherits");
        var Stream = require("stream");
        util.inherits(Writable, Stream);

        function WriteReq(chunk, encoding, cb) {
          this.chunk = chunk;
          this.encoding = encoding;
          this.callback = cb
        }

        function WritableState(options, stream) {
          options = options || {};
          var hwm = options.highWaterMark;
          this.highWaterMark = hwm || hwm === 0 ? hwm : 16 * 1024;
          this.objectMode = !!options.objectMode;
          this.highWaterMark = ~~this.highWaterMark;
          this.needDrain = false;
          this.ending = false;
          this.ended = false;
          this.finished = false;
          var noDecode = options.decodeStrings === false;
          this.decodeStrings = !noDecode;
          this.defaultEncoding = options.defaultEncoding || "utf8";
          this.length = 0;
          this.writing = false;
          this.sync = true;
          this.bufferProcessing = false;
          this.onwrite = function(er) {
            onwrite(stream, er)
          };
          this.writecb = null;
          this.writelen = 0;
          this.buffer = [];
          this.errorEmitted = false
        }

        function Writable(options) {
          var Duplex = require("./_stream_duplex");
          if (!(this instanceof Writable) && !(this instanceof Duplex)) return new Writable(options);
          this._writableState = new WritableState(options, this);
          this.writable = true;
          Stream.call(this)
        }
        Writable.prototype.pipe = function() {
          this.emit("error", new Error("Cannot pipe. Not readable."))
        };

        function writeAfterEnd(stream, state, cb) {
          var er = new Error("write after end");
          stream.emit("error", er);
          process.nextTick(function() {
            cb(er)
          })
        }

        function validChunk(stream, state, chunk, cb) {
          var valid = true;
          if (!Buffer.isBuffer(chunk) && "string" !== typeof chunk && chunk !== null && chunk !== undefined && !state.objectMode) {
            var er = new TypeError("Invalid non-string/buffer chunk");
            stream.emit("error", er);
            process.nextTick(function() {
              cb(er)
            });
            valid = false
          }
          return valid
        }
        Writable.prototype.write = function(chunk, encoding, cb) {
          var state = this._writableState;
          var ret = false;
          if (typeof encoding === "function") {
            cb = encoding;
            encoding = null
          }
          if (Buffer.isBuffer(chunk)) encoding = "buffer";
          else if (!encoding) encoding = state.defaultEncoding;
          if (typeof cb !== "function") cb = function() {};
          if (state.ended) writeAfterEnd(this, state, cb);
          else if (validChunk(this, state, chunk, cb)) ret = writeOrBuffer(this, state, chunk, encoding, cb);
          return ret
        };

        function decodeChunk(state, chunk, encoding) {
          if (!state.objectMode && state.decodeStrings !== false && typeof chunk === "string") {
            chunk = new Buffer(chunk, encoding)
          }
          return chunk
        }

        function writeOrBuffer(stream, state, chunk, encoding, cb) {
          chunk = decodeChunk(state, chunk, encoding);
          if (Buffer.isBuffer(chunk)) encoding = "buffer";
          var len = state.objectMode ? 1 : chunk.length;
          state.length += len;
          var ret = state.length < state.highWaterMark;
          if (!ret) state.needDrain = true;
          if (state.writing) state.buffer.push(new WriteReq(chunk, encoding, cb));
          else doWrite(stream, state, len, chunk, encoding, cb);
          return ret
        }

        function doWrite(stream, state, len, chunk, encoding, cb) {
          state.writelen = len;
          state.writecb = cb;
          state.writing = true;
          state.sync = true;
          stream._write(chunk, encoding, state.onwrite);
          state.sync = false
        }

        function onwriteError(stream, state, sync, er, cb) {
          if (sync) process.nextTick(function() {
            cb(er)
          });
          else cb(er);
          stream._writableState.errorEmitted = true;
          stream.emit("error", er)
        }

        function onwriteStateUpdate(state) {
          state.writing = false;
          state.writecb = null;
          state.length -= state.writelen;
          state.writelen = 0
        }

        function onwrite(stream, er) {
          var state = stream._writableState;
          var sync = state.sync;
          var cb = state.writecb;
          onwriteStateUpdate(state);
          if (er) onwriteError(stream, state, sync, er, cb);
          else {
            var finished = needFinish(stream, state);
            if (!finished && !state.bufferProcessing && state.buffer.length) clearBuffer(stream, state);
            if (sync) {
              process.nextTick(function() {
                afterWrite(stream, state, finished, cb)
              })
            } else {
              afterWrite(stream, state, finished, cb)
            }
          }
        }

        function afterWrite(stream, state, finished, cb) {
          if (!finished) onwriteDrain(stream, state);
          cb();
          if (finished) finishMaybe(stream, state)
        }

        function onwriteDrain(stream, state) {
          if (state.length === 0 && state.needDrain) {
            state.needDrain = false;
            stream.emit("drain")
          }
        }

        function clearBuffer(stream, state) {
          state.bufferProcessing = true;
          for (var c = 0; c < state.buffer.length; c++) {
            var entry = state.buffer[c];
            var chunk = entry.chunk;
            var encoding = entry.encoding;
            var cb = entry.callback;
            var len = state.objectMode ? 1 : chunk.length;
            doWrite(stream, state, len, chunk, encoding, cb);
            if (state.writing) {
              c++;
              break
            }
          }
          state.bufferProcessing = false;
          if (c < state.buffer.length) state.buffer = state.buffer.slice(c);
          else state.buffer.length = 0
        }
        Writable.prototype._write = function(chunk, encoding, cb) {
          cb(new Error("not implemented"))
        };
        Writable.prototype.end = function(chunk, encoding, cb) {
          var state = this._writableState;
          if (typeof chunk === "function") {
            cb = chunk;
            chunk = null;
            encoding = null
          } else if (typeof encoding === "function") {
            cb = encoding;
            encoding = null
          }
          if (typeof chunk !== "undefined" && chunk !== null) this.write(chunk, encoding);
          if (!state.ending && !state.finished) endWritable(this, state, cb)
        };

        function needFinish(stream, state) {
          return state.ending && state.length === 0 && !state.finished && !state.writing
        }

        function finishMaybe(stream, state) {
          var need = needFinish(stream, state);
          if (need) {
            state.finished = true;
            stream.emit("finish")
          }
          return need
        }

        function endWritable(stream, state, cb) {
          state.ending = true;
          finishMaybe(stream, state);
          if (cb) {
            if (state.finished) process.nextTick(cb);
            else stream.once("finish", cb)
          }
          state.ended = true
        }
      }).call(this, require("_process"))
    }, {
      "./_stream_duplex": 16,
      _process: 14,
      buffer: 7,
      "core-util-is": 21,
      inherits: 12,
      stream: 26
    }],
    21: [function(require, module, exports) {
      (function(Buffer) {
        function isArray(ar) {
          return Array.isArray(ar)
        }
        exports.isArray = isArray;

        function isBoolean(arg) {
          return typeof arg === "boolean"
        }
        exports.isBoolean = isBoolean;

        function isNull(arg) {
          return arg === null
        }
        exports.isNull = isNull;

        function isNullOrUndefined(arg) {
          return arg == null
        }
        exports.isNullOrUndefined = isNullOrUndefined;

        function isNumber(arg) {
          return typeof arg === "number"
        }
        exports.isNumber = isNumber;

        function isString(arg) {
          return typeof arg === "string"
        }
        exports.isString = isString;

        function isSymbol(arg) {
          return typeof arg === "symbol"
        }
        exports.isSymbol = isSymbol;

        function isUndefined(arg) {
          return arg === void 0
        }
        exports.isUndefined = isUndefined;

        function isRegExp(re) {
          return isObject(re) && objectToString(re) === "[object RegExp]"
        }
        exports.isRegExp = isRegExp;

        function isObject(arg) {
          return typeof arg === "object" && arg !== null
        }
        exports.isObject = isObject;

        function isDate(d) {
          return isObject(d) && objectToString(d) === "[object Date]"
        }
        exports.isDate = isDate;

        function isError(e) {
          return isObject(e) && (objectToString(e) === "[object Error]" || e instanceof Error)
        }
        exports.isError = isError;

        function isFunction(arg) {
          return typeof arg === "function"
        }
        exports.isFunction = isFunction;

        function isPrimitive(arg) {
          return arg === null || typeof arg === "boolean" || typeof arg === "number" || typeof arg === "string" || typeof arg === "symbol" || typeof arg === "undefined"
        }
        exports.isPrimitive = isPrimitive;

        function isBuffer(arg) {
          return Buffer.isBuffer(arg)
        }
        exports.isBuffer = isBuffer;

        function objectToString(o) {
          return Object.prototype.toString.call(o)
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    22: [function(require, module, exports) {
      module.exports = require("./lib/_stream_passthrough.js")
    }, {
      "./lib/_stream_passthrough.js": 17
    }],
    23: [function(require, module, exports) {
      var Stream = require("stream");
      exports = module.exports = require("./lib/_stream_readable.js");
      exports.Stream = Stream;
      exports.Readable = exports;
      exports.Writable = require("./lib/_stream_writable.js");
      exports.Duplex = require("./lib/_stream_duplex.js");
      exports.Transform = require("./lib/_stream_transform.js");
      exports.PassThrough = require("./lib/_stream_passthrough.js")
    }, {
      "./lib/_stream_duplex.js": 16,
      "./lib/_stream_passthrough.js": 17,
      "./lib/_stream_readable.js": 18,
      "./lib/_stream_transform.js": 19,
      "./lib/_stream_writable.js": 20,
      stream: 26
    }],
    24: [function(require, module, exports) {
      module.exports = require("./lib/_stream_transform.js")
    }, {
      "./lib/_stream_transform.js": 19
    }],
    25: [function(require, module, exports) {
      module.exports = require("./lib/_stream_writable.js")
    }, {
      "./lib/_stream_writable.js": 20
    }],
    26: [function(require, module, exports) {
      module.exports = Stream;
      var EE = require("events").EventEmitter;
      var inherits = require("inherits");
      inherits(Stream, EE);
      Stream.Readable = require("readable-stream/readable.js");
      Stream.Writable = require("readable-stream/writable.js");
      Stream.Duplex = require("readable-stream/duplex.js");
      Stream.Transform = require("readable-stream/transform.js");
      Stream.PassThrough = require("readable-stream/passthrough.js");
      Stream.Stream = Stream;

      function Stream() {
        EE.call(this)
      }
      Stream.prototype.pipe = function(dest, options) {
        var source = this;

        function ondata(chunk) {
          if (dest.writable) {
            if (false === dest.write(chunk) && source.pause) {
              source.pause()
            }
          }
        }
        source.on("data", ondata);

        function ondrain() {
          if (source.readable && source.resume) {
            source.resume()
          }
        }
        dest.on("drain", ondrain);
        if (!dest._isStdio && (!options || options.end !== false)) {
          source.on("end", onend);
          source.on("close", onclose)
        }
        var didOnEnd = false;

        function onend() {
          if (didOnEnd) return;
          didOnEnd = true;
          dest.end()
        }

        function onclose() {
          if (didOnEnd) return;
          didOnEnd = true;
          if (typeof dest.destroy === "function") dest.destroy()
        }

        function onerror(er) {
          cleanup();
          if (EE.listenerCount(this, "error") === 0) {
            throw er
          }
        }
        source.on("error", onerror);
        dest.on("error", onerror);

        function cleanup() {
          source.removeListener("data", ondata);
          dest.removeListener("drain", ondrain);
          source.removeListener("end", onend);
          source.removeListener("close", onclose);
          source.removeListener("error", onerror);
          dest.removeListener("error", onerror);
          source.removeListener("end", cleanup);
          source.removeListener("close", cleanup);
          dest.removeListener("close", cleanup)
        }
        source.on("end", cleanup);
        source.on("close", cleanup);
        dest.on("close", cleanup);
        dest.emit("pipe", source);
        return dest
      }
    }, {
      events: 11,
      inherits: 12,
      "readable-stream/duplex.js": 15,
      "readable-stream/passthrough.js": 22,
      "readable-stream/readable.js": 23,
      "readable-stream/transform.js": 24,
      "readable-stream/writable.js": 25
    }],
    27: [function(require, module, exports) {
      var Buffer = require("buffer").Buffer;
      var isBufferEncoding = Buffer.isEncoding || function(encoding) {
            switch (encoding && encoding.toLowerCase()) {
              case "hex":
              case "utf8":
              case "utf-8":
              case "ascii":
              case "binary":
              case "base64":
              case "ucs2":
              case "ucs-2":
              case "utf16le":
              case "utf-16le":
              case "raw":
                return true;
              default:
                return false
            }
          };

      function assertEncoding(encoding) {
        if (encoding && !isBufferEncoding(encoding)) {
          throw new Error("Unknown encoding: " + encoding)
        }
      }
      var StringDecoder = exports.StringDecoder = function(encoding) {
        this.encoding = (encoding || "utf8").toLowerCase().replace(/[-_]/, "");
        assertEncoding(encoding);
        switch (this.encoding) {
          case "utf8":
            this.surrogateSize = 3;
            break;
          case "ucs2":
          case "utf16le":
            this.surrogateSize = 2;
            this.detectIncompleteChar = utf16DetectIncompleteChar;
            break;
          case "base64":
            this.surrogateSize = 3;
            this.detectIncompleteChar = base64DetectIncompleteChar;
            break;
          default:
            this.write = passThroughWrite;
            return
        }
        this.charBuffer = new Buffer(6);
        this.charReceived = 0;
        this.charLength = 0
      };
      StringDecoder.prototype.write = function(buffer) {
        var charStr = "";
        while (this.charLength) {
          var available = buffer.length >= this.charLength - this.charReceived ? this.charLength - this.charReceived : buffer.length;
          buffer.copy(this.charBuffer, this.charReceived, 0, available);
          this.charReceived += available;
          if (this.charReceived < this.charLength) {
            return ""
          }
          buffer = buffer.slice(available, buffer.length);
          charStr = this.charBuffer.slice(0, this.charLength).toString(this.encoding);
          var charCode = charStr.charCodeAt(charStr.length - 1);
          if (charCode >= 55296 && charCode <= 56319) {
            this.charLength += this.surrogateSize;
            charStr = "";
            continue
          }
          this.charReceived = this.charLength = 0;
          if (buffer.length === 0) {
            return charStr
          }
          break
        }
        this.detectIncompleteChar(buffer);
        var end = buffer.length;
        if (this.charLength) {
          buffer.copy(this.charBuffer, 0, buffer.length - this.charReceived, end);
          end -= this.charReceived
        }
        charStr += buffer.toString(this.encoding, 0, end);
        var end = charStr.length - 1;
        var charCode = charStr.charCodeAt(end);
        if (charCode >= 55296 && charCode <= 56319) {
          var size = this.surrogateSize;
          this.charLength += size;
          this.charReceived += size;
          this.charBuffer.copy(this.charBuffer, size, 0, size);
          buffer.copy(this.charBuffer, 0, 0, size);
          return charStr.substring(0, end)
        }
        return charStr
      };
      StringDecoder.prototype.detectIncompleteChar = function(buffer) {
        var i = buffer.length >= 3 ? 3 : buffer.length;
        for (; i > 0; i--) {
          var c = buffer[buffer.length - i];
          if (i == 1 && c >> 5 == 6) {
            this.charLength = 2;
            break
          }
          if (i <= 2 && c >> 4 == 14) {
            this.charLength = 3;
            break
          }
          if (i <= 3 && c >> 3 == 30) {
            this.charLength = 4;
            break
          }
        }
        this.charReceived = i
      };
      StringDecoder.prototype.end = function(buffer) {
        var res = "";
        if (buffer && buffer.length) res = this.write(buffer);
        if (this.charReceived) {
          var cr = this.charReceived;
          var buf = this.charBuffer;
          var enc = this.encoding;
          res += buf.slice(0, cr).toString(enc)
        }
        return res
      };

      function passThroughWrite(buffer) {
        return buffer.toString(this.encoding)
      }

      function utf16DetectIncompleteChar(buffer) {
        this.charReceived = buffer.length % 2;
        this.charLength = this.charReceived ? 2 : 0
      }

      function base64DetectIncompleteChar(buffer) {
        this.charReceived = buffer.length % 3;
        this.charLength = this.charReceived ? 3 : 0
      }
    }, {
      buffer: 7
    }],
    28: [function(require, module, exports) {
      module.exports = function isBuffer(arg) {
        return arg && typeof arg === "object" && typeof arg.copy === "function" && typeof arg.fill === "function" && typeof arg.readUInt8 === "function"
      }
    }, {}],
    29: [function(require, module, exports) {
      (function(process, global) {
        var formatRegExp = /%[sdj%]/g;
        exports.format = function(f) {
          if (!isString(f)) {
            var objects = [];
            for (var i = 0; i < arguments.length; i++) {
              objects.push(inspect(arguments[i]))
            }
            return objects.join(" ")
          }
          var i = 1;
          var args = arguments;
          var len = args.length;
          var str = String(f).replace(formatRegExp, function(x) {
            if (x === "%%") return "%";
            if (i >= len) return x;
            switch (x) {
              case "%s":
                return String(args[i++]);
              case "%d":
                return Number(args[i++]);
              case "%j":
                try {
                  return JSON.stringify(args[i++])
                } catch (_) {
                  return "[Circular]"
                }
              default:
                return x
            }
          });
          for (var x = args[i]; i < len; x = args[++i]) {
            if (isNull(x) || !isObject(x)) {
              str += " " + x
            } else {
              str += " " + inspect(x)
            }
          }
          return str
        };
        exports.deprecate = function(fn, msg) {
          if (isUndefined(global.process)) {
            return function() {
              return exports.deprecate(fn, msg).apply(this, arguments)
            }
          }
          if (process.noDeprecation === true) {
            return fn
          }
          var warned = false;

          function deprecated() {
            if (!warned) {
              if (process.throwDeprecation) {
                throw new Error(msg)
              } else if (process.traceDeprecation) {
                console.trace(msg)
              } else {
                console.error(msg)
              }
              warned = true
            }
            return fn.apply(this, arguments)
          }
          return deprecated
        };
        var debugs = {};
        var debugEnviron;
        exports.debuglog = function(set) {
          if (isUndefined(debugEnviron)) debugEnviron = process.env.NODE_DEBUG || "";
          set = set.toUpperCase();
          if (!debugs[set]) {
            if (new RegExp("\\b" + set + "\\b", "i").test(debugEnviron)) {
              var pid = process.pid;
              debugs[set] = function() {
                var msg = exports.format.apply(exports, arguments);
                console.error("%s %d: %s", set, pid, msg)
              }
            } else {
              debugs[set] = function() {}
            }
          }
          return debugs[set]
        };

        function inspect(obj, opts) {
          var ctx = {
            seen: [],
            stylize: stylizeNoColor
          };
          if (arguments.length >= 3) ctx.depth = arguments[2];
          if (arguments.length >= 4) ctx.colors = arguments[3];
          if (isBoolean(opts)) {
            ctx.showHidden = opts
          } else if (opts) {
            exports._extend(ctx, opts)
          }
          if (isUndefined(ctx.showHidden)) ctx.showHidden = false;
          if (isUndefined(ctx.depth)) ctx.depth = 2;
          if (isUndefined(ctx.colors)) ctx.colors = false;
          if (isUndefined(ctx.customInspect)) ctx.customInspect = true;
          if (ctx.colors) ctx.stylize = stylizeWithColor;
          return formatValue(ctx, obj, ctx.depth)
        }
        exports.inspect = inspect;
        inspect.colors = {
          bold: [1, 22],
          italic: [3, 23],
          underline: [4, 24],
          inverse: [7, 27],
          white: [37, 39],
          grey: [90, 39],
          black: [30, 39],
          blue: [34, 39],
          cyan: [36, 39],
          green: [32, 39],
          magenta: [35, 39],
          red: [31, 39],
          yellow: [33, 39]
        };
        inspect.styles = {
          special: "cyan",
          number: "yellow",
          "boolean": "yellow",
          undefined: "grey",
          "null": "bold",
          string: "green",
          date: "magenta",
          regexp: "red"
        };

        function stylizeWithColor(str, styleType) {
          var style = inspect.styles[styleType];
          if (style) {
            return "[" + inspect.colors[style][0] + "m" + str + "[" + inspect.colors[style][1] + "m"
          } else {
            return str
          }
        }

        function stylizeNoColor(str, styleType) {
          return str
        }

        function arrayToHash(array) {
          var hash = {};
          array.forEach(function(val, idx) {
            hash[val] = true
          });
          return hash
        }

        function formatValue(ctx, value, recurseTimes) {
          if (ctx.customInspect && value && isFunction(value.inspect) && value.inspect !== exports.inspect && !(value.constructor && value.constructor.prototype === value)) {
            var ret = value.inspect(recurseTimes, ctx);
            if (!isString(ret)) {
              ret = formatValue(ctx, ret, recurseTimes)
            }
            return ret
          }
          var primitive = formatPrimitive(ctx, value);
          if (primitive) {
            return primitive
          }
          var keys = Object.keys(value);
          var visibleKeys = arrayToHash(keys);
          if (ctx.showHidden) {
            keys = Object.getOwnPropertyNames(value)
          }
          if (isError(value) && (keys.indexOf("message") >= 0 || keys.indexOf("description") >= 0)) {
            return formatError(value)
          }
          if (keys.length === 0) {
            if (isFunction(value)) {
              var name = value.name ? ": " + value.name : "";
              return ctx.stylize("[Function" + name + "]", "special")
            }
            if (isRegExp(value)) {
              return ctx.stylize(RegExp.prototype.toString.call(value), "regexp")
            }
            if (isDate(value)) {
              return ctx.stylize(Date.prototype.toString.call(value), "date")
            }
            if (isError(value)) {
              return formatError(value)
            }
          }
          var base = "",
              array = false,
              braces = ["{", "}"];
          if (isArray(value)) {
            array = true;
            braces = ["[", "]"]
          }
          if (isFunction(value)) {
            var n = value.name ? ": " + value.name : "";
            base = " [Function" + n + "]"
          }
          if (isRegExp(value)) {
            base = " " + RegExp.prototype.toString.call(value)
          }
          if (isDate(value)) {
            base = " " + Date.prototype.toUTCString.call(value)
          }
          if (isError(value)) {
            base = " " + formatError(value)
          }
          if (keys.length === 0 && (!array || value.length == 0)) {
            return braces[0] + base + braces[1]
          }
          if (recurseTimes < 0) {
            if (isRegExp(value)) {
              return ctx.stylize(RegExp.prototype.toString.call(value), "regexp")
            } else {
              return ctx.stylize("[Object]", "special")
            }
          }
          ctx.seen.push(value);
          var output;
          if (array) {
            output = formatArray(ctx, value, recurseTimes, visibleKeys, keys)
          } else {
            output = keys.map(function(key) {
              return formatProperty(ctx, value, recurseTimes, visibleKeys, key, array)
            })
          }
          ctx.seen.pop();
          return reduceToSingleString(output, base, braces)
        }

        function formatPrimitive(ctx, value) {
          if (isUndefined(value)) return ctx.stylize("undefined", "undefined");
          if (isString(value)) {
            var simple = "'" + JSON.stringify(value).replace(/^"|"$/g, "").replace(/'/g, "\\'").replace(/\\"/g, '"') + "'";
            return ctx.stylize(simple, "string")
          }
          if (isNumber(value)) return ctx.stylize("" + value, "number");
          if (isBoolean(value)) return ctx.stylize("" + value, "boolean");
          if (isNull(value)) return ctx.stylize("null", "null")
        }

        function formatError(value) {
          return "[" + Error.prototype.toString.call(value) + "]"
        }

        function formatArray(ctx, value, recurseTimes, visibleKeys, keys) {
          var output = [];
          for (var i = 0, l = value.length; i < l; ++i) {
            if (hasOwnProperty(value, String(i))) {
              output.push(formatProperty(ctx, value, recurseTimes, visibleKeys, String(i), true))
            } else {
              output.push("")
            }
          }
          keys.forEach(function(key) {
            if (!key.match(/^\d+$/)) {
              output.push(formatProperty(ctx, value, recurseTimes, visibleKeys, key, true))
            }
          });
          return output
        }

        function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
          var name, str, desc;
          desc = Object.getOwnPropertyDescriptor(value, key) || {
                value: value[key]
              };
          if (desc.get) {
            if (desc.set) {
              str = ctx.stylize("[Getter/Setter]", "special")
            } else {
              str = ctx.stylize("[Getter]", "special")
            }
          } else {
            if (desc.set) {
              str = ctx.stylize("[Setter]", "special")
            }
          }
          if (!hasOwnProperty(visibleKeys, key)) {
            name = "[" + key + "]"
          }
          if (!str) {
            if (ctx.seen.indexOf(desc.value) < 0) {
              if (isNull(recurseTimes)) {
                str = formatValue(ctx, desc.value, null)
              } else {
                str = formatValue(ctx, desc.value, recurseTimes - 1)
              }
              if (str.indexOf("\n") > -1) {
                if (array) {
                  str = str.split("\n").map(function(line) {
                    return "  " + line
                  }).join("\n").substr(2)
                } else {
                  str = "\n" + str.split("\n").map(function(line) {
                        return "   " + line
                      }).join("\n")
                }
              }
            } else {
              str = ctx.stylize("[Circular]", "special")
            }
          }
          if (isUndefined(name)) {
            if (array && key.match(/^\d+$/)) {
              return str
            }
            name = JSON.stringify("" + key);
            if (name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)) {
              name = name.substr(1, name.length - 2);
              name = ctx.stylize(name, "name")
            } else {
              name = name.replace(/'/g, "\\'").replace(/\\"/g, '"').replace(/(^"|"$)/g, "'");
              name = ctx.stylize(name, "string")
            }
          }
          return name + ": " + str
        }

        function reduceToSingleString(output, base, braces) {
          var numLinesEst = 0;
          var length = output.reduce(function(prev, cur) {
            numLinesEst++;
            if (cur.indexOf("\n") >= 0) numLinesEst++;
            return prev + cur.replace(/\u001b\[\d\d?m/g, "").length + 1
          }, 0);
          if (length > 60) {
            return braces[0] + (base === "" ? "" : base + "\n ") + " " + output.join(",\n  ") + " " + braces[1]
          }
          return braces[0] + base + " " + output.join(", ") + " " + braces[1]
        }

        function isArray(ar) {
          return Array.isArray(ar)
        }
        exports.isArray = isArray;

        function isBoolean(arg) {
          return typeof arg === "boolean"
        }
        exports.isBoolean = isBoolean;

        function isNull(arg) {
          return arg === null
        }
        exports.isNull = isNull;

        function isNullOrUndefined(arg) {
          return arg == null
        }
        exports.isNullOrUndefined = isNullOrUndefined;

        function isNumber(arg) {
          return typeof arg === "number"
        }
        exports.isNumber = isNumber;

        function isString(arg) {
          return typeof arg === "string"
        }
        exports.isString = isString;

        function isSymbol(arg) {
          return typeof arg === "symbol"
        }
        exports.isSymbol = isSymbol;

        function isUndefined(arg) {
          return arg === void 0
        }
        exports.isUndefined = isUndefined;

        function isRegExp(re) {
          return isObject(re) && objectToString(re) === "[object RegExp]"
        }
        exports.isRegExp = isRegExp;

        function isObject(arg) {
          return typeof arg === "object" && arg !== null
        }
        exports.isObject = isObject;

        function isDate(d) {
          return isObject(d) && objectToString(d) === "[object Date]"
        }
        exports.isDate = isDate;

        function isError(e) {
          return isObject(e) && (objectToString(e) === "[object Error]" || e instanceof Error)
        }
        exports.isError = isError;

        function isFunction(arg) {
          return typeof arg === "function"
        }
        exports.isFunction = isFunction;

        function isPrimitive(arg) {
          return arg === null || typeof arg === "boolean" || typeof arg === "number" || typeof arg === "string" || typeof arg === "symbol" || typeof arg === "undefined"
        }
        exports.isPrimitive = isPrimitive;
        exports.isBuffer = require("./support/isBuffer");

        function objectToString(o) {
          return Object.prototype.toString.call(o)
        }

        function pad(n) {
          return n < 10 ? "0" + n.toString(10) : n.toString(10)
        }
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

        function timestamp() {
          var d = new Date;
          var time = [pad(d.getHours()), pad(d.getMinutes()), pad(d.getSeconds())].join(":");
          return [d.getDate(), months[d.getMonth()], time].join(" ")
        }
        exports.log = function() {
          console.log("%s - %s", timestamp(), exports.format.apply(exports, arguments))
        };
        exports.inherits = require("inherits");
        exports._extend = function(origin, add) {
          if (!add || !isObject(add)) return origin;
          var keys = Object.keys(add);
          var i = keys.length;
          while (i--) {
            origin[keys[i]] = add[keys[i]]
          }
          return origin
        };

        function hasOwnProperty(obj, prop) {
          return Object.prototype.hasOwnProperty.call(obj, prop)
        }
      }).call(this, require("_process"), typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {
      "./support/isBuffer": 28,
      _process: 14,
      inherits: 12
    }],
    30: [function(require, module, exports) {
      var indexOf = require("indexof");
      var Object_keys = function(obj) {
        if (Object.keys) return Object.keys(obj);
        else {
          var res = [];
          for (var key in obj) res.push(key);
          return res
        }
      };
      var forEach = function(xs, fn) {
        if (xs.forEach) return xs.forEach(fn);
        else
          for (var i = 0; i < xs.length; i++) {
            fn(xs[i], i, xs)
          }
      };
      var defineProp = function() {
        try {
          Object.defineProperty({}, "_", {});
          return function(obj, name, value) {
            Object.defineProperty(obj, name, {
              writable: true,
              enumerable: false,
              configurable: true,
              value: value
            })
          }
        } catch (e) {
          return function(obj, name, value) {
            obj[name] = value
          }
        }
      }();
      var globals = ["Array", "Boolean", "Date", "Error", "EvalError", "Function", "Infinity", "JSON", "Math", "NaN", "Number", "Object", "RangeError", "ReferenceError", "RegExp", "String", "SyntaxError", "TypeError", "URIError", "decodeURI", "decodeURIComponent", "encodeURI", "encodeURIComponent", "escape", "eval", "isFinite", "isNaN", "parseFloat", "parseInt", "undefined", "unescape"];

      function Context() {}
      Context.prototype = {};
      var Script = exports.Script = function NodeScript(code) {
        if (!(this instanceof Script)) return new Script(code);
        this.code = code
      };
      Script.prototype.runInContext = function(context) {
        if (!(context instanceof Context)) {
          throw new TypeError("needs a 'context' argument.")
        }
        var iframe = document.createElement("iframe");
        if (!iframe.style) iframe.style = {};
        iframe.style.display = "none";
        document.body.appendChild(iframe);
        var win = iframe.contentWindow;
        var wEval = win.eval,
            wExecScript = win.execScript;
        if (!wEval && wExecScript) {
          wExecScript.call(win, "null");
          wEval = win.eval
        }
        forEach(Object_keys(context), function(key) {
          win[key] = context[key]
        });
        forEach(globals, function(key) {
          if (context[key]) {
            win[key] = context[key]
          }
        });
        var winKeys = Object_keys(win);
        var res = wEval.call(win, this.code);
        forEach(Object_keys(win), function(key) {
          if (key in context || indexOf(winKeys, key) === -1) {
            context[key] = win[key]
          }
        });
        forEach(globals, function(key) {
          if (!(key in context)) {
            defineProp(context, key, win[key])
          }
        });
        document.body.removeChild(iframe);
        return res
      };
      Script.prototype.runInThisContext = function() {
        return eval(this.code)
      };
      Script.prototype.runInNewContext = function(context) {
        var ctx = Script.createContext(context);
        var res = this.runInContext(ctx);
        forEach(Object_keys(ctx), function(key) {
          context[key] = ctx[key]
        });
        return res
      };
      forEach(Object_keys(Script.prototype), function(name) {
        exports[name] = Script[name] = function(code) {
          var s = Script(code);
          return s[name].apply(s, [].slice.call(arguments, 1))
        }
      });
      exports.createScript = function(code) {
        return exports.Script(code)
      };
      exports.createContext = Script.createContext = function(context) {
        var copy = new Context;
        if (typeof context === "object") {
          forEach(Object_keys(context), function(key) {
            copy[key] = context[key]
          })
        }
        return copy
      }
    }, {
      indexof: 31
    }],
    31: [function(require, module, exports) {
      var indexOf = [].indexOf;
      module.exports = function(arr, obj) {
        if (indexOf) return arr.indexOf(obj);
        for (var i = 0; i < arr.length; ++i) {
          if (arr[i] === obj) return i
        }
        return -1
      }
    }, {}],
    32: [function(require, module, exports) {
      var ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
      var ALPHABET_MAP = {};
      for (var i = 0; i < ALPHABET.length; i++) {
        ALPHABET_MAP[ALPHABET.charAt(i)] = i
      }
      var BASE = 58;

      function encode(buffer) {
        if (buffer.length === 0) return "";
        var i, j, digits = [0];
        for (i = 0; i < buffer.length; i++) {
          for (j = 0; j < digits.length; j++) digits[j] <<= 8;
          digits[0] += buffer[i];
          var carry = 0;
          for (j = 0; j < digits.length; ++j) {
            digits[j] += carry;
            carry = digits[j] / BASE | 0;
            digits[j] %= BASE
          }
          while (carry) {
            digits.push(carry % BASE);
            carry = carry / BASE | 0
          }
        }
        for (i = 0; buffer[i] === 0 && i < buffer.length - 1; i++) digits.push(0);
        return digits.reverse().map(function(digit) {
          return ALPHABET[digit]
        }).join("")
      }

      function decode(string) {
        if (string.length === 0) return [];
        var i, j, bytes = [0];
        for (i = 0; i < string.length; i++) {
          var c = string[i];
          if (!(c in ALPHABET_MAP)) throw new Error("Non-base58 character");
          for (j = 0; j < bytes.length; j++) bytes[j] *= BASE;
          bytes[0] += ALPHABET_MAP[c];
          var carry = 0;
          for (j = 0; j < bytes.length; ++j) {
            bytes[j] += carry;
            carry = bytes[j] >> 8;
            bytes[j] &= 255
          }
          while (carry) {
            bytes.push(carry & 255);
            carry >>= 8
          }
        }
        for (i = 0; string[i] === "1" && i < string.length - 1; i++) bytes.push(0);
        return bytes.reverse()
      }
      module.exports = {
        encode: encode,
        decode: decode
      }
    }, {}],
    33: [function(require, module, exports) {
      (function(Buffer) {
        "use strict";
        var assert = require("assert");
        var base58 = require("bs58");
        var crypto = require("crypto");

        function sha256x2(buffer) {
          buffer = crypto.createHash("sha256").update(buffer).digest();
          return crypto.createHash("sha256").update(buffer).digest()
        }

        function encode(payload) {
          var checksum = sha256x2(payload).slice(0, 4);
          return base58.encode(Buffer.concat([payload, checksum]))
        }

        function decode(string) {
          var buffer = new Buffer(base58.decode(string));
          var payload = buffer.slice(0, -4);
          var checksum = buffer.slice(-4);
          var newChecksum = sha256x2(payload).slice(0, 4);
          assert.deepEqual(newChecksum, checksum, "Invalid checksum");
          return payload
        }
        module.exports = {
          encode: encode,
          decode: decode
        }
      }).call(this, require("buffer").Buffer)
    }, {
      assert: 5,
      bs58: 32,
      buffer: 7,
      crypto: 37
    }],
    34: [function(require, module, exports) {
      (function(Buffer) {
        "use strict";
        var createHash = require("sha.js");
        var md5 = require("./md5");
        var rmd160 = require("ripemd160");
        var Transform = require("stream").Transform;
        var inherits = require("util").inherits;
        module.exports = function(alg) {
          if ("md5" === alg) return new HashNoConstructor(md5);
          if ("rmd160" === alg) return new HashNoConstructor(rmd160);
          return new Hash(createHash(alg))
        };
        inherits(HashNoConstructor, Transform);

        function HashNoConstructor(hash) {
          Transform.call(this);
          this._hash = hash;
          this.buffers = []
        }
        HashNoConstructor.prototype._transform = function(data, _, done) {
          this.buffers.push(data);
          done()
        };
        HashNoConstructor.prototype._flush = function(done) {
          var buf = Buffer.concat(this.buffers);
          var r = this._hash(buf);
          this.buffers = null;
          this.push(r);
          done()
        };
        HashNoConstructor.prototype.update = function(data, enc) {
          this.write(data, enc);
          return this
        };
        HashNoConstructor.prototype.digest = function(enc) {
          this.end();
          var outData = new Buffer("");
          var chunk;
          while (chunk = this.read()) {
            outData = Buffer.concat([outData, chunk])
          }
          if (enc) {
            outData = outData.toString(enc)
          }
          return outData
        };
        inherits(Hash, Transform);

        function Hash(hash) {
          Transform.call(this);
          this._hash = hash
        }
        Hash.prototype._transform = function(data, _, done) {
          this._hash.update(data);
          done()
        };
        Hash.prototype._flush = function(done) {
          this.push(this._hash.digest());
          this._hash = null;
          done()
        };
        Hash.prototype.update = function(data, enc) {
          this.write(data, enc);
          return this
        };
        Hash.prototype.digest = function(enc) {
          this.end();
          var outData = new Buffer("");
          var chunk;
          while (chunk = this.read()) {
            outData = Buffer.concat([outData, chunk])
          }
          if (enc) {
            outData = outData.toString(enc)
          }
          return outData
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./md5": 38,
      buffer: 7,
      ripemd160: 143,
      "sha.js": 145,
      stream: 26,
      util: 29
    }],
    35: [function(require, module, exports) {
      (function(Buffer) {
        "use strict";
        var createHash = require("./create-hash");
        var Transform = require("stream").Transform;
        var inherits = require("util").inherits;
        var zeroBuffer = new Buffer(128);
        zeroBuffer.fill(0);
        module.exports = Hmac;
        inherits(Hmac, Transform);

        function Hmac(alg, key) {
          if (!(this instanceof Hmac)) return new Hmac(alg, key);
          Transform.call(this);
          this._opad = opad;
          this._alg = alg;
          var blocksize = alg === "sha512" || alg === "sha384" ? 128 : 64;
          key = this._key = !Buffer.isBuffer(key) ? new Buffer(key) : key;
          if (key.length > blocksize) {
            key = createHash(alg).update(key).digest()
          } else if (key.length < blocksize) {
            key = Buffer.concat([key, zeroBuffer], blocksize)
          }
          var ipad = this._ipad = new Buffer(blocksize);
          var opad = this._opad = new Buffer(blocksize);
          for (var i = 0; i < blocksize; i++) {
            ipad[i] = key[i] ^ 54;
            opad[i] = key[i] ^ 92
          }
          this._hash = createHash(alg).update(ipad)
        }
        Hmac.prototype.update = function(data, enc) {
          this.write(data, enc);
          return this
        };
        Hmac.prototype._transform = function(data, _, next) {
          this._hash.update(data);
          next()
        };
        Hmac.prototype._flush = function(next) {
          var h = this._hash.digest();
          this.push(createHash(this._alg).update(this._opad).update(h).digest());
          next()
        };
        Hmac.prototype.digest = function(enc) {
          this.end();
          var outData = new Buffer("");
          var chunk;
          while (chunk = this.read()) {
            outData = Buffer.concat([outData, chunk])
          }
          if (enc) {
            outData = outData.toString(enc)
          }
          return outData
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./create-hash": 34,
      buffer: 7,
      stream: 26,
      util: 29
    }],
    36: [function(require, module, exports) {
      (function(Buffer) {
        "use strict";
        var intSize = 4;
        var zeroBuffer = new Buffer(intSize);
        zeroBuffer.fill(0);
        var chrsz = 8;

        function toArray(buf, bigEndian) {
          if (buf.length % intSize !== 0) {
            var len = buf.length + (intSize - buf.length % intSize);
            buf = Buffer.concat([buf, zeroBuffer], len)
          }
          var arr = [];
          var fn = bigEndian ? buf.readInt32BE : buf.readInt32LE;
          for (var i = 0; i < buf.length; i += intSize) {
            arr.push(fn.call(buf, i))
          }
          return arr
        }

        function toBuffer(arr, size, bigEndian) {
          var buf = new Buffer(size);
          var fn = bigEndian ? buf.writeInt32BE : buf.writeInt32LE;
          for (var i = 0; i < arr.length; i++) {
            fn.call(buf, arr[i], i * 4, true)
          }
          return buf
        }

        function hash(buf, fn, hashSize, bigEndian) {
          if (!Buffer.isBuffer(buf)) buf = new Buffer(buf);
          var arr = fn(toArray(buf, bigEndian), buf.length * chrsz);
          return toBuffer(arr, hashSize, bigEndian)
        }
        module.exports = {
          hash: hash
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    37: [function(require, module, exports) {
      (function(Buffer) {
        "use strict";
        var rng = require("./rng");

        function error() {
          var m = [].slice.call(arguments).join(" ");
          throw new Error([m, "we accept pull requests", "http://github.com/dominictarr/crypto-browserify"].join("\n"))
        }
        exports.createHash = require("./create-hash");
        exports.createHmac = require("./create-hmac");
        exports.randomBytes = function(size, callback) {
          if (callback && callback.call) {
            try {
              callback.call(this, undefined, new Buffer(rng(size)))
            } catch (err) {
              callback(err)
            }
          } else {
            return new Buffer(rng(size))
          }
        };

        function each(a, f) {
          for (var i in a) f(a[i], i)
        }
        var hashes = ["sha1", "sha256", "sha512", "md5", "rmd160"].concat(Object.keys(require("browserify-sign/algos")));
        exports.getHashes = function() {
          return hashes
        };
        var p = require("./pbkdf2")(exports);
        exports.pbkdf2 = p.pbkdf2;
        exports.pbkdf2Sync = p.pbkdf2Sync;
        require("browserify-aes/inject")(exports, module.exports);
        require("browserify-sign/inject")(module.exports, exports);
        require("diffie-hellman/inject")(exports, module.exports);
        require("create-ecdh/inject")(module.exports, exports);
        each(["createCredentials", "publicEncrypt", "privateDecrypt"], function(name) {
          exports[name] = function() {
            error("sorry,", name, "is not implemented yet")
          }
        })
      }).call(this, require("buffer").Buffer)
    }, {
      "./create-hash": 34,
      "./create-hmac": 35,
      "./pbkdf2": 151,
      "./rng": 152,
      "browserify-aes/inject": 46,
      "browserify-sign/algos": 59,
      "browserify-sign/inject": 62,
      buffer: 7,
      "create-ecdh/inject": 112,
      "diffie-hellman/inject": 137
    }],
    38: [function(require, module, exports) {
      "use strict";
      var helpers = require("./helpers");

      function core_md5(x, len) {
        x[len >> 5] |= 128 << len % 32;
        x[(len + 64 >>> 9 << 4) + 14] = len;
        var a = 1732584193;
        var b = -271733879;
        var c = -1732584194;
        var d = 271733878;
        for (var i = 0; i < x.length; i += 16) {
          var olda = a;
          var oldb = b;
          var oldc = c;
          var oldd = d;
          a = md5_ff(a, b, c, d, x[i + 0], 7, -680876936);
          d = md5_ff(d, a, b, c, x[i + 1], 12, -389564586);
          c = md5_ff(c, d, a, b, x[i + 2], 17, 606105819);
          b = md5_ff(b, c, d, a, x[i + 3], 22, -1044525330);
          a = md5_ff(a, b, c, d, x[i + 4], 7, -176418897);
          d = md5_ff(d, a, b, c, x[i + 5], 12, 1200080426);
          c = md5_ff(c, d, a, b, x[i + 6], 17, -1473231341);
          b = md5_ff(b, c, d, a, x[i + 7], 22, -45705983);
          a = md5_ff(a, b, c, d, x[i + 8], 7, 1770035416);
          d = md5_ff(d, a, b, c, x[i + 9], 12, -1958414417);
          c = md5_ff(c, d, a, b, x[i + 10], 17, -42063);
          b = md5_ff(b, c, d, a, x[i + 11], 22, -1990404162);
          a = md5_ff(a, b, c, d, x[i + 12], 7, 1804603682);
          d = md5_ff(d, a, b, c, x[i + 13], 12, -40341101);
          c = md5_ff(c, d, a, b, x[i + 14], 17, -1502002290);
          b = md5_ff(b, c, d, a, x[i + 15], 22, 1236535329);
          a = md5_gg(a, b, c, d, x[i + 1], 5, -165796510);
          d = md5_gg(d, a, b, c, x[i + 6], 9, -1069501632);
          c = md5_gg(c, d, a, b, x[i + 11], 14, 643717713);
          b = md5_gg(b, c, d, a, x[i + 0], 20, -373897302);
          a = md5_gg(a, b, c, d, x[i + 5], 5, -701558691);
          d = md5_gg(d, a, b, c, x[i + 10], 9, 38016083);
          c = md5_gg(c, d, a, b, x[i + 15], 14, -660478335);
          b = md5_gg(b, c, d, a, x[i + 4], 20, -405537848);
          a = md5_gg(a, b, c, d, x[i + 9], 5, 568446438);
          d = md5_gg(d, a, b, c, x[i + 14], 9, -1019803690);
          c = md5_gg(c, d, a, b, x[i + 3], 14, -187363961);
          b = md5_gg(b, c, d, a, x[i + 8], 20, 1163531501);
          a = md5_gg(a, b, c, d, x[i + 13], 5, -1444681467);
          d = md5_gg(d, a, b, c, x[i + 2], 9, -51403784);
          c = md5_gg(c, d, a, b, x[i + 7], 14, 1735328473);
          b = md5_gg(b, c, d, a, x[i + 12], 20, -1926607734);
          a = md5_hh(a, b, c, d, x[i + 5], 4, -378558);
          d = md5_hh(d, a, b, c, x[i + 8], 11, -2022574463);
          c = md5_hh(c, d, a, b, x[i + 11], 16, 1839030562);
          b = md5_hh(b, c, d, a, x[i + 14], 23, -35309556);
          a = md5_hh(a, b, c, d, x[i + 1], 4, -1530992060);
          d = md5_hh(d, a, b, c, x[i + 4], 11, 1272893353);
          c = md5_hh(c, d, a, b, x[i + 7], 16, -155497632);
          b = md5_hh(b, c, d, a, x[i + 10], 23, -1094730640);
          a = md5_hh(a, b, c, d, x[i + 13], 4, 681279174);
          d = md5_hh(d, a, b, c, x[i + 0], 11, -358537222);
          c = md5_hh(c, d, a, b, x[i + 3], 16, -722521979);
          b = md5_hh(b, c, d, a, x[i + 6], 23, 76029189);
          a = md5_hh(a, b, c, d, x[i + 9], 4, -640364487);
          d = md5_hh(d, a, b, c, x[i + 12], 11, -421815835);
          c = md5_hh(c, d, a, b, x[i + 15], 16, 530742520);
          b = md5_hh(b, c, d, a, x[i + 2], 23, -995338651);
          a = md5_ii(a, b, c, d, x[i + 0], 6, -198630844);
          d = md5_ii(d, a, b, c, x[i + 7], 10, 1126891415);
          c = md5_ii(c, d, a, b, x[i + 14], 15, -1416354905);
          b = md5_ii(b, c, d, a, x[i + 5], 21, -57434055);
          a = md5_ii(a, b, c, d, x[i + 12], 6, 1700485571);
          d = md5_ii(d, a, b, c, x[i + 3], 10, -1894986606);
          c = md5_ii(c, d, a, b, x[i + 10], 15, -1051523);
          b = md5_ii(b, c, d, a, x[i + 1], 21, -2054922799);
          a = md5_ii(a, b, c, d, x[i + 8], 6, 1873313359);
          d = md5_ii(d, a, b, c, x[i + 15], 10, -30611744);
          c = md5_ii(c, d, a, b, x[i + 6], 15, -1560198380);
          b = md5_ii(b, c, d, a, x[i + 13], 21, 1309151649);
          a = md5_ii(a, b, c, d, x[i + 4], 6, -145523070);
          d = md5_ii(d, a, b, c, x[i + 11], 10, -1120210379);
          c = md5_ii(c, d, a, b, x[i + 2], 15, 718787259);
          b = md5_ii(b, c, d, a, x[i + 9], 21, -343485551);
          a = safe_add(a, olda);
          b = safe_add(b, oldb);
          c = safe_add(c, oldc);
          d = safe_add(d, oldd)
        }
        return Array(a, b, c, d)
      }

      function md5_cmn(q, a, b, x, s, t) {
        return safe_add(bit_rol(safe_add(safe_add(a, q), safe_add(x, t)), s), b)
      }

      function md5_ff(a, b, c, d, x, s, t) {
        return md5_cmn(b & c | ~b & d, a, b, x, s, t)
      }

      function md5_gg(a, b, c, d, x, s, t) {
        return md5_cmn(b & d | c & ~d, a, b, x, s, t)
      }

      function md5_hh(a, b, c, d, x, s, t) {
        return md5_cmn(b ^ c ^ d, a, b, x, s, t)
      }

      function md5_ii(a, b, c, d, x, s, t) {
        return md5_cmn(c ^ (b | ~d), a, b, x, s, t)
      }

      function safe_add(x, y) {
        var lsw = (x & 65535) + (y & 65535);
        var msw = (x >> 16) + (y >> 16) + (lsw >> 16);
        return msw << 16 | lsw & 65535
      }

      function bit_rol(num, cnt) {
        return num << cnt | num >>> 32 - cnt
      }
      module.exports = function md5(buf) {
        return helpers.hash(buf, core_md5, 16)
      }
    }, {
      "./helpers": 36
    }],
    39: [function(require, module, exports) {
      (function(Buffer) {
        module.exports = function(crypto, password, keyLen, ivLen) {
          keyLen = keyLen / 8;
          ivLen = ivLen || 0;
          var ki = 0;
          var ii = 0;
          var key = new Buffer(keyLen);
          var iv = new Buffer(ivLen);
          var addmd = 0;
          var md, md_buf;
          var i;
          while (true) {
            md = crypto.createHash("md5");
            if (addmd++ > 0) {
              md.update(md_buf)
            }
            md.update(password);
            md_buf = md.digest();
            i = 0;
            if (keyLen > 0) {
              while (true) {
                if (keyLen === 0) {
                  break
                }
                if (i === md_buf.length) {
                  break
                }
                key[ki++] = md_buf[i];
                keyLen--;
                i++
              }
            }
            if (ivLen > 0 && i !== md_buf.length) {
              while (true) {
                if (ivLen === 0) {
                  break
                }
                if (i === md_buf.length) {
                  break
                }
                iv[ii++] = md_buf[i];
                ivLen--;
                i++
              }
            }
            if (keyLen === 0 && ivLen === 0) {
              break
            }
          }
          for (i = 0; i < md_buf.length; i++) {
            md_buf[i] = 0
          }
          return {
            key: key,
            iv: iv
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    40: [function(require, module, exports) {
      (function(Buffer) {
        var uint_max = Math.pow(2, 32);

        function fixup_uint32(x) {
          var ret, x_pos;
          ret = x > uint_max || x < 0 ? (x_pos = Math.abs(x) % uint_max, x < 0 ? uint_max - x_pos : x_pos) : x;
          return ret
        }

        function scrub_vec(v) {
          var i, _i, _ref;
          for (i = _i = 0, _ref = v.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
            v[i] = 0
          }
          return false
        }

        function Global() {
          var i;
          this.SBOX = [];
          this.INV_SBOX = [];
          this.SUB_MIX = function() {
            var _i, _results;
            _results = [];
            for (i = _i = 0; _i < 4; i = ++_i) {
              _results.push([])
            }
            return _results
          }();
          this.INV_SUB_MIX = function() {
            var _i, _results;
            _results = [];
            for (i = _i = 0; _i < 4; i = ++_i) {
              _results.push([])
            }
            return _results
          }();
          this.init();
          this.RCON = [0, 1, 2, 4, 8, 16, 32, 64, 128, 27, 54]
        }
        Global.prototype.init = function() {
          var d, i, sx, t, x, x2, x4, x8, xi, _i;
          d = function() {
            var _i, _results;
            _results = [];
            for (i = _i = 0; _i < 256; i = ++_i) {
              if (i < 128) {
                _results.push(i << 1)
              } else {
                _results.push(i << 1 ^ 283)
              }
            }
            return _results
          }();
          x = 0;
          xi = 0;
          for (i = _i = 0; _i < 256; i = ++_i) {
            sx = xi ^ xi << 1 ^ xi << 2 ^ xi << 3 ^ xi << 4;
            sx = sx >>> 8 ^ sx & 255 ^ 99;
            this.SBOX[x] = sx;
            this.INV_SBOX[sx] = x;
            x2 = d[x];
            x4 = d[x2];
            x8 = d[x4];
            t = d[sx] * 257 ^ sx * 16843008;
            this.SUB_MIX[0][x] = t << 24 | t >>> 8;
            this.SUB_MIX[1][x] = t << 16 | t >>> 16;
            this.SUB_MIX[2][x] = t << 8 | t >>> 24;
            this.SUB_MIX[3][x] = t;
            t = x8 * 16843009 ^ x4 * 65537 ^ x2 * 257 ^ x * 16843008;
            this.INV_SUB_MIX[0][sx] = t << 24 | t >>> 8;
            this.INV_SUB_MIX[1][sx] = t << 16 | t >>> 16;
            this.INV_SUB_MIX[2][sx] = t << 8 | t >>> 24;
            this.INV_SUB_MIX[3][sx] = t;
            if (x === 0) {
              x = xi = 1
            } else {
              x = x2 ^ d[d[d[x8 ^ x2]]];
              xi ^= d[d[xi]]
            }
          }
          return true
        };
        var G = new Global;
        AES.blockSize = 4 * 4;
        AES.prototype.blockSize = AES.blockSize;
        AES.keySize = 256 / 8;
        AES.prototype.keySize = AES.keySize;
        AES.ivSize = AES.blockSize;
        AES.prototype.ivSize = AES.ivSize;

        function bufferToArray(buf) {
          var len = buf.length / 4;
          var out = new Array(len);
          var i = -1;
          while (++i < len) {
            out[i] = buf.readUInt32BE(i * 4)
          }
          return out
        }

        function AES(key) {
          this._key = bufferToArray(key);
          this._doReset()
        }
        AES.prototype._doReset = function() {
          var invKsRow, keySize, keyWords, ksRow, ksRows, t, _i, _j;
          keyWords = this._key;
          keySize = keyWords.length;
          this._nRounds = keySize + 6;
          ksRows = (this._nRounds + 1) * 4;
          this._keySchedule = [];
          for (ksRow = _i = 0; 0 <= ksRows ? _i < ksRows : _i > ksRows; ksRow = 0 <= ksRows ? ++_i : --_i) {
            this._keySchedule[ksRow] = ksRow < keySize ? keyWords[ksRow] : (t = this._keySchedule[ksRow - 1], ksRow % keySize === 0 ? (t = t << 8 | t >>> 24, t = G.SBOX[t >>> 24] << 24 | G.SBOX[t >>> 16 & 255] << 16 | G.SBOX[t >>> 8 & 255] << 8 | G.SBOX[t & 255], t ^= G.RCON[ksRow / keySize | 0] << 24) : keySize > 6 && ksRow % keySize === 4 ? t = G.SBOX[t >>> 24] << 24 | G.SBOX[t >>> 16 & 255] << 16 | G.SBOX[t >>> 8 & 255] << 8 | G.SBOX[t & 255] : void 0, this._keySchedule[ksRow - keySize] ^ t)
          }
          this._invKeySchedule = [];
          for (invKsRow = _j = 0; 0 <= ksRows ? _j < ksRows : _j > ksRows; invKsRow = 0 <= ksRows ? ++_j : --_j) {
            ksRow = ksRows - invKsRow;
            t = this._keySchedule[ksRow - (invKsRow % 4 ? 0 : 4)];
            this._invKeySchedule[invKsRow] = invKsRow < 4 || ksRow <= 4 ? t : G.INV_SUB_MIX[0][G.SBOX[t >>> 24]] ^ G.INV_SUB_MIX[1][G.SBOX[t >>> 16 & 255]] ^ G.INV_SUB_MIX[2][G.SBOX[t >>> 8 & 255]] ^ G.INV_SUB_MIX[3][G.SBOX[t & 255]]
          }
          return true
        };
        AES.prototype.encryptBlock = function(M) {
          M = bufferToArray(new Buffer(M));
          var out = this._doCryptBlock(M, this._keySchedule, G.SUB_MIX, G.SBOX);
          var buf = new Buffer(16);
          buf.writeUInt32BE(out[0], 0);
          buf.writeUInt32BE(out[1], 4);
          buf.writeUInt32BE(out[2], 8);
          buf.writeUInt32BE(out[3], 12);
          return buf
        };
        AES.prototype.decryptBlock = function(M) {
          M = bufferToArray(new Buffer(M));
          var temp = [M[3], M[1]];
          M[1] = temp[0];
          M[3] = temp[1];
          var out = this._doCryptBlock(M, this._invKeySchedule, G.INV_SUB_MIX, G.INV_SBOX);
          var buf = new Buffer(16);
          buf.writeUInt32BE(out[0], 0);
          buf.writeUInt32BE(out[3], 4);
          buf.writeUInt32BE(out[2], 8);
          buf.writeUInt32BE(out[1], 12);
          return buf
        };
        AES.prototype.scrub = function() {
          scrub_vec(this._keySchedule);
          scrub_vec(this._invKeySchedule);
          scrub_vec(this._key)
        };
        AES.prototype._doCryptBlock = function(M, keySchedule, SUB_MIX, SBOX) {
          var ksRow, round, s0, s1, s2, s3, t0, t1, t2, t3, _i, _ref;
          s0 = M[0] ^ keySchedule[0];
          s1 = M[1] ^ keySchedule[1];
          s2 = M[2] ^ keySchedule[2];
          s3 = M[3] ^ keySchedule[3];
          ksRow = 4;
          for (round = _i = 1, _ref = this._nRounds; 1 <= _ref ? _i < _ref : _i > _ref; round = 1 <= _ref ? ++_i : --_i) {
            t0 = SUB_MIX[0][s0 >>> 24] ^ SUB_MIX[1][s1 >>> 16 & 255] ^ SUB_MIX[2][s2 >>> 8 & 255] ^ SUB_MIX[3][s3 & 255] ^ keySchedule[ksRow++];
            t1 = SUB_MIX[0][s1 >>> 24] ^ SUB_MIX[1][s2 >>> 16 & 255] ^ SUB_MIX[2][s3 >>> 8 & 255] ^ SUB_MIX[3][s0 & 255] ^ keySchedule[ksRow++];
            t2 = SUB_MIX[0][s2 >>> 24] ^ SUB_MIX[1][s3 >>> 16 & 255] ^ SUB_MIX[2][s0 >>> 8 & 255] ^ SUB_MIX[3][s1 & 255] ^ keySchedule[ksRow++];
            t3 = SUB_MIX[0][s3 >>> 24] ^ SUB_MIX[1][s0 >>> 16 & 255] ^ SUB_MIX[2][s1 >>> 8 & 255] ^ SUB_MIX[3][s2 & 255] ^ keySchedule[ksRow++];
            s0 = t0;
            s1 = t1;
            s2 = t2;
            s3 = t3
          }
          t0 = (SBOX[s0 >>> 24] << 24 | SBOX[s1 >>> 16 & 255] << 16 | SBOX[s2 >>> 8 & 255] << 8 | SBOX[s3 & 255]) ^ keySchedule[ksRow++];
          t1 = (SBOX[s1 >>> 24] << 24 | SBOX[s2 >>> 16 & 255] << 16 | SBOX[s3 >>> 8 & 255] << 8 | SBOX[s0 & 255]) ^ keySchedule[ksRow++];
          t2 = (SBOX[s2 >>> 24] << 24 | SBOX[s3 >>> 16 & 255] << 16 | SBOX[s0 >>> 8 & 255] << 8 | SBOX[s1 & 255]) ^ keySchedule[ksRow++];
          t3 = (SBOX[s3 >>> 24] << 24 | SBOX[s0 >>> 16 & 255] << 16 | SBOX[s1 >>> 8 & 255] << 8 | SBOX[s2 & 255]) ^ keySchedule[ksRow++];
          return [fixup_uint32(t0), fixup_uint32(t1), fixup_uint32(t2), fixup_uint32(t3)]
        };
        exports.AES = AES
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    41: [function(require, module, exports) {
      (function(Buffer) {
        var aes = require("./aes");
        var Transform = require("./cipherBase");
        var inherits = require("inherits");
        var GHASH = require("./ghash");
        var xor = require("./xor");
        inherits(StreamCipher, Transform);
        module.exports = StreamCipher;

        function StreamCipher(mode, key, iv, decrypt) {
          if (!(this instanceof StreamCipher)) {
            return new StreamCipher(mode, key, iv)
          }
          Transform.call(this);
          this._finID = Buffer.concat([iv, new Buffer([0, 0, 0, 1])]);
          iv = Buffer.concat([iv, new Buffer([0, 0, 0, 2])]);
          this._cipher = new aes.AES(key);
          this._prev = new Buffer(iv.length);
          this._cache = new Buffer("");
          this._secCache = new Buffer("");
          this._decrypt = decrypt;
          this._alen = 0;
          this._len = 0;
          iv.copy(this._prev);
          this._mode = mode;
          var h = new Buffer(4);
          h.fill(0);
          this._ghash = new GHASH(this._cipher.encryptBlock(h));
          this._authTag = null;
          this._called = false
        }
        StreamCipher.prototype._transform = function(chunk, _, next) {
          if (!this._called && this._alen) {
            var rump = 16 - this._alen % 16;
            if (rump < 16) {
              rump = new Buffer(rump);
              rump.fill(0);
              this._ghash.update(rump)
            }
          }
          this._called = true;
          var out = this._mode.encrypt(this, chunk);
          if (this._decrypt) {
            this._ghash.update(chunk)
          } else {
            this._ghash.update(out)
          }
          this._len += chunk.length;
          next(null, out)
        };
        StreamCipher.prototype._flush = function(next) {
          if (this._decrypt && !this._authTag) {
            throw new Error("Unsupported state or unable to authenticate data")
          }
          var tag = xor(this._ghash.final(this._alen * 8, this._len * 8), this._cipher.encryptBlock(this._finID));
          if (this._decrypt) {
            if (xorTest(tag, this._authTag)) {
              throw new Error("Unsupported state or unable to authenticate data")
            }
          } else {
            this._authTag = tag
          }
          this._cipher.scrub();
          next()
        };
        StreamCipher.prototype.getAuthTag = function getAuthTag() {
          if (!this._decrypt && Buffer.isBuffer(this._authTag)) {
            return this._authTag
          } else {
            throw new Error("Attempting to get auth tag in unsupported state")
          }
        };
        StreamCipher.prototype.setAuthTag = function setAuthTag(tag) {
          if (this._decrypt) {
            this._authTag = tag
          } else {
            throw new Error("Attempting to set auth tag in unsupported state")
          }
        };
        StreamCipher.prototype.setAAD = function setAAD(buf) {
          if (!this._called) {
            this._ghash.update(buf);
            this._alen += buf.length
          } else {
            throw new Error("Attempting to set AAD in unsupported state")
          }
        };

        function xorTest(a, b) {
          var out = 0;
          if (a.length !== b.length) {
            out++
          }
          var len = Math.min(a.length, b.length);
          var i = -1;
          while (++i < len) {
            out += a[i] ^ b[i]
          }
          return out
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./aes": 40,
      "./cipherBase": 42,
      "./ghash": 45,
      "./xor": 57,
      buffer: 7,
      inherits: 55
    }],
    42: [function(require, module, exports) {
      (function(Buffer) {
        var Transform = require("stream").Transform;
        var inherits = require("inherits");
        module.exports = CipherBase;
        inherits(CipherBase, Transform);

        function CipherBase() {
          Transform.call(this)
        }
        CipherBase.prototype.update = function(data, inputEnd, outputEnc) {
          this.write(data, inputEnd);
          var outData = new Buffer("");
          var chunk;
          while (chunk = this.read()) {
            outData = Buffer.concat([outData, chunk])
          }
          if (outputEnc) {
            outData = outData.toString(outputEnc)
          }
          return outData
        };
        CipherBase.prototype.final = function(outputEnc) {
          this.end();
          var outData = new Buffer("");
          var chunk;
          while (chunk = this.read()) {
            outData = Buffer.concat([outData, chunk])
          }
          if (outputEnc) {
            outData = outData.toString(outputEnc)
          }
          return outData
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7,
      inherits: 55,
      stream: 26
    }],
    43: [function(require, module, exports) {
      (function(Buffer) {
        var aes = require("./aes");
        var Transform = require("./cipherBase");
        var inherits = require("inherits");
        var modes = require("./modes");
        var StreamCipher = require("./streamCipher");
        var AuthCipher = require("./authCipher");
        var ebtk = require("./EVP_BytesToKey");
        inherits(Decipher, Transform);

        function Decipher(mode, key, iv) {
          if (!(this instanceof Decipher)) {
            return new Decipher(mode, key, iv)
          }
          Transform.call(this);
          this._cache = new Splitter;
          this._last = void 0;
          this._cipher = new aes.AES(key);
          this._prev = new Buffer(iv.length);
          iv.copy(this._prev);
          this._mode = mode
        }
        Decipher.prototype._transform = function(data, _, next) {
          this._cache.add(data);
          var chunk;
          var thing;
          while (chunk = this._cache.get()) {
            thing = this._mode.decrypt(this, chunk);
            this.push(thing)
          }
          next()
        };
        Decipher.prototype._flush = function(next) {
          var chunk = this._cache.flush();
          if (!chunk) {
            return next
          }
          this.push(unpad(this._mode.decrypt(this, chunk)));
          next()
        };

        function Splitter() {
          if (!(this instanceof Splitter)) {
            return new Splitter
          }
          this.cache = new Buffer("")
        }
        Splitter.prototype.add = function(data) {
          this.cache = Buffer.concat([this.cache, data])
        };
        Splitter.prototype.get = function() {
          if (this.cache.length > 16) {
            var out = this.cache.slice(0, 16);
            this.cache = this.cache.slice(16);
            return out
          }
          return null
        };
        Splitter.prototype.flush = function() {
          if (this.cache.length) {
            return this.cache
          }
        };

        function unpad(last) {
          var padded = last[15];
          if (padded === 16) {
            return
          }
          return last.slice(0, 16 - padded)
        }
        var modelist = {
          ECB: require("./modes/ecb"),
          CBC: require("./modes/cbc"),
          CFB: require("./modes/cfb"),
          CFB8: require("./modes/cfb8"),
          CFB1: require("./modes/cfb1"),
          OFB: require("./modes/ofb"),
          CTR: require("./modes/ctr"),
          GCM: require("./modes/ctr")
        };
        module.exports = function(crypto) {
          function createDecipheriv(suite, password, iv) {
            var config = modes[suite];
            if (!config) {
              throw new TypeError("invalid suite type")
            }
            if (typeof iv === "string") {
              iv = new Buffer(iv)
            }
            if (typeof password === "string") {
              password = new Buffer(password)
            }
            if (password.length !== config.key / 8) {
              throw new TypeError("invalid key length " + password.length)
            }
            if (iv.length !== config.iv) {
              throw new TypeError("invalid iv length " + iv.length)
            }
            if (config.type === "stream") {
              return new StreamCipher(modelist[config.mode], password, iv, true)
            } else if (config.type === "auth") {
              return new AuthCipher(modelist[config.mode], password, iv, true)
            }
            return new Decipher(modelist[config.mode], password, iv)
          }

          function createDecipher(suite, password) {
            var config = modes[suite];
            if (!config) {
              throw new TypeError("invalid suite type")
            }
            var keys = ebtk(crypto, password, config.key, config.iv);
            return createDecipheriv(suite, keys.key, keys.iv)
          }
          return {
            createDecipher: createDecipher,
            createDecipheriv: createDecipheriv
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./EVP_BytesToKey": 39,
      "./aes": 40,
      "./authCipher": 41,
      "./cipherBase": 42,
      "./modes": 47,
      "./modes/cbc": 48,
      "./modes/cfb": 49,
      "./modes/cfb1": 50,
      "./modes/cfb8": 51,
      "./modes/ctr": 52,
      "./modes/ecb": 53,
      "./modes/ofb": 54,
      "./streamCipher": 56,
      buffer: 7,
      inherits: 55
    }],
    44: [function(require, module, exports) {
      (function(Buffer) {
        var aes = require("./aes");
        var Transform = require("./cipherBase");
        var inherits = require("inherits");
        var modes = require("./modes");
        var ebtk = require("./EVP_BytesToKey");
        var StreamCipher = require("./streamCipher");
        var AuthCipher = require("./authCipher");
        inherits(Cipher, Transform);

        function Cipher(mode, key, iv) {
          if (!(this instanceof Cipher)) {
            return new Cipher(mode, key, iv)
          }
          Transform.call(this);
          this._cache = new Splitter;
          this._cipher = new aes.AES(key);
          this._prev = new Buffer(iv.length);
          iv.copy(this._prev);
          this._mode = mode
        }
        Cipher.prototype._transform = function(data, _, next) {
          this._cache.add(data);
          var chunk;
          var thing;
          while (chunk = this._cache.get()) {
            thing = this._mode.encrypt(this, chunk);
            this.push(thing)
          }
          next()
        };
        Cipher.prototype._flush = function(next) {
          var chunk = this._cache.flush();
          this.push(this._mode.encrypt(this, chunk));
          this._cipher.scrub();
          next()
        };

        function Splitter() {
          if (!(this instanceof Splitter)) {
            return new Splitter
          }
          this.cache = new Buffer("")
        }
        Splitter.prototype.add = function(data) {
          this.cache = Buffer.concat([this.cache, data])
        };
        Splitter.prototype.get = function() {
          if (this.cache.length > 15) {
            var out = this.cache.slice(0, 16);
            this.cache = this.cache.slice(16);
            return out
          }
          return null
        };
        Splitter.prototype.flush = function() {
          var len = 16 - this.cache.length;
          var padBuff = new Buffer(len);
          var i = -1;
          while (++i < len) {
            padBuff.writeUInt8(len, i)
          }
          var out = Buffer.concat([this.cache, padBuff]);
          return out
        };
        var modelist = {
          ECB: require("./modes/ecb"),
          CBC: require("./modes/cbc"),
          CFB: require("./modes/cfb"),
          CFB8: require("./modes/cfb8"),
          CFB1: require("./modes/cfb1"),
          OFB: require("./modes/ofb"),
          CTR: require("./modes/ctr"),
          GCM: require("./modes/ctr")
        };
        module.exports = function(crypto) {
          function createCipheriv(suite, password, iv) {
            var config = modes[suite];
            if (!config) {
              throw new TypeError("invalid suite type")
            }
            if (typeof iv === "string") {
              iv = new Buffer(iv)
            }
            if (typeof password === "string") {
              password = new Buffer(password)
            }
            if (password.length !== config.key / 8) {
              throw new TypeError("invalid key length " + password.length)
            }
            if (iv.length !== config.iv) {
              throw new TypeError("invalid iv length " + iv.length)
            }
            if (config.type === "stream") {
              return new StreamCipher(modelist[config.mode], password, iv)
            } else if (config.type === "auth") {
              return new AuthCipher(modelist[config.mode], password, iv)
            }
            return new Cipher(modelist[config.mode], password, iv)
          }

          function createCipher(suite, password) {
            var config = modes[suite];
            if (!config) {
              throw new TypeError("invalid suite type")
            }
            var keys = ebtk(crypto, password, config.key, config.iv);
            return createCipheriv(suite, keys.key, keys.iv)
          }
          return {
            createCipher: createCipher,
            createCipheriv: createCipheriv
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./EVP_BytesToKey": 39,
      "./aes": 40,
      "./authCipher": 41,
      "./cipherBase": 42,
      "./modes": 47,
      "./modes/cbc": 48,
      "./modes/cfb": 49,
      "./modes/cfb1": 50,
      "./modes/cfb8": 51,
      "./modes/ctr": 52,
      "./modes/ecb": 53,
      "./modes/ofb": 54,
      "./streamCipher": 56,
      buffer: 7,
      inherits: 55
    }],
    45: [function(require, module, exports) {
      (function(Buffer) {
        var zeros = new Buffer(16);
        zeros.fill(0);
        module.exports = GHASH;

        function GHASH(key) {
          this.h = key;
          this.state = new Buffer(16);
          this.state.fill(0);
          this.cache = new Buffer("")
        }
        GHASH.prototype.ghash = function(block) {
          var i = -1;
          while (++i < block.length) {
            this.state[i] ^= 255 & block[i]
          }
          this._multiply()
        };
        GHASH.prototype._multiply = function() {
          var Vi = toArray(this.h);
          var Zi = [0, 0, 0, 0];
          var j, xi, lsb_Vi;
          var i = -1;
          while (++i < 128) {
            xi = (this.state[~~(i / 8)] & 1 << 7 - i % 8) !== 0;
            if (xi) {
              Zi = xor(Zi, Vi)
            }
            lsb_Vi = (Vi[3] & 1) !== 0;
            for (j = 3; j > 0; j--) {
              Vi[j] = Vi[j] >>> 1 | (Vi[j - 1] & 1) << 31
            }
            Vi[0] = Vi[0] >>> 1;
            if (lsb_Vi) {
              Vi[0] = Vi[0] ^ 225 << 24
            }
          }
          this.state = fromArray(Zi)
        };
        GHASH.prototype.update = function(buf) {
          this.cache = Buffer.concat([this.cache, buf]);
          var chunk;
          while (this.cache.length >= 16) {
            chunk = this.cache.slice(0, 16);
            this.cache = this.cache.slice(16);
            this.ghash(chunk)
          }
        };
        GHASH.prototype.final = function(abl, bl) {
          if (this.cache.length) {
            this.ghash(Buffer.concat([this.cache, zeros], 16))
          }
          this.ghash(fromArray([0, abl, 0, bl]));
          return this.state
        };

        function toArray(buf) {
          return [buf.readUInt32BE(0), buf.readUInt32BE(4), buf.readUInt32BE(8), buf.readUInt32BE(12)]
        }

        function fromArray(out) {
          out = out.map(fixup_uint32);
          var buf = new Buffer(16);
          buf.writeUInt32BE(out[0], 0);
          buf.writeUInt32BE(out[1], 4);
          buf.writeUInt32BE(out[2], 8);
          buf.writeUInt32BE(out[3], 12);
          return buf
        }
        var uint_max = Math.pow(2, 32);

        function fixup_uint32(x) {
          var ret, x_pos;
          ret = x > uint_max || x < 0 ? (x_pos = Math.abs(x) % uint_max, x < 0 ? uint_max - x_pos : x_pos) : x;
          return ret
        }

        function xor(a, b) {
          return [a[0] ^ b[0], a[1] ^ b[1], a[2] ^ b[2], a[3] ^ b[3]]
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    46: [function(require, module, exports) {
      module.exports = function(crypto, exports) {
        exports = exports || {};
        var ciphers = require("./encrypter")(crypto);
        exports.createCipher = ciphers.createCipher;
        exports.createCipheriv = ciphers.createCipheriv;
        var deciphers = require("./decrypter")(crypto);
        exports.createDecipher = deciphers.createDecipher;
        exports.createDecipheriv = deciphers.createDecipheriv;
        var modes = require("./modes");

        function listCiphers() {
          return Object.keys(modes)
        }
        exports.listCiphers = listCiphers
      }
    }, {
      "./decrypter": 43,
      "./encrypter": 44,
      "./modes": 47
    }],
    47: [function(require, module, exports) {
      exports["aes-128-ecb"] = {
        cipher: "AES",
        key: 128,
        iv: 0,
        mode: "ECB",
        type: "block"
      };
      exports["aes-192-ecb"] = {
        cipher: "AES",
        key: 192,
        iv: 0,
        mode: "ECB",
        type: "block"
      };
      exports["aes-256-ecb"] = {
        cipher: "AES",
        key: 256,
        iv: 0,
        mode: "ECB",
        type: "block"
      };
      exports["aes-128-cbc"] = {
        cipher: "AES",
        key: 128,
        iv: 16,
        mode: "CBC",
        type: "block"
      };
      exports["aes-192-cbc"] = {
        cipher: "AES",
        key: 192,
        iv: 16,
        mode: "CBC",
        type: "block"
      };
      exports["aes-256-cbc"] = {
        cipher: "AES",
        key: 256,
        iv: 16,
        mode: "CBC",
        type: "block"
      };
      exports["aes128"] = exports["aes-128-cbc"];
      exports["aes192"] = exports["aes-192-cbc"];
      exports["aes256"] = exports["aes-256-cbc"];
      exports["aes-128-cfb"] = {
        cipher: "AES",
        key: 128,
        iv: 16,
        mode: "CFB",
        type: "stream"
      };
      exports["aes-192-cfb"] = {
        cipher: "AES",
        key: 192,
        iv: 16,
        mode: "CFB",
        type: "stream"
      };
      exports["aes-256-cfb"] = {
        cipher: "AES",
        key: 256,
        iv: 16,
        mode: "CFB",
        type: "stream"
      };
      exports["aes-128-cfb8"] = {
        cipher: "AES",
        key: 128,
        iv: 16,
        mode: "CFB8",
        type: "stream"
      };
      exports["aes-192-cfb8"] = {
        cipher: "AES",
        key: 192,
        iv: 16,
        mode: "CFB8",
        type: "stream"
      };
      exports["aes-256-cfb8"] = {
        cipher: "AES",
        key: 256,
        iv: 16,
        mode: "CFB8",
        type: "stream"
      };
      exports["aes-128-cfb1"] = {
        cipher: "AES",
        key: 128,
        iv: 16,
        mode: "CFB1",
        type: "stream"
      };
      exports["aes-192-cfb1"] = {
        cipher: "AES",
        key: 192,
        iv: 16,
        mode: "CFB1",
        type: "stream"
      };
      exports["aes-256-cfb1"] = {
        cipher: "AES",
        key: 256,
        iv: 16,
        mode: "CFB1",
        type: "stream"
      };
      exports["aes-128-ofb"] = {
        cipher: "AES",
        key: 128,
        iv: 16,
        mode: "OFB",
        type: "stream"
      };
      exports["aes-192-ofb"] = {
        cipher: "AES",
        key: 192,
        iv: 16,
        mode: "OFB",
        type: "stream"
      };
      exports["aes-256-ofb"] = {
        cipher: "AES",
        key: 256,
        iv: 16,
        mode: "OFB",
        type: "stream"
      };
      exports["aes-128-ctr"] = {
        cipher: "AES",
        key: 128,
        iv: 16,
        mode: "CTR",
        type: "stream"
      };
      exports["aes-192-ctr"] = {
        cipher: "AES",
        key: 192,
        iv: 16,
        mode: "CTR",
        type: "stream"
      };
      exports["aes-256-ctr"] = {
        cipher: "AES",
        key: 256,
        iv: 16,
        mode: "CTR",
        type: "stream"
      };
      exports["aes-128-gcm"] = {
        cipher: "AES",
        key: 128,
        iv: 12,
        mode: "GCM",
        type: "auth"
      };
      exports["aes-192-gcm"] = {
        cipher: "AES",
        key: 192,
        iv: 12,
        mode: "GCM",
        type: "auth"
      };
      exports["aes-256-gcm"] = {
        cipher: "AES",
        key: 256,
        iv: 12,
        mode: "GCM",
        type: "auth"
      }
    }, {}],
    48: [function(require, module, exports) {
      var xor = require("../xor");
      exports.encrypt = function(self, block) {
        var data = xor(block, self._prev);
        self._prev = self._cipher.encryptBlock(data);
        return self._prev
      };
      exports.decrypt = function(self, block) {
        var pad = self._prev;
        self._prev = block;
        var out = self._cipher.decryptBlock(block);
        return xor(out, pad)
      }
    }, {
      "../xor": 57
    }],
    49: [function(require, module, exports) {
      (function(Buffer) {
        var xor = require("../xor");
        exports.encrypt = function(self, data, decrypt) {
          var out = new Buffer("");
          var len;
          while (data.length) {
            if (self._cache.length === 0) {
              self._cache = self._cipher.encryptBlock(self._prev);
              self._prev = new Buffer("")
            }
            if (self._cache.length <= data.length) {
              len = self._cache.length;
              out = Buffer.concat([out, encryptStart(self, data.slice(0, len), decrypt)]);
              data = data.slice(len)
            } else {
              out = Buffer.concat([out, encryptStart(self, data, decrypt)]);
              break
            }
          }
          return out
        };

        function encryptStart(self, data, decrypt) {
          var len = data.length;
          var out = xor(data, self._cache);
          self._cache = self._cache.slice(len);
          self._prev = Buffer.concat([self._prev, decrypt ? data : out]);
          return out
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "../xor": 57,
      buffer: 7
    }],
    50: [function(require, module, exports) {
      (function(Buffer) {
        function encryptByte(self, byte, decrypt) {
          var pad;
          var i = -1;
          var len = 8;
          var out = 0;
          var bit, value;
          while (++i < len) {
            pad = self._cipher.encryptBlock(self._prev);
            bit = byte & 1 << 7 - i ? 128 : 0;
            value = pad[0] ^ bit;
            out += (value & 128) >> i % 8;
            self._prev = shiftIn(self._prev, decrypt ? bit : value)
          }
          return out
        }
        exports.encrypt = function(self, chunk, decrypt) {
          var len = chunk.length;
          var out = new Buffer(len);
          var i = -1;
          while (++i < len) {
            out[i] = encryptByte(self, chunk[i], decrypt)
          }
          return out
        };

        function shiftIn(buffer, value) {
          var len = buffer.length;
          var i = -1;
          var out = new Buffer(buffer.length);
          buffer = Buffer.concat([buffer, new Buffer([value])]);
          while (++i < len) {
            out[i] = buffer[i] << 1 | buffer[i + 1] >> 7
          }
          return out
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    51: [function(require, module, exports) {
      (function(Buffer) {
        function encryptByte(self, byte, decrypt) {
          var pad = self._cipher.encryptBlock(self._prev);
          var out = pad[0] ^ byte;
          self._prev = Buffer.concat([self._prev.slice(1), new Buffer([decrypt ? byte : out])]);
          return out
        }
        exports.encrypt = function(self, chunk, decrypt) {
          var len = chunk.length;
          var out = new Buffer(len);
          var i = -1;
          while (++i < len) {
            out[i] = encryptByte(self, chunk[i], decrypt)
          }
          return out
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    52: [function(require, module, exports) {
      (function(Buffer) {
        var xor = require("../xor");

        function getBlock(self) {
          var out = self._cipher.encryptBlock(self._prev);
          incr32(self._prev);
          return out
        }
        exports.encrypt = function(self, chunk) {
          while (self._cache.length < chunk.length) {
            self._cache = Buffer.concat([self._cache, getBlock(self)])
          }
          var pad = self._cache.slice(0, chunk.length);
          self._cache = self._cache.slice(chunk.length);
          return xor(chunk, pad)
        };

        function incr32(iv) {
          var len = iv.length;
          var item;
          while (len--) {
            item = iv.readUInt8(len);
            if (item === 255) {
              iv.writeUInt8(0, len)
            } else {
              item++;
              iv.writeUInt8(item, len);
              break
            }
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "../xor": 57,
      buffer: 7
    }],
    53: [function(require, module, exports) {
      exports.encrypt = function(self, block) {
        return self._cipher.encryptBlock(block)
      };
      exports.decrypt = function(self, block) {
        return self._cipher.decryptBlock(block)
      }
    }, {}],
    54: [function(require, module, exports) {
      (function(Buffer) {
        var xor = require("../xor");

        function getBlock(self) {
          self._prev = self._cipher.encryptBlock(self._prev);
          return self._prev
        }
        exports.encrypt = function(self, chunk) {
          while (self._cache.length < chunk.length) {
            self._cache = Buffer.concat([self._cache, getBlock(self)])
          }
          var pad = self._cache.slice(0, chunk.length);
          self._cache = self._cache.slice(chunk.length);
          return xor(chunk, pad)
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "../xor": 57,
      buffer: 7
    }],
    55: [function(require, module, exports) {
      module.exports = require(12)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/inherits/inherits_browser.js": 12
    }],
    56: [function(require, module, exports) {
      (function(Buffer) {
        var aes = require("./aes");
        var Transform = require("./cipherBase");
        var inherits = require("inherits");
        inherits(StreamCipher, Transform);
        module.exports = StreamCipher;

        function StreamCipher(mode, key, iv, decrypt) {
          if (!(this instanceof StreamCipher)) {
            return new StreamCipher(mode, key, iv)
          }
          Transform.call(this);
          this._cipher = new aes.AES(key);
          this._prev = new Buffer(iv.length);
          this._cache = new Buffer("");
          this._secCache = new Buffer("");
          this._decrypt = decrypt;
          iv.copy(this._prev);
          this._mode = mode
        }
        StreamCipher.prototype._transform = function(chunk, _, next) {
          next(null, this._mode.encrypt(this, chunk, this._decrypt))
        };
        StreamCipher.prototype._flush = function(next) {
          this._cipher.scrub();
          next()
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./aes": 40,
      "./cipherBase": 42,
      buffer: 7,
      inherits: 55
    }],
    57: [function(require, module, exports) {
      (function(Buffer) {
        module.exports = xor;

        function xor(a, b) {
          var len = Math.min(a.length, b.length);
          var out = new Buffer(len);
          var i = -1;
          while (++i < len) {
            out.writeUInt8(a[i] ^ b[i], i)
          }
          return out
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    58: [function(require, module, exports) {
      module.exports = {
        "2.16.840.1.101.3.4.1.1": "aes-128-ecb",
        "2.16.840.1.101.3.4.1.2": "aes-128-cbc",
        "2.16.840.1.101.3.4.1.3": "aes-128-ofb",
        "2.16.840.1.101.3.4.1.4": "aes-128-cfb",
        "2.16.840.1.101.3.4.1.21": "aes-192-ecb",
        "2.16.840.1.101.3.4.1.22": "aes-192-cbc",
        "2.16.840.1.101.3.4.1.23": "aes-192-ofb",
        "2.16.840.1.101.3.4.1.24": "aes-192-cfb",
        "2.16.840.1.101.3.4.1.41": "aes-256-ecb",
        "2.16.840.1.101.3.4.1.42": "aes-256-cbc",
        "2.16.840.1.101.3.4.1.43": "aes-256-ofb",
        "2.16.840.1.101.3.4.1.44": "aes-256-cfb"
      }
    }, {}],
    59: [function(require, module, exports) {
      (function(Buffer) {
        exports["RSA-SHA224"] = exports.sha224WithRSAEncryption = {
          sign: "rsa",
          hash: "sha224",
          id: new Buffer("302d300d06096086480165030402040500041c", "hex")
        };
        exports["RSA-SHA256"] = exports.sha256WithRSAEncryption = {
          sign: "rsa",
          hash: "sha256",
          id: new Buffer("3031300d060960864801650304020105000420", "hex")
        };
        exports["RSA-SHA384"] = exports.sha384WithRSAEncryption = {
          sign: "rsa",
          hash: "sha384",
          id: new Buffer("3041300d060960864801650304020205000430", "hex")
        };
        exports["RSA-SHA512"] = exports.sha512WithRSAEncryption = {
          sign: "rsa",
          hash: "sha512",
          id: new Buffer("3051300d060960864801650304020305000440", "hex")
        };
        exports["RSA-SHA1"] = {
          sign: "rsa",
          hash: "sha1",
          id: new Buffer("3021300906052b0e03021a05000414", "hex")
        };
        exports["ecdsa-with-SHA1"] = {
          sign: "ecdsa",
          hash: "sha1",
          id: new Buffer("", "hex")
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    60: [function(require, module, exports) {
      var asn1 = require("asn1.js");
      var rfc3280 = require("asn1.js-rfc3280");
      var RSAPrivateKey = asn1.define("RSAPrivateKey", function() {
        this.seq().obj(this.key("version").int(), this.key("modulus").int(), this.key("publicExponent").int(), this.key("privateExponent").int(), this.key("prime1").int(), this.key("prime2").int(), this.key("exponent1").int(), this.key("exponent2").int(), this.key("coefficient").int())
      });
      exports.RSAPrivateKey = RSAPrivateKey;
      var RSAPublicKey = asn1.define("RSAPublicKey", function() {
        this.seq().obj(this.key("modulus").int(), this.key("publicExponent").int())
      });
      exports.RSAPublicKey = RSAPublicKey;
      var PublicKey = rfc3280.SubjectPublicKeyInfo;
      exports.PublicKey = PublicKey;
      var ECPublicKey = asn1.define("ECPublicKey", function() {
        this.seq().obj(this.key("algorithm").seq().obj(this.key("id").objid(), this.key("curve").objid()), this.key("subjectPrivateKey").bitstr())
      });
      exports.ECPublicKey = ECPublicKey;
      var ECPrivateWrap = asn1.define("ECPrivateWrap", function() {
        this.seq().obj(this.key("version").int(), this.key("algorithm").seq().obj(this.key("id").objid(), this.key("curve").objid()), this.key("subjectPrivateKey").octstr())
      });
      exports.ECPrivateWrap = ECPrivateWrap;
      var PrivateKeyInfo = asn1.define("PrivateKeyInfo", function() {
        this.seq().obj(this.key("version").int(), this.key("algorithm").use(rfc3280.AlgorithmIdentifier), this.key("subjectPrivateKey").octstr())
      });
      exports.PrivateKey = PrivateKeyInfo;
      var EncryptedPrivateKeyInfo = asn1.define("EncryptedPrivateKeyInfo", function() {
        this.seq().obj(this.key("algorithm").seq().obj(this.key("id").objid(), this.key("decrypt").seq().obj(this.key("kde").seq().obj(this.key("id").objid(), this.key("kdeparams").seq().obj(this.key("salt").octstr(), this.key("iters").int())), this.key("cipher").seq().obj(this.key("algo").objid(), this.key("iv").octstr()))), this.key("subjectPrivateKey").octstr())
      });
      exports.EncryptedPrivateKey = EncryptedPrivateKeyInfo;
      var ECPrivateKey = asn1.define("ECPrivateKey", function() {
        this.seq().obj(this.key("version").int(), this.key("privateKey").octstr(), this.key("parameters").optional().explicit(0).use(ECParameters), this.key("publicKey").optional().explicit(1).bitstr())
      });
      exports.ECPrivateKey = ECPrivateKey;
      var ECParameters = asn1.define("ECParameters", function() {
        this.choice({
          namedCurve: this.objid()
        })
      });
      var ECPrivateKey2 = asn1.define("ECPrivateKey2", function() {
        this.seq().obj(this.key("version").int(), this.key("privateKey").octstr(), this.key("publicKey").seq().obj(this.key("key").bitstr()))
      });
      exports.ECPrivateKey2 = ECPrivateKey2
    }, {
      "asn1.js": 64,
      "asn1.js-rfc3280": 63
    }],
    61: [function(require, module, exports) {
      require("./inject")(module.exports, require("crypto"))
    }, {
      "./inject": 62,
      crypto: 37
    }],
    62: [function(require, module, exports) {
      (function(Buffer) {
        var sign = require("./sign");
        var verify = require("./verify");
        var Writable = require("readable-stream").Writable;
        var inherits = require("inherits");
        var algos = require("./algos");
        "use strict";
        module.exports = function(exports, crypto) {
          exports.createSign = createSign;

          function createSign(algorithm) {
            return new Sign(algorithm, crypto)
          }
          exports.createVerify = createVerify;

          function createVerify(algorithm) {
            return new Verify(algorithm, crypto)
          }
        };
        inherits(Sign, Writable);

        function Sign(algorithm, crypto) {
          Writable.call(this);
          var data = algos[algorithm];
          if (!data) {
            throw new Error("Unknown message digest")
          }
          this._hash = crypto.createHash(data.hash);
          this._tag = data.id;
          this._crypto = crypto
        }
        Sign.prototype._write = function _write(data, _, done) {
          this._hash.update(data);
          done()
        };
        Sign.prototype.update = function update(data) {
          this.write(data);
          return this
        };
        Sign.prototype.sign = function signMethod(key, enc) {
          this.end();
          var hash = this._hash.digest();
          var sig = sign(Buffer.concat([this._tag, hash]), key, this._crypto);
          if (enc) {
            sig = sig.toString(enc)
          }
          return sig
        };
        inherits(Verify, Writable);

        function Verify(algorithm, crypto) {
          Writable.call(this);
          var data = algos[algorithm];
          if (!data) {
            throw new Error("Unknown message digest")
          }
          this._hash = crypto.createHash(data.hash);
          this._tag = data.id
        }
        Verify.prototype._write = function _write(data, _, done) {
          this._hash.update(data);
          done()
        };
        Verify.prototype.update = function update(data) {
          this.write(data);
          return this
        };
        Verify.prototype.verify = function verifyMethod(key, sig, enc) {
          this.end();
          var hash = this._hash.digest();
          if (!Buffer.isBuffer(sig)) {
            sig = new Buffer(sig, enc)
          }
          return verify(sig, Buffer.concat([this._tag, hash]), key)
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./algos": 59,
      "./sign": 109,
      "./verify": 110,
      buffer: 7,
      inherits: 97,
      "readable-stream": 107
    }],
    63: [function(require, module, exports) {
      try {
        var asn1 = require("asn1.js")
      } catch (e) {
        var asn1 = require("../..")
      }
      var CRLReason = asn1.define("CRLReason", function() {
        this.enum({
          0: "unspecified",
          1: "keyCompromise",
          2: "CACompromise",
          3: "affiliationChanged",
          4: "superseded",
          5: "cessationOfOperation",
          6: "certificateHold",
          8: "removeFromCRL",
          9: "privilegeWithdrawn",
          10: "AACompromise"
        })
      });
      exports.CRLReason = CRLReason;
      var AlgorithmIdentifier = asn1.define("AlgorithmIdentifier", function() {
        this.seq().obj(this.key("algorithm").objid(), this.key("parameters").optional().any())
      });
      exports.AlgorithmIdentifier = AlgorithmIdentifier;
      var Certificate = asn1.define("Certificate", function() {
        this.seq().obj(this.key("tbsCertificate").use(TBSCertificate), this.key("signatureAlgorithm").use(AlgorithmIdentifier), this.key("signature").bitstr())
      });
      exports.Certificate = Certificate;
      var TBSCertificate = asn1.define("TBSCertificate", function() {
        this.seq().obj(this.key("version").def("v1").explicit(0).use(Version), this.key("serialNumber").use(CertificateSerialNumber), this.key("signature").use(AlgorithmIdentifier), this.key("issuer").use(Name), this.key("validity").use(Validity), this.key("subject").use(Name), this.key("subjectPublicKeyInfo").use(SubjectPublicKeyInfo), this.key("issuerUniqueID").optional().explicit(1).use(UniqueIdentifier), this.key("subjectUniqueID").optional().explicit(2).use(UniqueIdentifier), this.key("extensions").optional().explicit(3).use(Extensions))
      });
      exports.TBSCertificate = TBSCertificate;
      var Version = asn1.define("Version", function() {
        this.int({
          0: "v1",
          1: "v2",
          2: "v3"
        })
      });
      exports.Version = Version;
      var CertificateSerialNumber = asn1.define("CertificateSerialNumber", function() {
        this.int()
      });
      exports.CertificateSerialNumber = CertificateSerialNumber;
      var Validity = asn1.define("Validity", function() {
        this.seq().obj(this.key("notBefore").use(Time), this.key("notAfter").use(Time))
      });
      exports.Validity = Validity;
      var Time = asn1.define("Time", function() {
        this.choice({
          utcTime: this.utctime(),
          genTime: this.gentime()
        })
      });
      exports.Time = Time;
      var UniqueIdentifier = asn1.define("UniqueIdentifier", function() {
        this.bitstr()
      });
      exports.UniqueIdentifier = UniqueIdentifier;
      var SubjectPublicKeyInfo = asn1.define("SubjectPublicKeyInfo", function() {
        this.seq().obj(this.key("algorithm").use(AlgorithmIdentifier), this.key("subjectPublicKey").bitstr())
      });
      exports.SubjectPublicKeyInfo = SubjectPublicKeyInfo;
      var Extensions = asn1.define("Extensions", function() {
        this.seqof(Extension)
      });
      exports.Extensions = Extensions;
      var Extension = asn1.define("Extension", function() {
        this.seq().obj(this.key("extnID").objid(), this.key("critical").bool().def(false), this.key("extnValue").octstr())
      });
      exports.Extension = Extension;
      var Name = asn1.define("Name", function() {
        this.choice({
          rdn: this.use(RDNSequence)
        })
      });
      exports.Name = Name;
      var RDNSequence = asn1.define("RDNSequence", function() {
        this.seqof(RelativeDistinguishedName)
      });
      exports.RDNSequence = RDNSequence;
      var RelativeDistinguishedName = asn1.define("RelativeDistinguishedName", function() {
        this.setof(AttributeTypeAndValue)
      });
      exports.RelativeDistinguishedName = RelativeDistinguishedName;
      var AttributeTypeAndValue = asn1.define("AttributeTypeAndValue", function() {
        this.seq().obj(this.key("type").use(AttributeType), this.key("value").use(AttributeValue))
      });
      exports.AttributeTypeAndValue = AttributeTypeAndValue;
      var AttributeType = asn1.define("AttributeType", function() {
        this.objid()
      });
      exports.AttributeType = AttributeType;
      var AttributeValue = asn1.define("AttributeValue", function() {
        this.any()
      });
      exports.AttributeValue = AttributeValue
    }, {
      "../..": 61,
      "asn1.js": 64
    }],
    64: [function(require, module, exports) {
      var asn1 = exports;
      asn1.bignum = require("bn.js");
      asn1.define = require("./asn1/api").define;
      asn1.base = require("./asn1/base");
      asn1.constants = require("./asn1/constants");
      asn1.decoders = require("./asn1/decoders");
      asn1.encoders = require("./asn1/encoders")
    }, {
      "./asn1/api": 65,
      "./asn1/base": 67,
      "./asn1/constants": 71,
      "./asn1/decoders": 73,
      "./asn1/encoders": 75,
      "bn.js": 76
    }],
    65: [function(require, module, exports) {
      var asn1 = require("../asn1");
      var util = require("util");
      var vm = require("vm");
      var api = exports;
      api.define = function define(name, body) {
        return new Entity(name, body)
      };

      function Entity(name, body) {
        this.name = name;
        this.body = body;
        this.decoders = {};
        this.encoders = {}
      }
      Entity.prototype._createNamed = function createNamed(base) {
        var named = vm.runInThisContext("(function " + this.name + "(entity) {\n" + "  this._initNamed(entity);\n" + "})");
        util.inherits(named, base);
        named.prototype._initNamed = function initnamed(entity) {
          base.call(this, entity)
        };
        return new named(this)
      };
      Entity.prototype._getDecoder = function _getDecoder(enc) {
        if (!this.decoders.hasOwnProperty(enc)) this.decoders[enc] = this._createNamed(asn1.decoders[enc]);
        return this.decoders[enc]
      };
      Entity.prototype.decode = function decode(data, enc, options) {
        return this._getDecoder(enc).decode(data, options)
      };
      Entity.prototype._getEncoder = function _getEncoder(enc) {
        if (!this.encoders.hasOwnProperty(enc)) this.encoders[enc] = this._createNamed(asn1.encoders[enc]);
        return this.encoders[enc]
      };
      Entity.prototype.encode = function encode(data, enc, reporter) {
        return this._getEncoder(enc).encode(data, reporter)
      }
    }, {
      "../asn1": 64,
      util: 29,
      vm: 30
    }],
    66: [function(require, module, exports) {
      var assert = require("assert");
      var util = require("util");
      var Reporter = require("../base").Reporter;
      var Buffer = require("buffer").Buffer;

      function DecoderBuffer(base, options) {
        Reporter.call(this, options);
        if (!Buffer.isBuffer(base)) {
          this.error("Input not Buffer");
          return
        }
        this.base = base;
        this.offset = 0;
        this.length = base.length
      }
      util.inherits(DecoderBuffer, Reporter);
      exports.DecoderBuffer = DecoderBuffer;
      DecoderBuffer.prototype.save = function save() {
        return {
          offset: this.offset
        }
      };
      DecoderBuffer.prototype.restore = function restore(save) {
        var res = new DecoderBuffer(this.base);
        res.offset = save.offset;
        res.length = this.offset;
        this.offset = save.offset;
        return res
      };
      DecoderBuffer.prototype.isEmpty = function isEmpty() {
        return this.offset === this.length
      };
      DecoderBuffer.prototype.readUInt8 = function readUInt8(fail) {
        if (this.offset + 1 <= this.length) return this.base.readUInt8(this.offset++, true);
        else return this.error(fail || "DecoderBuffer overrun")
      };
      DecoderBuffer.prototype.skip = function skip(bytes, fail) {
        if (!(this.offset + bytes <= this.length)) return this.error(fail || "DecoderBuffer overrun");
        var res = new DecoderBuffer(this.base);
        res._reporterState = this._reporterState;
        res.offset = this.offset;
        res.length = this.offset + bytes;
        this.offset += bytes;
        return res
      };
      DecoderBuffer.prototype.raw = function raw(save) {
        return this.base.slice(save ? save.offset : this.offset, this.length)
      };

      function EncoderBuffer(value, reporter) {
        if (Array.isArray(value)) {
          this.length = 0;
          this.value = value.map(function(item) {
            if (!(item instanceof EncoderBuffer)) item = new EncoderBuffer(item, reporter);
            this.length += item.length;
            return item
          }, this)
        } else if (typeof value === "number") {
          if (!(0 <= value && value <= 255)) return reporter.error("non-byte EncoderBuffer value");
          this.value = value;
          this.length = 1
        } else if (typeof value === "string") {
          this.value = value;
          this.length = Buffer.byteLength(value)
        } else if (Buffer.isBuffer(value)) {
          this.value = value;
          this.length = value.length
        } else {
          return reporter.error("Unsupported type: " + typeof value)
        }
      }
      exports.EncoderBuffer = EncoderBuffer;
      EncoderBuffer.prototype.join = function join(out, offset) {
        if (!out) out = new Buffer(this.length);
        if (!offset) offset = 0;
        if (this.length === 0) return out;
        if (Array.isArray(this.value)) {
          this.value.forEach(function(item) {
            item.join(out, offset);
            offset += item.length
          })
        } else {
          if (typeof this.value === "number") out[offset] = this.value;
          else if (typeof this.value === "string") out.write(this.value, offset);
          else if (Buffer.isBuffer(this.value)) this.value.copy(out, offset);
          offset += this.length
        }
        return out
      }
    }, {
      "../base": 67,
      assert: 5,
      buffer: 7,
      util: 29
    }],
    67: [function(require, module, exports) {
      var base = exports;
      base.Reporter = require("./reporter").Reporter;
      base.DecoderBuffer = require("./buffer").DecoderBuffer;
      base.EncoderBuffer = require("./buffer").EncoderBuffer;
      base.Node = require("./node")
    }, {
      "./buffer": 66,
      "./node": 68,
      "./reporter": 69
    }],
    68: [function(require, module, exports) {
      var assert = require("assert");
      var Reporter = require("../base").Reporter;
      var EncoderBuffer = require("../base").EncoderBuffer;
      var tags = ["seq", "seqof", "set", "setof", "octstr", "bitstr", "objid", "bool", "gentime", "utctime", "null_", "enum", "int", "ia5str"];
      var methods = ["key", "obj", "use", "optional", "explicit", "implicit", "def", "choice", "any"].concat(tags);
      var overrided = ["_peekTag", "_decodeTag", "_use", "_decodeStr", "_decodeObjid", "_decodeTime", "_decodeNull", "_decodeInt", "_decodeBool", "_decodeList", "_encodeComposite", "_encodeStr", "_encodeObjid", "_encodeTime", "_encodeNull", "_encodeInt", "_encodeBool"];

      function Node(enc, parent) {
        var state = {};
        this._baseState = state;
        state.enc = enc;
        state.parent = parent || null;
        state.children = null;
        state.tag = null;
        state.args = null;
        state.reverseArgs = null;
        state.choice = null;
        state.optional = false;
        state.any = false;
        state.obj = false;
        state.use = null;
        state.useDecoder = null;
        state.key = null;
        state["default"] = null;
        state.explicit = null;
        state.implicit = null;
        if (!state.parent) {
          state.children = [];
          this._wrap()
        }
      }
      module.exports = Node;
      var stateProps = ["enc", "parent", "children", "tag", "args", "reverseArgs", "choice", "optional", "any", "obj", "use", "alteredUse", "key", "default", "explicit", "implicit"];
      Node.prototype.clone = function clone() {
        var state = this._baseState;
        var cstate = {};
        stateProps.forEach(function(prop) {
          cstate[prop] = state[prop]
        });
        var res = new this.constructor(cstate.parent);
        res._baseState = cstate;
        return res
      };
      Node.prototype._wrap = function wrap() {
        var state = this._baseState;
        methods.forEach(function(method) {
          this[method] = function _wrappedMethod() {
            var clone = new this.constructor(this);
            state.children.push(clone);
            return clone[method].apply(clone, arguments)
          }
        }, this)
      };
      Node.prototype._init = function init(body) {
        var state = this._baseState;
        assert(state.parent === null);
        body.call(this);
        state.children = state.children.filter(function(child) {
          return child._baseState.parent === this
        }, this);
        assert.equal(state.children.length, 1, "Root node can have only one child")
      };
      Node.prototype._useArgs = function useArgs(args) {
        var state = this._baseState;
        var children = args.filter(function(arg) {
          return arg instanceof this.constructor
        }, this);
        args = args.filter(function(arg) {
          return !(arg instanceof this.constructor)
        }, this);
        if (children.length !== 0) {
          assert(state.children === null);
          state.children = children;
          children.forEach(function(child) {
            child._baseState.parent = this
          }, this)
        }
        if (args.length !== 0) {
          assert(state.args === null);
          state.args = args;
          state.reverseArgs = args.map(function(arg) {
            if (typeof arg !== "object" || arg.constructor !== Object) return arg;
            var res = {};
            Object.keys(arg).forEach(function(key) {
              if (key == (key | 0)) key |= 0;
              var value = arg[key];
              res[value] = key
            });
            return res
          })
        }
      };
      overrided.forEach(function(method) {
        Node.prototype[method] = function _overrided() {
          var state = this._baseState;
          throw new Error(method + " not implemented for encoding: " + state.enc)
        }
      });
      tags.forEach(function(tag) {
        Node.prototype[tag] = function _tagMethod() {
          var state = this._baseState;
          var args = Array.prototype.slice.call(arguments);
          assert(state.tag === null);
          state.tag = tag;
          this._useArgs(args);
          return this
        }
      });
      Node.prototype.use = function use(item) {
        var state = this._baseState;
        assert(state.use === null);
        state.use = item;
        return this
      };
      Node.prototype.optional = function optional() {
        var state = this._baseState;
        state.optional = true;
        return this
      };
      Node.prototype.def = function def(val) {
        var state = this._baseState;
        assert(state["default"] === null);
        state["default"] = val;
        state.optional = true;
        return this
      };
      Node.prototype.explicit = function explicit(num) {
        var state = this._baseState;
        assert(state.explicit === null && state.implicit === null);
        state.explicit = num;
        return this
      };
      Node.prototype.implicit = function implicit(num) {
        var state = this._baseState;
        assert(state.explicit === null && state.implicit === null);
        state.implicit = num;
        return this
      };
      Node.prototype.obj = function obj() {
        var state = this._baseState;
        var args = Array.prototype.slice.call(arguments);
        state.obj = true;
        if (args.length !== 0) this._useArgs(args);
        return this
      };
      Node.prototype.key = function key(key) {
        var state = this._baseState;
        assert(state.key === null);
        state.key = key;
        return this
      };
      Node.prototype.any = function any() {
        var state = this._baseState;
        state.any = true;
        return this
      };
      Node.prototype.choice = function choice(obj) {
        var state = this._baseState;
        assert(state.choice === null);
        state.choice = obj;
        this._useArgs(Object.keys(obj).map(function(key) {
          return obj[key]
        }));
        return this
      };
      Node.prototype._decode = function decode(input) {
        var state = this._baseState;
        if (state.parent === null) return input.wrapResult(state.children[0]._decode(input));
        var result = state["default"];
        var present = true;
        var prevKey;
        if (state.key !== null) prevKey = input.enterKey(state.key);
        if (state.optional) {
          present = this._peekTag(input, state.explicit !== null ? state.explicit : state.implicit !== null ? state.implicit : state.tag || 0);
          if (input.isError(present)) return present
        }
        var prevObj;
        if (state.obj && present) prevObj = input.enterObject();
        if (present) {
          if (state.explicit !== null) {
            var explicit = this._decodeTag(input, state.explicit);
            if (input.isError(explicit)) return explicit;
            input = explicit
          }
          if (state.use === null && state.choice === null) {
            if (state.any) var save = input.save();
            var body = this._decodeTag(input, state.implicit !== null ? state.implicit : state.tag, state.any);
            if (input.isError(body)) return body;
            if (state.any) result = input.raw(save);
            else input = body
          }
          if (state.any) result = result;
          else if (state.choice === null) result = this._decodeGeneric(state.tag, input);
          else result = this._decodeChoice(input);
          if (input.isError(result)) return result;
          if (!state.any && state.choice === null && state.children !== null) {
            var fail = state.children.some(function decodeChildren(child) {
              child._decode(input)
            });
            if (fail) return err
          }
        }
        if (state.obj && present) result = input.leaveObject(prevObj);
        if (state.key !== null && (result !== null || present === true)) input.leaveKey(prevKey, state.key, result);
        return result
      };
      Node.prototype._decodeGeneric = function decodeGeneric(tag, input) {
        var state = this._baseState;
        if (tag === "seq" || tag === "set") return null;
        if (tag === "seqof" || tag === "setof") return this._decodeList(input, tag, state.args[0]);
        else if (tag === "octstr" || tag === "bitstr" || tag === "ia5str") return this._decodeStr(input, tag);
        else if (tag === "objid" && state.args) return this._decodeObjid(input, state.args[0], state.args[1]);
        else if (tag === "objid") return this._decodeObjid(input, null, null);
        else if (tag === "gentime" || tag === "utctime") return this._decodeTime(input, tag);
        else if (tag === "null_") return this._decodeNull(input);
        else if (tag === "bool") return this._decodeBool(input);
        else if (tag === "int" || tag === "enum") return this._decodeInt(input, state.args && state.args[0]);
        else if (state.use !== null) return this._getUse(state.use, input._reporterState.obj)._decode(input);
        else return input.error("unknown tag: " + tag);
        return null
      };
      Node.prototype._getUse = function _getUse(entity, obj) {
        var state = this._baseState;
        state.useDecoder = this._use(entity, obj);
        assert(state.useDecoder._baseState.parent === null);
        state.useDecoder = state.useDecoder._baseState.children[0];
        if (state.implicit !== state.useDecoder._baseState.implicit) {
          state.useDecoder = state.useDecoder.clone();
          state.useDecoder._baseState.implicit = state.implicit
        }
        return state.useDecoder
      };
      Node.prototype._decodeChoice = function decodeChoice(input) {
        var state = this._baseState;
        var result = null;
        var match = false;
        Object.keys(state.choice).some(function(key) {
          var save = input.save();
          var node = state.choice[key];
          try {
            var value = node._decode(input);
            if (input.isError(value)) return false;
            result = {
              type: key,
              value: value
            };
            match = true
          } catch (e) {
            input.restore(save);
            return false
          }
          return true
        }, this);
        if (!match) return input.error("Choice not matched");
        return result
      };
      Node.prototype._createEncoderBuffer = function createEncoderBuffer(data) {
        return new EncoderBuffer(data, this.reporter)
      };
      Node.prototype._encode = function encode(data, reporter, parent) {
        var state = this._baseState;
        if (state["default"] !== null && state["default"] === data) return;
        var result = this._encodeValue(data, reporter, parent);
        if (result === undefined) return;
        if (this._skipDefault(result, reporter, parent)) return;
        return result
      };
      Node.prototype._encodeValue = function encode(data, reporter, parent) {
        var state = this._baseState;
        if (state.parent === null) return state.children[0]._encode(data, reporter || new Reporter);
        var result = null;
        var present = true;
        this.reporter = reporter;
        if (state.optional && data === undefined) {
          if (state["default"] !== null) data = state["default"];
          else return
        }
        var prevKey;
        var content = null;
        var primitive = false;
        if (state.any) {
          result = this._createEncoderBuffer(data)
        } else if (state.choice) {
          result = this._encodeChoice(data, reporter)
        } else if (state.children) {
          content = state.children.map(function(child) {
            if (child._baseState.tag === "null_") return child._encode(null, reporter, data);
            if (child._baseState.key === null) return reporter.error("Child should have a key");
            var prevKey = reporter.enterKey(child._baseState.key);
            if (typeof data !== "object") return reporter.error("Child expected, but input is not object");
            var res = child._encode(data[child._baseState.key], reporter, data);
            reporter.leaveKey(prevKey);
            return res
          }, this).filter(function(child) {
            return child
          });
          content = this._createEncoderBuffer(content)
        } else {
          if (state.tag === "seqof" || state.tag === "setof") {
            if (!(state.args && state.args.length === 1)) return reporter.error("Too many args for : " + state.tag);
            if (!Array.isArray(data)) return reporter.error("seqof/setof, but data is not Array");
            var child = this.clone();
            child._baseState.implicit = null;
            content = this._createEncoderBuffer(data.map(function(item) {
              var state = this._baseState;
              return this._getUse(state.args[0], data)._encode(item, reporter)
            }, child))
          } else if (state.use !== null) {
            result = this._getUse(state.use, parent)._encode(data, reporter)
          } else {
            content = this._encodePrimitive(state.tag, data);
            primitive = true
          }
        }
        var result;
        if (!state.any && state.choice === null) {
          var tag = state.implicit !== null ? state.implicit : state.tag;
          var cls = state.implicit === null ? "universal" : "context";
          if (tag === null) {
            if (state.use === null) reporter.error("Tag could be ommited only for .use()")
          } else {
            if (state.use === null) result = this._encodeComposite(tag, primitive, cls, content)
          }
        }
        if (state.explicit !== null) result = this._encodeComposite(state.explicit, false, "context", result);
        return result
      };
      Node.prototype._encodeChoice = function encodeChoice(data, reporter) {
        var state = this._baseState;
        var node = state.choice[data.type];
        if (!node) {
          assert(false, data.type + " not found in " + JSON.stringify(Object.keys(state.choice)))
        }
        return node._encode(data.value, reporter)
      };
      Node.prototype._encodePrimitive = function encodePrimitive(tag, data) {
        var state = this._baseState;
        if (tag === "octstr" || tag === "bitstr" || tag === "ia5str") return this._encodeStr(data, tag);
        else if (tag === "objid" && state.args) return this._encodeObjid(data, state.reverseArgs[0], state.args[1]);
        else if (tag === "objid") return this._encodeObjid(data, null, null);
        else if (tag === "gentime" || tag === "utctime") return this._encodeTime(data, tag);
        else if (tag === "null_") return this._encodeNull();
        else if (tag === "int" || tag === "enum") return this._encodeInt(data, state.args && state.reverseArgs[0]);
        else if (tag === "bool") return this._encodeBool(data);
        else throw new Error("Unsupported tag: " + tag)
      }
    }, {
      "../base": 67,
      assert: 5
    }],
    69: [function(require, module, exports) {
      var util = require("util");

      function Reporter(options) {
        this._reporterState = {
          obj: null,
          path: [],
          options: options || {},
          errors: []
        }
      }
      exports.Reporter = Reporter;
      Reporter.prototype.isError = function isError(obj) {
        return obj instanceof ReporterError
      };
      Reporter.prototype.enterKey = function enterKey(key) {
        return this._reporterState.path.push(key)
      };
      Reporter.prototype.leaveKey = function leaveKey(index, key, value) {
        var state = this._reporterState;
        state.path = state.path.slice(0, index - 1);
        if (state.obj !== null) state.obj[key] = value
      };
      Reporter.prototype.enterObject = function enterObject() {
        var state = this._reporterState;
        var prev = state.obj;
        state.obj = {};
        return prev
      };
      Reporter.prototype.leaveObject = function leaveObject(prev) {
        var state = this._reporterState;
        var now = state.obj;
        state.obj = prev;
        return now
      };
      Reporter.prototype.error = function error(msg) {
        var err;
        var state = this._reporterState;
        var inherited = msg instanceof ReporterError;
        if (inherited) {
          err = msg
        } else {
          err = new ReporterError(state.path.map(function(elem) {
            return "[" + JSON.stringify(elem) + "]"
          }).join(""), msg.message || msg, msg.stack)
        }
        if (!state.options.partial) throw err;
        if (!inherited) state.errors.push(err);
        return err
      };
      Reporter.prototype.wrapResult = function wrapResult(result) {
        var state = this._reporterState;
        if (!state.options.partial) return result;
        return {
          result: this.isError(result) ? null : result,
          errors: state.errors
        }
      };

      function ReporterError(path, msg) {
        this.path = path;
        this.rethrow(msg)
      }
      util.inherits(ReporterError, Error);
      ReporterError.prototype.rethrow = function rethrow(msg) {
        this.message = msg + " at: " + (this.path || "(shallow)");
        Error.captureStackTrace(this, ReporterError);
        return this
      }
    }, {
      util: 29
    }],
    70: [function(require, module, exports) {
      var constants = require("../constants");
      exports.tagClass = {
        0: "universal",
        1: "application",
        2: "context",
        3: "private"
      };
      exports.tagClassByName = constants._reverse(exports.tagClass);
      exports.tag = {
        0: "end",
        1: "bool",
        2: "int",
        3: "bitstr",
        4: "octstr",
        5: "null_",
        6: "objid",
        7: "objDesc",
        8: "external",
        9: "real",
        10: "enum",
        11: "embed",
        12: "utf8str",
        13: "relativeOid",
        16: "seq",
        17: "set",
        18: "numstr",
        19: "printstr",
        20: "t61str",
        21: "videostr",
        22: "ia5str",
        23: "utctime",
        24: "gentime",
        25: "graphstr",
        26: "iso646str",
        27: "genstr",
        28: "unistr",
        29: "charstr",
        30: "bmpstr"
      };
      exports.tagByName = constants._reverse(exports.tag)
    }, {
      "../constants": 71
    }],
    71: [function(require, module, exports) {
      var constants = exports;
      constants._reverse = function reverse(map) {
        var res = {};
        Object.keys(map).forEach(function(key) {
          if ((key | 0) == key) key = key | 0;
          var value = map[key];
          res[value] = key
        });
        return res
      };
      constants.der = require("./der")
    }, {
      "./der": 70
    }],
    72: [function(require, module, exports) {
      var util = require("util");
      var asn1 = require("../../asn1");
      var base = asn1.base;
      var bignum = asn1.bignum;
      var der = asn1.constants.der;

      function DERDecoder(entity) {
        this.enc = "der";
        this.name = entity.name;
        this.entity = entity;
        this.tree = new DERNode;
        this.tree._init(entity.body)
      }
      module.exports = DERDecoder;
      DERDecoder.prototype.decode = function decode(data, options) {
        if (!(data instanceof base.DecoderBuffer)) data = new base.DecoderBuffer(data, options);
        return this.tree._decode(data, options)
      };

      function DERNode(parent) {
        base.Node.call(this, "der", parent)
      }
      util.inherits(DERNode, base.Node);
      DERNode.prototype._peekTag = function peekTag(buffer, tag) {
        if (buffer.isEmpty()) return false;
        var state = buffer.save();
        var decodedTag = derDecodeTag(buffer, 'Failed to peek tag: "' + tag + '"');
        if (buffer.isError(decodedTag)) return decodedTag;
        buffer.restore(state);
        return decodedTag.tag === tag || decodedTag.tagStr === tag
      };
      DERNode.prototype._decodeTag = function decodeTag(buffer, tag, any) {
        var decodedTag = derDecodeTag(buffer, 'Failed to decode tag of "' + tag + '"');
        if (buffer.isError(decodedTag)) return decodedTag;
        var len = derDecodeLen(buffer, decodedTag.primitive, 'Failed to get length of "' + tag + '"');
        if (buffer.isError(len)) return len;
        if (!any && decodedTag.tag !== tag && decodedTag.tagStr !== tag && decodedTag.tagStr + "of" !== tag) {
          return buffer.error('Failed to match tag: "' + tag + '"')
        }
        if (decodedTag.primitive || len !== null) return buffer.skip(len, 'Failed to match body of: "' + tag + '"');
        var state = buffer.start();
        var res = this._skipUntilEnd(buffer, 'Failed to skip indefinite length body: "' + this.tag + '"');
        if (buffer.isError(res)) return res;
        return buffer.cut(state)
      };
      DERNode.prototype._skipUntilEnd = function skipUntilEnd(buffer, fail) {
        while (true) {
          var tag = derDecodeTag(buffer, fail);
          if (buffer.isError(tag)) return tag;
          var len = derDecodeLen(buffer, tag.primitive, fail);
          if (buffer.isError(len)) return len;
          var res;
          if (tag.primitive || len !== null) res = buffer.skip(len);
          else res = this._skipUntilEnd(buffer, fail);
          if (buffer.isError(res)) return res;
          if (tag.tagStr === "end") break
        }
      };
      DERNode.prototype._decodeList = function decodeList(buffer, tag, decoder) {
        var result = [];
        while (!buffer.isEmpty()) {
          var possibleEnd = this._peekTag(buffer, "end");
          if (buffer.isError(possibleEnd)) return possibleEnd;
          var res = decoder.decode(buffer, "der");
          if (buffer.isError(res) && possibleEnd) break;
          result.push(res)
        }
        return result
      };
      DERNode.prototype._decodeStr = function decodeStr(buffer, tag) {
        if (tag === "octstr") {
          return buffer.raw()
        } else if (tag === "bitstr") {
          var unused = buffer.readUInt8();
          if (buffer.isError(unused)) return unused;
          return {
            unused: unused,
            data: buffer.raw()
          }
        } else if (tag === "ia5str") {
          return buffer.raw().toString()
        } else {
          return this.error("Decoding of string type: " + tag + " unsupported")
        }
      };
      DERNode.prototype._decodeObjid = function decodeObjid(buffer, values, relative) {
        var identifiers = [];
        var ident = 0;
        while (!buffer.isEmpty()) {
          var subident = buffer.readUInt8();
          ident <<= 7;
          ident |= subident & 127;
          if ((subident & 128) === 0) {
            identifiers.push(ident);
            ident = 0
          }
        }
        if (subident & 128) identifiers.push(ident);
        var first = identifiers[0] / 40 | 0;
        var second = identifiers[0] % 40;
        if (relative) result = identifiers;
        else result = [first, second].concat(identifiers.slice(1));
        if (values) result = values[result.join(" ")];
        return result
      };
      DERNode.prototype._decodeTime = function decodeTime(buffer, tag) {
        var str = buffer.raw().toString();
        if (tag === "gentime") {
          var year = str.slice(0, 4) | 0;
          var mon = str.slice(4, 6) | 0;
          var day = str.slice(6, 8) | 0;
          var hour = str.slice(8, 10) | 0;
          var min = str.slice(10, 12) | 0;
          var sec = str.slice(12, 14) | 0
        } else if (tag === "utctime") {
          var year = str.slice(0, 2) | 0;
          var mon = str.slice(2, 4) | 0;
          var day = str.slice(4, 6) | 0;
          var hour = str.slice(6, 8) | 0;
          var min = str.slice(8, 10) | 0;
          var sec = str.slice(10, 12) | 0;
          if (year < 70) year = 2e3 + year;
          else year = 1900 + year
        } else {
          return this.error("Decoding " + tag + " time is not supported yet")
        }
        return Date.UTC(year, mon - 1, day, hour, min, sec, 0)
      };
      DERNode.prototype._decodeNull = function decodeNull(buffer) {
        return null
      };
      DERNode.prototype._decodeBool = function decodeBool(buffer) {
        var res = buffer.readUInt8();
        if (buffer.isError(res)) return res;
        else return res !== 0
      };
      DERNode.prototype._decodeInt = function decodeInt(buffer, values) {
        var res = 0;
        var raw = buffer.raw();
        if (raw.length > 3) return new bignum(raw);
        while (!buffer.isEmpty()) {
          res <<= 8;
          var i = buffer.readUInt8();
          if (buffer.isError(i)) return i;
          res |= i
        }
        if (values) res = values[res] || res;
        return res
      };
      DERNode.prototype._use = function use(entity, obj) {
        if (typeof entity === "function") entity = entity(obj);
        return entity._getDecoder("der").tree
      };

      function derDecodeTag(buf, fail) {
        var tag = buf.readUInt8(fail);
        if (buf.isError(tag)) return tag;
        var cls = der.tagClass[tag >> 6];
        var primitive = (tag & 32) === 0;
        if ((tag & 31) === 31) {
          var oct = tag;
          tag = 0;
          while ((oct & 128) === 128) {
            oct = buf.readUInt8(fail);
            if (buf.isError(oct)) return oct;
            tag <<= 7;
            tag |= oct & 127
          }
        } else {
          tag &= 31
        }
        var tagStr = der.tag[tag];
        return {
          cls: cls,
          primitive: primitive,
          tag: tag,
          tagStr: tagStr
        }
      }

      function derDecodeLen(buf, primitive, fail) {
        var len = buf.readUInt8(fail);
        if (buf.isError(len)) return len;
        if (!primitive && len === 128) return null;
        if ((len & 128) === 0) {
          return len
        }
        var num = len & 127;
        if (num >= 4) return buf.error("length octect is too long");
        len = 0;
        for (var i = 0; i < num; i++) {
          len <<= 8;
          var j = buf.readUInt8(fail);
          if (buf.isError(j)) return j;
          len |= j
        }
        return len
      }
    }, {
      "../../asn1": 64,
      util: 29
    }],
    73: [function(require, module, exports) {
      var decoders = exports;
      decoders.der = require("./der")
    }, {
      "./der": 72
    }],
    74: [function(require, module, exports) {
      var util = require("util");
      var Buffer = require("buffer").Buffer;
      var asn1 = require("../../asn1");
      var base = asn1.base;
      var bignum = asn1.bignum;
      var der = asn1.constants.der;

      function DEREncoder(entity) {
        this.enc = "der";
        this.name = entity.name;
        this.entity = entity;
        this.tree = new DERNode;
        this.tree._init(entity.body)
      }
      module.exports = DEREncoder;
      DEREncoder.prototype.encode = function encode(data, reporter) {
        return this.tree._encode(data, reporter).join()
      };

      function DERNode(parent) {
        base.Node.call(this, "der", parent)
      }
      util.inherits(DERNode, base.Node);
      DERNode.prototype._encodeComposite = function encodeComposite(tag, primitive, cls, content) {
        var encodedTag = encodeTag(tag, primitive, cls, this.reporter);
        if (content.length < 128) {
          var header = new Buffer(2);
          header[0] = encodedTag;
          header[1] = content.length;
          return this._createEncoderBuffer([header, content])
        }
        var lenOctets = 1;
        for (var i = content.length; i >= 256; i >>= 8) lenOctets++;
        var header = new Buffer(1 + 1 + lenOctets);
        header[0] = encodedTag;
        header[1] = 128 | lenOctets;
        for (var i = 1 + lenOctets, j = content.length; j > 0; i--, j >>= 8) header[i] = j & 255;
        return this._createEncoderBuffer([header, content])
      };
      DERNode.prototype._encodeStr = function encodeStr(str, tag) {
        if (tag === "octstr") return this._createEncoderBuffer(str);
        else if (tag === "bitstr") return this._createEncoderBuffer([str.unused | 0, str.data]);
        else if (tag === "ia5str") return this._createEncoderBuffer(str);
        return this.reporter.error("Encoding of string type: " + tag + " unsupported")
      };
      DERNode.prototype._encodeObjid = function encodeObjid(id, values, relative) {
        if (typeof id === "string") {
          if (!values) return this.reporter.error("string objid given, but no values map found");
          if (!values.hasOwnProperty(id)) return this.reporter.error("objid not found in values map");
          id = values[id].split(/\s+/g);
          for (var i = 0; i < id.length; i++) id[i] |= 0
        } else if (Array.isArray(id)) {
          id = id.slice()
        }
        if (!Array.isArray(id)) {
          return this.reporter.error("objid() should be either array or string, " + "got: " + JSON.stringify(id))
        }
        if (!relative) {
          if (id[1] >= 40) return this.reporter.error("Second objid identifier OOB");
          id.splice(0, 2, id[0] * 40 + id[1])
        }
        var size = 0;
        for (var i = 0; i < id.length; i++) {
          var ident = id[i];
          for (size++; ident >= 128; ident >>= 7) size++
        }
        var objid = new Buffer(size);
        var offset = objid.length - 1;
        for (var i = id.length - 1; i >= 0; i--) {
          var ident = id[i];
          objid[offset--] = ident & 127;
          while ((ident >>= 7) > 0) objid[offset--] = 128 | ident & 127
        }
        return this._createEncoderBuffer(objid)
      };

      function two(num) {
        if (num <= 10) return "0" + num;
        else return num
      }
      DERNode.prototype._encodeTime = function encodeTime(time, tag) {
        var str;
        var date = new Date(time);
        if (tag === "gentime") {
          str = [date.getFullYear(), two(date.getUTCMonth() + 1), two(date.getUTCDate()), two(date.getUTCHours()), two(date.getUTCMinutes()), two(date.getUTCSeconds()), "Z"].join("")
        } else if (tag === "utctime") {
          str = [date.getFullYear() % 100, two(date.getUTCMonth() + 1), two(date.getUTCDate()), two(date.getUTCHours()), two(date.getUTCMinutes()), two(date.getUTCSeconds()), "Z"].join("")
        } else {
          this.reporter.error("Encoding " + tag + " time is not supported yet")
        }
        return this._encodeStr(str, "octstr")
      };
      DERNode.prototype._encodeNull = function encodeNull() {
        return this._createEncoderBuffer("")
      };
      DERNode.prototype._encodeInt = function encodeInt(num, values) {
        if (typeof num === "string") {
          if (!values) return this.reporter.error("String int or enum given, but no values map");
          if (!values.hasOwnProperty(num)) {
            return this.reporter.error("Values map doesn't contain: " + JSON.stringify(num))
          }
          num = values[num]
        }
        if (bignum !== null && num instanceof bignum) {
          var numArray = num.toArray();
          if (num.sign === false && numArray[0] & 128) {
            numArray.unshift(0)
          }
          num = new Buffer(numArray)
        }
        if (Buffer.isBuffer(num)) {
          var size = num.length;
          if (num.length === 0) size++;
          var out = new Buffer(size);
          num.copy(out);
          if (num.length === 0) out[0] = 0;
          return this._createEncoderBuffer(out)
        }
        if (num < 128) return this._createEncoderBuffer(num);
        if (num < 256) return this._createEncoderBuffer([0, num]);
        var size = 1;
        for (var i = num; i >= 256; i >>= 8) size++;
        var out = new Array(size);
        for (var i = out.length - 1; i >= 0; i--) {
          out[i] = num & 255;
          num >>= 8
        }
        if (out[0] & 128) {
          out.unshift(0)
        }
        return this._createEncoderBuffer(new Buffer(out))
      };
      DERNode.prototype._encodeBool = function encodeBool(value) {
        return this._createEncoderBuffer(value ? 255 : 0)
      };
      DERNode.prototype._use = function use(entity, obj) {
        if (typeof entity === "function") entity = entity(obj);
        return entity._getEncoder("der").tree
      };
      DERNode.prototype._skipDefault = function skipDefault(dataBuffer, reporter, parent) {
        var state = this._baseState;
        var i;
        if (state["default"] === null) return false;
        var data = dataBuffer.join();
        if (state.defaultBuffer === undefined) state.defaultBuffer = this._encodeValue(state["default"], reporter, parent).join();
        if (data.length !== state.defaultBuffer.length) return false;
        for (i = 0; i < data.length; i++)
          if (data[i] !== state.defaultBuffer[i]) return false;
        return true
      };

      function encodeTag(tag, primitive, cls, reporter) {
        var res;
        if (tag === "seqof") tag = "seq";
        else if (tag === "setof") tag = "set";
        if (der.tagByName.hasOwnProperty(tag)) res = der.tagByName[tag];
        else if (typeof tag === "number" && (tag | 0) === tag) res = tag;
        else return reporter.error("Unknown tag: " + tag);
        if (res >= 31) return reporter.error("Multi-octet tag encoding unsupported");
        if (!primitive) res |= 32;
        res |= der.tagClassByName[cls || "universal"] << 6;
        return res
      }
    }, {
      "../../asn1": 64,
      buffer: 7,
      util: 29
    }],
    75: [function(require, module, exports) {
      var encoders = exports;
      encoders.der = require("./der")
    }, {
      "./der": 74
    }],
    76: [function(require, module, exports) {
      function assert(val, msg) {
        if (!val) throw new Error(msg || "Assertion failed")
      }

      function assertEqual(l, r, msg) {
        if (l != r) throw new Error(msg || "Assertion failed: " + l + " != " + r)
      }

      function inherits(ctor, superCtor) {
        ctor.super_ = superCtor;
        var TempCtor = function() {};
        TempCtor.prototype = superCtor.prototype;
        ctor.prototype = new TempCtor;
        ctor.prototype.constructor = ctor
      }

      function BN(number, base) {
        if (number !== null && typeof number === "object" && Array.isArray(number.words)) {
          return number
        }
        this.sign = false;
        this.words = null;
        this.length = 0;
        this.red = null;
        if (number !== null) this._init(number || 0, base || 10)
      }
      if (typeof module === "object") module.exports = BN;
      BN.BN = BN;
      BN.wordSize = 26;
      BN.prototype._init = function init(number, base) {
        if (typeof number === "number") {
          if (number < 0) {
            this.sign = true;
            number = -number
          }
          if (number < 67108864) {
            this.words = [number & 67108863];
            this.length = 1
          } else {
            this.words = [number & 67108863, number / 67108864 & 67108863];
            this.length = 2
          }
          return
        } else if (typeof number === "object") {
          assert(typeof number.length === "number");
          this.length = Math.ceil(number.length / 3);
          this.words = new Array(this.length);
          for (var i = 0; i < this.length; i++) this.words[i] = 0;
          var off = 0;
          for (var i = number.length - 1, j = 0; i >= 0; i -= 3) {
            var w = number[i] | number[i - 1] << 8 | number[i - 2] << 16;
            this.words[j] |= w << off & 67108863;
            this.words[j + 1] = w >>> 26 - off & 67108863;
            off += 24;
            if (off >= 26) {
              off -= 26;
              j++
            }
          }
          return this.strip()
        }
        if (base === "hex") base = 16;
        assert(base === (base | 0) && base >= 2 && base <= 36);
        number = number.toString().replace(/\s+/g, "");
        var start = 0;
        if (number[0] === "-") start++;
        if (base === 16) this._parseHex(number, start);
        else this._parseBase(number, base, start);
        if (number[0] === "-") this.sign = true;
        this.strip()
      };
      BN.prototype._parseHex = function parseHex(number, start) {
        this.length = Math.ceil((number.length - start) / 6);
        this.words = new Array(this.length);
        for (var i = 0; i < this.length; i++) this.words[i] = 0;
        var off = 0;
        for (var i = number.length - 6, j = 0; i >= start; i -= 6) {
          var w = parseInt(number.slice(i, i + 6), 16);
          this.words[j] |= w << off & 67108863;
          this.words[j + 1] |= w >>> 26 - off & 4194303;
          off += 24;
          if (off >= 26) {
            off -= 26;
            j++
          }
        }
        if (i + 6 !== start) {
          var w = parseInt(number.slice(start, i + 6), 16);
          this.words[j] |= w << off & 67108863;
          this.words[j + 1] |= w >>> 26 - off & 4194303
        }
        this.strip()
      };
      BN.prototype._parseBase = function parseBase(number, base, start) {
        this.words = [0];
        this.length = 1;
        var word = 0;
        var q = 1;
        var p = 0;
        var bigQ = null;
        for (var i = start; i < number.length; i++) {
          var digit;
          var ch = number[i];
          if (base === 10 || ch <= "9") digit = ch | 0;
          else if (ch >= "a") digit = ch.charCodeAt(0) - 97 + 10;
          else digit = ch.charCodeAt(0) - 65 + 10;
          word *= base;
          word += digit;
          q *= base;
          p++;
          if (q > 1048575) {
            assert(q <= 67108863);
            if (!bigQ) bigQ = new BN(q);
            this.mul(bigQ).copy(this);
            this.iadd(new BN(word));
            word = 0;
            q = 1;
            p = 0
          }
        }
        if (p !== 0) {
          this.mul(new BN(q)).copy(this);
          this.iadd(new BN(word))
        }
      };
      BN.prototype.copy = function copy(dest) {
        dest.words = new Array(this.length);
        for (var i = 0; i < this.length; i++) dest.words[i] = this.words[i];
        dest.length = this.length;
        dest.sign = this.sign;
        dest.red = this.red
      };
      BN.prototype.clone = function clone() {
        var r = new BN(null);
        this.copy(r);
        return r
      };
      BN.prototype.strip = function strip() {
        while (this.length > 1 && this.words[this.length - 1] === 0) this.length--;
        return this._normSign()
      };
      BN.prototype._normSign = function _normSign() {
        if (this.length === 1 && this.words[0] === 0) this.sign = false;
        return this
      };
      BN.prototype.inspect = function inspect() {
        return (this.red ? "<BN-R: " : "<BN: ") + this.toString(16) + ">"
      };
      var zeros = ["", "0", "00", "000", "0000", "00000", "000000", "0000000", "00000000", "000000000", "0000000000", "00000000000", "000000000000", "0000000000000", "00000000000000", "000000000000000", "0000000000000000", "00000000000000000", "000000000000000000", "0000000000000000000", "00000000000000000000", "000000000000000000000", "0000000000000000000000", "00000000000000000000000", "000000000000000000000000", "0000000000000000000000000"];
      var groupSizes = [0, 0, 25, 16, 12, 11, 10, 9, 8, 8, 7, 7, 7, 7, 6, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5];
      var groupBases = [0, 0, 33554432, 43046721, 16777216, 48828125, 60466176, 40353607, 16777216, 43046721, 1e7, 19487171, 35831808, 62748517, 7529536, 11390625, 16777216, 24137569, 34012224, 47045881, 64e6, 4084101, 5153632, 6436343, 7962624, 9765625, 11881376, 14348907, 17210368, 20511149, 243e5, 28629151, 33554432, 39135393, 45435424, 52521875, 60466176];
      BN.prototype.toString = function toString(base, padding) {
        base = base || 10;
        if (base === 16 || base === "hex") {
          var out = "";
          var off = 0;
          var padding = padding | 0 || 1;
          var carry = 0;
          for (var i = 0; i < this.length; i++) {
            var w = this.words[i];
            var word = ((w << off | carry) & 16777215).toString(16);
            carry = w >>> 24 - off & 16777215;
            if (carry !== 0 || i !== this.length - 1) out = zeros[6 - word.length] + word + out;
            else out = word + out;
            off += 2;
            if (off >= 26) {
              off -= 26;
              i--
            }
          }
          if (carry !== 0) out = carry.toString(16) + out;
          while (out.length % padding !== 0) out = "0" + out;
          if (this.sign) out = "-" + out;
          return out
        } else if (base === (base | 0) && base >= 2 && base <= 36) {
          var groupSize = groupSizes[base];
          var groupBase = groupBases[base];
          var out = "";
          var c = this.clone();
          c.sign = false;
          while (c.cmpn(0) !== 0) {
            var r = c.modn(groupBase).toString(base);
            c = c.idivn(groupBase);
            if (c.cmpn(0) !== 0) out = zeros[groupSize - r.length] + r + out;
            else out = r + out
          }
          if (this.cmpn(0) === 0) out = "0" + out;
          if (this.sign) out = "-" + out;
          return out
        } else {
          assert(false, "Base should be between 2 and 36")
        }
      };
      BN.prototype.toJSON = function toJSON() {
        return this.toString(16)
      };
      BN.prototype.toArray = function toArray() {
        this.strip();
        var res = new Array(this.byteLength());
        res[0] = 0;
        var q = this.clone();
        for (var i = 0; q.cmpn(0) !== 0; i++) {
          var b = q.andln(255);
          q.ishrn(8);
          res[res.length - i - 1] = b
        }
        return res
      };
      BN.prototype._countBits = function _countBits(w) {
        return w >= 33554432 ? 26 : w >= 16777216 ? 25 : w >= 8388608 ? 24 : w >= 4194304 ? 23 : w >= 2097152 ? 22 : w >= 1048576 ? 21 : w >= 524288 ? 20 : w >= 262144 ? 19 : w >= 131072 ? 18 : w >= 65536 ? 17 : w >= 32768 ? 16 : w >= 16384 ? 15 : w >= 8192 ? 14 : w >= 4096 ? 13 : w >= 2048 ? 12 : w >= 1024 ? 11 : w >= 512 ? 10 : w >= 256 ? 9 : w >= 128 ? 8 : w >= 64 ? 7 : w >= 32 ? 6 : w >= 16 ? 5 : w >= 8 ? 4 : w >= 4 ? 3 : w >= 2 ? 2 : w >= 1 ? 1 : 0
      };
      BN.prototype.bitLength = function bitLength() {
        var hi = 0;
        var w = this.words[this.length - 1];
        var hi = this._countBits(w);
        return (this.length - 1) * 26 + hi
      };
      BN.prototype.byteLength = function byteLength() {
        var hi = 0;
        var w = this.words[this.length - 1];
        return Math.ceil(this.bitLength() / 8)
      };
      BN.prototype.neg = function neg() {
        if (this.cmpn(0) === 0) return this.clone();
        var r = this.clone();
        r.sign = !this.sign;
        return r
      };
      BN.prototype.iadd = function iadd(num) {
        if (this.sign && !num.sign) {
          this.sign = false;
          var r = this.isub(num);
          this.sign = !this.sign;
          return this._normSign()
        } else if (!this.sign && num.sign) {
          num.sign = false;
          var r = this.isub(num);
          num.sign = true;
          return r._normSign()
        }
        var a;
        var b;
        if (this.length > num.length) {
          a = this;
          b = num
        } else {
          a = num;
          b = this
        }
        var carry = 0;
        for (var i = 0; i < b.length; i++) {
          var r = a.words[i] + b.words[i] + carry;
          this.words[i] = r & 67108863;
          carry = r >>> 26
        }
        for (; carry !== 0 && i < a.length; i++) {
          var r = a.words[i] + carry;
          this.words[i] = r & 67108863;
          carry = r >>> 26
        }
        this.length = a.length;
        if (carry !== 0) {
          this.words[this.length] = carry;
          this.length++
        } else if (a !== this) {
          for (; i < a.length; i++) this.words[i] = a.words[i]
        }
        return this
      };
      BN.prototype.add = function add(num) {
        if (num.sign && !this.sign) {
          num.sign = false;
          var res = this.sub(num);
          num.sign = true;
          return res
        } else if (!num.sign && this.sign) {
          this.sign = false;
          var res = num.sub(this);
          this.sign = true;
          return res
        }
        if (this.length > num.length) return this.clone().iadd(num);
        else return num.clone().iadd(this)
      };
      BN.prototype.isub = function isub(num) {
        if (num.sign) {
          num.sign = false;
          var r = this.iadd(num);
          num.sign = true;
          return r._normSign()
        } else if (this.sign) {
          this.sign = false;
          this.iadd(num);
          this.sign = true;
          return this._normSign()
        }
        var cmp = this.cmp(num);
        if (cmp === 0) {
          this.sign = false;
          this.length = 1;
          this.words[0] = 0;
          return this
        }
        if (cmp > 0) {
          var a = this;
          var b = num
        } else {
          var a = num;
          var b = this
        }
        var carry = 0;
        for (var i = 0; i < b.length; i++) {
          var r = a.words[i] - b.words[i] - carry;
          if (r < 0) {
            r += 67108864;
            carry = 1
          } else {
            carry = 0
          }
          this.words[i] = r
        }
        for (; carry !== 0 && i < a.length; i++) {
          var r = a.words[i] - carry;
          if (r < 0) {
            r += 67108864;
            carry = 1
          } else {
            carry = 0
          }
          this.words[i] = r
        }
        if (carry === 0 && i < a.length && a !== this)
          for (; i < a.length; i++) this.words[i] = a.words[i];
        this.length = Math.max(this.length, i);
        if (a !== this) this.sign = true;
        return this.strip()
      };
      BN.prototype.sub = function sub(num) {
        return this.clone().isub(num)
      };
      BN.prototype._smallMulTo = function _smallMulTo(num, out) {
        out.sign = num.sign !== this.sign;
        out.length = this.length + num.length;
        var carry = 0;
        for (var k = 0; k < out.length - 1; k++) {
          var ncarry = carry >>> 26;
          var rword = carry & 67108863;
          var maxJ = Math.min(k, num.length - 1);
          for (var j = Math.max(0, k - this.length + 1); j <= maxJ; j++) {
            var i = k - j;
            var a = this.words[i] | 0;
            var b = num.words[j] | 0;
            var r = a * b;
            var lo = r & 67108863;
            ncarry = ncarry + (r / 67108864 | 0) | 0;
            lo = lo + rword | 0;
            rword = lo & 67108863;
            ncarry = ncarry + (lo >>> 26) | 0
          }
          out.words[k] = rword;
          carry = ncarry
        }
        if (carry !== 0) {
          out.words[k] = carry
        } else {
          out.length--
        }
        return out.strip()
      };
      BN.prototype._bigMulTo = function _bigMulTo(num, out) {
        out.sign = num.sign !== this.sign;
        out.length = this.length + num.length;
        var carry = 0;
        var hncarry = 0;
        for (var k = 0; k < out.length - 1; k++) {
          var ncarry = hncarry;
          hncarry = 0;
          var rword = carry & 67108863;
          var maxJ = Math.min(k, num.length - 1);
          for (var j = Math.max(0, k - this.length + 1); j <= maxJ; j++) {
            var i = k - j;
            var a = this.words[i] | 0;
            var b = num.words[j] | 0;
            var r = a * b;
            var lo = r & 67108863;
            ncarry = ncarry + (r / 67108864 | 0) | 0;
            lo = lo + rword | 0;
            rword = lo & 67108863;
            ncarry = ncarry + (lo >>> 26) | 0;
            hncarry += ncarry >>> 26;
            ncarry &= 67108863
          }
          out.words[k] = rword;
          carry = ncarry;
          ncarry = hncarry
        }
        if (carry !== 0) {
          out.words[k] = carry
        } else {
          out.length--
        }
        return out.strip()
      };
      BN.prototype.mulTo = function mulTo(num, out) {
        var res;
        if (this.length + num.length < 63) res = this._smallMulTo(num, out);
        else res = this._bigMulTo(num, out);
        return res
      };
      BN.prototype.mul = function mul(num) {
        var out = new BN(null);
        out.words = new Array(this.length + num.length);
        return this.mulTo(num, out)
      };
      BN.prototype.imul = function imul(num) {
        if (this.cmpn(0) === 0 || num.cmpn(0) === 0) {
          this.words[0] = 0;
          this.length = 1;
          return this
        }
        var tlen = this.length;
        var nlen = num.length;
        this.sign = num.sign !== this.sign;
        this.length = this.length + num.length;
        this.words[this.length - 1] = 0;
        var lastCarry = 0;
        for (var k = this.length - 2; k >= 0; k--) {
          var carry = 0;
          var rword = 0;
          var maxJ = Math.min(k, nlen - 1);
          for (var j = Math.max(0, k - tlen + 1); j <= maxJ; j++) {
            var i = k - j;
            var a = this.words[i];
            var b = num.words[j];
            var r = a * b;
            var lo = r & 67108863;
            carry += r / 67108864 | 0;
            lo += rword;
            rword = lo & 67108863;
            carry += lo >>> 26
          }
          this.words[k] = rword;
          this.words[k + 1] += carry;
          carry = 0
        }
        var carry = 0;
        for (var i = 1; i < this.length; i++) {
          var w = this.words[i] + carry;
          this.words[i] = w & 67108863;
          carry = w >>> 26
        }
        return this.strip()
      };
      BN.prototype.sqr = function sqr() {
        return this.mul(this)
      };
      BN.prototype.isqr = function isqr() {
        return this.mul(this)
      };
      BN.prototype.ishln = function ishln(bits) {
        assert(typeof bits === "number" && bits >= 0);
        var r = bits % 26;
        var s = (bits - r) / 26;
        var carryMask = 67108863 >>> 26 - r << 26 - r;
        var o = this.clone();
        if (r !== 0) {
          var carry = 0;
          for (var i = 0; i < this.length; i++) {
            var newCarry = this.words[i] & carryMask;
            var c = this.words[i] - newCarry << r;
            this.words[i] = c | carry;
            carry = newCarry >>> 26 - r
          }
          if (carry) {
            this.words[i] = carry;
            this.length++
          }
        }
        if (s !== 0) {
          for (var i = this.length - 1; i >= 0; i--) this.words[i + s] = this.words[i];
          for (var i = 0; i < s; i++) this.words[i] = 0;
          this.length += s
        }
        return this.strip()
      };
      BN.prototype.ishrn = function ishrn(bits, hint, extended) {
        assert(typeof bits === "number" && bits >= 0);
        if (hint) hint = (hint - hint % 26) / 26;
        else hint = 0;
        var r = bits % 26;
        var s = Math.min((bits - r) / 26, this.length);
        var mask = 67108863 ^ 67108863 >>> r << r;
        var maskedWords = extended;
        hint -= s;
        hint = Math.max(0, hint);
        if (maskedWords) {
          for (var i = 0; i < s; i++) maskedWords.words[i] = this.words[i];
          maskedWords.length = s
        }
        if (s === 0) {} else if (this.length > s) {
          this.length -= s;
          for (var i = 0; i < this.length; i++) this.words[i] = this.words[i + s]
        } else {
          this.words[0] = 0;
          this.length = 1
        }
        var carry = 0;
        for (var i = this.length - 1; i >= 0 && (carry !== 0 || i >= hint); i--) {
          var word = this.words[i];
          this.words[i] = carry << 26 - r | word >>> r;
          carry = word & mask
        }
        if (maskedWords && carry !== 0) maskedWords.words[maskedWords.length++] = carry;
        if (this.length === 0) {
          this.words[0] = 0;
          this.length = 1
        }
        this.strip();
        if (extended) return {
          hi: this,
          lo: maskedWords
        };
        return this
      };
      BN.prototype.shln = function shln(bits) {
        return this.clone().ishln(bits)
      };
      BN.prototype.shrn = function shrn(bits) {
        return this.clone().ishrn(bits)
      };
      BN.prototype.testn = function testn(bit) {
        assert(typeof bit === "number" && bit >= 0);
        var r = bit % 26;
        var s = (bit - r) / 26;
        var q = 1 << r;
        if (this.length <= s) {
          return false
        }
        var w = this.words[s];
        return !!(w & q)
      };
      BN.prototype.imaskn = function imaskn(bits) {
        assert(typeof bits === "number" && bits >= 0);
        var r = bits % 26;
        var s = (bits - r) / 26;
        assert(!this.sign, "imaskn works only with positive numbers");
        if (r !== 0) s++;
        this.length = Math.min(s, this.length);
        if (r !== 0) {
          var mask = 67108863 ^ 67108863 >>> r << r;
          this.words[this.length - 1] &= mask
        }
        return this.strip()
      };
      BN.prototype.maskn = function maskn(bits) {
        return this.clone().imaskn(bits)
      };
      BN.prototype.iaddn = function iaddn(num) {
        assert(typeof num === "number");
        if (num < 0) return this.isubn(-num);
        if (this.sign) {
          if (this.length === 1 && this.words[0] < num) {
            this.words[0] = num - this.words[0];
            this.sign = false;
            return this
          }
          this.sign = false;
          this.isubn(num);
          this.sign = true;
          return this
        }
        this.words[0] += num;
        for (var i = 0; i < this.length && this.words[i] >= 67108864; i++) {
          this.words[i] -= 67108864;
          if (i === this.length - 1) this.words[i + 1] = 1;
          else this.words[i + 1]++
        }
        this.length = Math.max(this.length, i + 1);
        return this
      };
      BN.prototype.isubn = function isubn(num) {
        assert(typeof num === "number");
        if (num < 0) return this.iaddn(-num);
        if (this.sign) {
          this.sign = false;
          this.iaddn(num);
          this.sign = true;
          return this
        }
        this.words[0] -= num;
        for (var i = 0; i < this.length && this.words[i] < 0; i++) {
          this.words[i] += 67108864;
          this.words[i + 1] -= 1
        }
        return this.strip()
      };
      BN.prototype.addn = function addn(num) {
        return this.clone().iaddn(num)
      };
      BN.prototype.subn = function subn(num) {
        return this.clone().isubn(num)
      };
      BN.prototype.iabs = function iabs() {
        this.sign = false;
        return this
      };
      BN.prototype.abs = function abs() {
        return this.clone().iabs()
      };
      BN.prototype._wordDiv = function _wordDiv(num, mode) {
        var shift = this.length - num.length;
        var a = this.clone();
        var b = num;
        var q = mode !== "mod" && new BN(0);
        var sign = false;
        while (a.length > b.length) {
          var hi = a.words[a.length - 1] * 67108864 + a.words[a.length - 2];
          var sq = hi / b.words[b.length - 1];
          var sqhi = sq / 67108864 | 0;
          var sqlo = sq & 67108863;
          sq = new BN(null);
          sq.words = [sqlo, sqhi];
          sq.length = 2;
          var shift = (a.length - b.length - 1) * 26;
          if (q) {
            var t = sq.shln(shift);
            if (a.sign) q.isub(t);
            else q.iadd(t)
          }
          sq = sq.mul(b).ishln(shift);
          if (a.sign) a.iadd(sq);
          else a.isub(sq)
        }
        while (a.ucmp(b) >= 0) {
          var hi = a.words[a.length - 1];
          var sq = new BN(hi / b.words[b.length - 1] | 0);
          var shift = (a.length - b.length) * 26;
          if (q) {
            var t = sq.shln(shift);
            if (a.sign) q.isub(t);
            else q.iadd(t)
          }
          sq = sq.mul(b).ishln(shift);
          if (a.sign) a.iadd(sq);
          else a.isub(sq)
        }
        if (a.sign) {
          if (q) q.isubn(1);
          a.iadd(b)
        }
        return {
          div: q ? q : null,
          mod: a
        }
      };
      BN.prototype.divmod = function divmod(num, mode) {
        assert(num.cmpn(0) !== 0);
        if (this.sign && !num.sign) {
          var res = this.neg().divmod(num, mode);
          var div;
          var mod;
          if (mode !== "mod") div = res.div.neg();
          if (mode !== "div") mod = res.mod.cmpn(0) === 0 ? res.mod : num.sub(res.mod);
          return {
            div: div,
            mod: mod
          }
        } else if (!this.sign && num.sign) {
          var res = this.divmod(num.neg(), mode);
          var div;
          if (mode !== "mod") div = res.div.neg();
          return {
            div: div,
            mod: res.mod
          }
        } else if (this.sign && num.sign) {
          return this.neg().divmod(num.neg(), mode)
        }
        if (num.length > this.length || this.cmp(num) < 0) return {
          div: new BN(0),
          mod: this
        };
        if (num.length === 1) {
          if (mode === "div") return {
            div: this.divn(num.words[0]),
            mod: null
          };
          else if (mode === "mod") return {
            div: null,
            mod: new BN(this.modn(num.words[0]))
          };
          return {
            div: this.divn(num.words[0]),
            mod: new BN(this.modn(num.words[0]))
          }
        }
        return this._wordDiv(num, mode)
      };
      BN.prototype.div = function div(num) {
        return this.divmod(num, "div").div
      };
      BN.prototype.mod = function mod(num) {
        return this.divmod(num, "mod").mod
      };
      BN.prototype.divRound = function divRound(num) {
        var dm = this.divmod(num);
        if (dm.mod.cmpn(0) === 0) return dm.div;
        var mod = dm.div.sign ? dm.mod.isub(num) : dm.mod;
        var half = num.shrn(1);
        var r2 = num.andln(1);
        var cmp = mod.cmp(half);
        if (cmp < 0 || r2 === 1 && cmp === 0) return dm.div;
        return dm.div.sign ? dm.div.isubn(1) : dm.div.iaddn(1)
      };
      BN.prototype.modn = function modn(num) {
        assert(num <= 67108863);
        var p = (1 << 26) % num;
        var acc = 0;
        for (var i = this.length - 1; i >= 0; i--) acc = (p * acc + this.words[i]) % num;
        return acc
      };
      BN.prototype.idivn = function idivn(num) {
        assert(num <= 67108863);
        var carry = 0;
        for (var i = this.length - 1; i >= 0; i--) {
          var w = this.words[i] + carry * 67108864;
          this.words[i] = w / num | 0;
          carry = w % num
        }
        return this.strip()
      };
      BN.prototype.divn = function divn(num) {
        return this.clone().idivn(num)
      };
      BN.prototype._egcd = function _egcd(x1, p) {
        assert(!p.sign);
        assert(p.cmpn(0) !== 0);
        var a = this;
        var b = p.clone();
        if (a.sign) a = a.mod(p);
        else a = a.clone();
        var x2 = new BN(0);
        while (b.isEven()) b.ishrn(1);
        var delta = b.clone();
        while (a.cmpn(1) > 0 && b.cmpn(1) > 0) {
          while (a.isEven()) {
            a.ishrn(1);
            if (x1.isEven()) x1.ishrn(1);
            else x1.iadd(delta).ishrn(1)
          }
          while (b.isEven()) {
            b.ishrn(1);
            if (x2.isEven()) x2.ishrn(1);
            else x2.iadd(delta).ishrn(1)
          }
          if (a.cmp(b) >= 0) {
            a.isub(b);
            x1.isub(x2)
          } else {
            b.isub(a);
            x2.isub(x1)
          }
        }
        if (a.cmpn(1) === 0) return x1;
        else return x2
      };
      BN.prototype.gcd = function gcd(num) {
        if (this.cmpn(0) === 0) return num.clone();
        if (num.cmpn(0) === 0) return this.clone();
        var a = this.clone();
        var b = num.clone();
        a.sign = false;
        b.sign = false;
        for (var shift = 0; a.isEven() && b.isEven(); shift++) {
          a.ishrn(1);
          b.ishrn(1)
        }
        while (a.isEven()) a.ishrn(1);
        do {
          while (b.isEven()) b.ishrn(1);
          if (a.cmp(b) < 0) {
            var t = a;
            a = b;
            b = t
          }
          a.isub(a.div(b).mul(b))
        } while (a.cmpn(0) !== 0 && b.cmpn(0) !== 0);
        if (a.cmpn(0) === 0) return b.ishln(shift);
        else return a.ishln(shift)
      };
      BN.prototype.invm = function invm(num) {
        return this._egcd(new BN(1), num).mod(num)
      };
      BN.prototype.isEven = function isEven(num) {
        return (this.words[0] & 1) === 0
      };
      BN.prototype.isOdd = function isOdd(num) {
        return (this.words[0] & 1) === 1
      };
      BN.prototype.andln = function andln(num) {
        return this.words[0] & num
      };
      BN.prototype.bincn = function bincn(bit) {
        assert(typeof bit === "number");
        var r = bit % 26;
        var s = (bit - r) / 26;
        var q = 1 << r;
        if (this.length <= s) {
          for (var i = this.length; i < s + 1; i++) this.words[i] = 0;
          this.words[s] |= q;
          this.length = s + 1;
          return this
        }
        var carry = q;
        for (var i = s; carry !== 0 && i < this.length; i++) {
          var w = this.words[i];
          w += carry;
          carry = w >>> 26;
          w &= 67108863;
          this.words[i] = w
        }
        if (carry !== 0) {
          this.words[i] = carry;
          this.length++
        }
        return this
      };
      BN.prototype.cmpn = function cmpn(num) {
        var sign = num < 0;
        if (sign) num = -num;
        if (this.sign && !sign) return -1;
        else if (!this.sign && sign) return 1;
        num &= 67108863;
        this.strip();
        var res;
        if (this.length > 1) {
          res = 1
        } else {
          var w = this.words[0];
          res = w === num ? 0 : w < num ? -1 : 1
        }
        if (this.sign) res = -res;
        return res
      };
      BN.prototype.cmp = function cmp(num) {
        if (this.sign && !num.sign) return -1;
        else if (!this.sign && num.sign) return 1;
        var res = this.ucmp(num);
        if (this.sign) return -res;
        else return res
      };
      BN.prototype.ucmp = function ucmp(num) {
        if (this.length > num.length) return 1;
        else if (this.length < num.length) return -1;
        var res = 0;
        for (var i = this.length - 1; i >= 0; i--) {
          var a = this.words[i];
          var b = num.words[i];
          if (a === b) continue;
          if (a < b) res = -1;
          else if (a > b) res = 1;
          break
        }
        return res
      };
      BN.red = function red(num) {
        return new Red(num)
      };
      BN.prototype.toRed = function toRed(ctx) {
        assert(!this.red, "Already a number in reduction context");
        assert(!this.sign, "red works only with positives");
        return ctx.convertTo(this)._forceRed(ctx)
      };
      BN.prototype.fromRed = function fromRed() {
        assert(this.red, "fromRed works only with numbers in reduction context");
        return this.red.convertFrom(this)
      };
      BN.prototype._forceRed = function _forceRed(ctx) {
        this.red = ctx;
        return this
      };
      BN.prototype.forceRed = function forceRed(ctx) {
        assert(!this.red, "Already a number in reduction context");
        return this._forceRed(ctx)
      };
      BN.prototype.redAdd = function redAdd(num) {
        assert(this.red, "redAdd works only with red numbers");
        return this.red.add(this, num)
      };
      BN.prototype.redIAdd = function redIAdd(num) {
        assert(this.red, "redIAdd works only with red numbers");
        return this.red.iadd(this, num)
      };
      BN.prototype.redSub = function redSub(num) {
        assert(this.red, "redSub works only with red numbers");
        return this.red.sub(this, num)
      };
      BN.prototype.redISub = function redISub(num) {
        assert(this.red, "redISub works only with red numbers");
        return this.red.isub(this, num)
      };
      BN.prototype.redShl = function redShl(num) {
        assert(this.red, "redShl works only with red numbers");
        return this.red.shl(this, num)
      };
      BN.prototype.redMul = function redMul(num) {
        assert(this.red, "redMul works only with red numbers");
        this.red._verify2(this, num);
        return this.red.mul(this, num)
      };
      BN.prototype.redIMul = function redIMul(num) {
        assert(this.red, "redMul works only with red numbers");
        this.red._verify2(this, num);
        return this.red.imul(this, num)
      };
      BN.prototype.redSqr = function redSqr() {
        assert(this.red, "redSqr works only with red numbers");
        this.red._verify1(this);
        return this.red.sqr(this)
      };
      BN.prototype.redISqr = function redISqr() {
        assert(this.red, "redISqr works only with red numbers");
        this.red._verify1(this);
        return this.red.isqr(this)
      };
      BN.prototype.redSqrt = function redSqrt() {
        assert(this.red, "redSqrt works only with red numbers");
        this.red._verify1(this);
        return this.red.sqrt(this)
      };
      BN.prototype.redInvm = function redInvm() {
        assert(this.red, "redInvm works only with red numbers");
        this.red._verify1(this);
        return this.red.invm(this)
      };
      BN.prototype.redNeg = function redNeg() {
        assert(this.red, "redNeg works only with red numbers");
        this.red._verify1(this);
        return this.red.neg(this)
      };
      BN.prototype.redPow = function redPow(num) {
        assert(this.red && !num.red, "redPow(normalNum)");
        this.red._verify1(this);
        return this.red.pow(this, num)
      };
      var primes = {
        k256: null,
        p224: null,
        p192: null,
        p25519: null
      };

      function MPrime(name, p) {
        this.name = name;
        this.p = new BN(p, 16);
        this.n = this.p.bitLength();
        this.k = new BN(1).ishln(this.n).isub(this.p);
        this.tmp = this._tmp()
      }
      MPrime.prototype._tmp = function _tmp() {
        var tmp = new BN(null);
        tmp.words = new Array(Math.ceil(this.n / 13));
        return tmp
      };
      MPrime.prototype.ireduce = function ireduce(num) {
        var r = num;
        var rlen;
        do {
          var pair = r.ishrn(this.n, 0, this.tmp);
          r = this.imulK(pair.hi);
          r = r.iadd(pair.lo);
          rlen = r.bitLength()
        } while (rlen > this.n);
        var cmp = rlen < this.n ? -1 : r.cmp(this.p);
        if (cmp === 0) {
          r.words[0] = 0;
          r.length = 1
        } else if (cmp > 0) {
          r.isub(this.p)
        } else {
          r.strip()
        }
        return r
      };
      MPrime.prototype.imulK = function imulK(num) {
        return num.imul(this.k)
      };

      function K256() {
        MPrime.call(this, "k256", "ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff fffffffe fffffc2f")
      }
      inherits(K256, MPrime);
      K256.prototype.imulK = function imulK(num) {
        num.words[num.length] = 0;
        num.words[num.length + 1] = 0;
        num.length += 2;
        for (var i = num.length - 3; i >= 0; i--) {
          var w = num.words[i];
          var hi = w * 64;
          var lo = w * 977;
          hi += lo / 67108864 | 0;
          var uhi = hi / 67108864 | 0;
          hi &= 67108863;
          lo &= 67108863;
          num.words[i + 2] += uhi;
          num.words[i + 1] += hi;
          num.words[i] = lo
        }
        var w = num.words[num.length - 2];
        if (w >= 67108864) {
          num.words[num.length - 1] += w >>> 26;
          num.words[num.length - 2] = w & 67108863
        }
        if (num.words[num.length - 1] === 0) num.length--;
        if (num.words[num.length - 1] === 0) num.length--;
        return num
      };

      function P224() {
        MPrime.call(this, "p224", "ffffffff ffffffff ffffffff ffffffff 00000000 00000000 00000001")
      }
      inherits(P224, MPrime);

      function P192() {
        MPrime.call(this, "p192", "ffffffff ffffffff ffffffff fffffffe ffffffff ffffffff")
      }
      inherits(P192, MPrime);

      function P25519() {
        MPrime.call(this, "25519", "7fffffffffffffff ffffffffffffffff ffffffffffffffff ffffffffffffffed")
      }
      inherits(P25519, MPrime);
      P25519.prototype.imulK = function imulK(num) {
        var carry = 0;
        for (var i = 0; i < num.length; i++) {
          var hi = num.words[i] * 19 + carry;
          var lo = hi & 67108863;
          hi >>>= 26;
          num.words[i] = lo;
          carry = hi
        }
        if (carry !== 0) num.words[num.length++] = carry;
        return num
      };
      BN._prime = function prime(name) {
        if (primes[name]) return primes[name];
        var prime;
        if (name === "k256") prime = new K256;
        else if (name === "p224") prime = new P224;
        else if (name === "p192") prime = new P192;
        else if (name === "p25519") prime = new P25519;
        else throw new Error("Unknown prime " + name);
        primes[name] = prime;
        return prime
      };

      function Red(m) {
        if (typeof m === "string") {
          var prime = BN._prime(m);
          this.m = prime.p;
          this.prime = prime
        } else {
          this.m = m;
          this.prime = null
        }
      }
      Red.prototype._verify1 = function _verify1(a) {
        assert(!a.sign, "red works only with positives");
        assert(a.red, "red works only with red numbers")
      };
      Red.prototype._verify2 = function _verify2(a, b) {
        assert(!a.sign && !b.sign, "red works only with positives");
        assert(a.red && a.red === b.red, "red works only with red numbers")
      };
      Red.prototype.imod = function imod(a) {
        if (this.prime) return this.prime.ireduce(a)._forceRed(this);
        return a.mod(this.m)._forceRed(this)
      };
      Red.prototype.neg = function neg(a) {
        var r = a.clone();
        r.sign = !r.sign;
        return r.iadd(this.m)._forceRed(this)
      };
      Red.prototype.add = function add(a, b) {
        this._verify2(a, b);
        var res = a.add(b);
        if (res.cmp(this.m) >= 0) res.isub(this.m);
        return res._forceRed(this)
      };
      Red.prototype.iadd = function iadd(a, b) {
        this._verify2(a, b);
        var res = a.iadd(b);
        if (res.cmp(this.m) >= 0) res.isub(this.m);
        return res
      };
      Red.prototype.sub = function sub(a, b) {
        this._verify2(a, b);
        var res = a.sub(b);
        if (res.cmpn(0) < 0) res.iadd(this.m);
        return res._forceRed(this)
      };
      Red.prototype.isub = function isub(a, b) {
        this._verify2(a, b);
        var res = a.isub(b);
        if (res.cmpn(0) < 0) res.iadd(this.m);
        return res
      };
      Red.prototype.shl = function shl(a, num) {
        this._verify1(a);
        return this.imod(a.shln(num))
      };
      Red.prototype.imul = function imul(a, b) {
        this._verify2(a, b);
        return this.imod(a.imul(b))
      };
      Red.prototype.mul = function mul(a, b) {
        this._verify2(a, b);
        return this.imod(a.mul(b))
      };
      Red.prototype.isqr = function isqr(a) {
        return this.imul(a, a)
      };
      Red.prototype.sqr = function sqr(a) {
        return this.mul(a, a)
      };
      Red.prototype.sqrt = function sqrt(a) {
        if (a.cmpn(0) === 0) return a.clone();
        var mod3 = this.m.andln(3);
        assert(mod3 % 2 === 1);
        if (mod3 === 3) {
          var pow = this.m.add(new BN(1)).ishrn(2);
          var r = this.pow(a, pow);
          return r
        }
        var q = this.m.subn(1);
        var s = 0;
        while (q.cmpn(0) !== 0 && q.andln(1) === 0) {
          s++;
          q.ishrn(1)
        }
        assert(q.cmpn(0) !== 0);
        var one = new BN(1).toRed(this);
        var nOne = one.redNeg();
        var lpow = this.m.subn(1).ishrn(1);
        var z = this.m.bitLength();
        z = new BN(2 * z * z).toRed(this);
        while (this.pow(z, lpow).cmp(nOne) !== 0) z.redIAdd(nOne);
        var c = this.pow(z, q);
        var r = this.pow(a, q.addn(1).ishrn(1));
        var t = this.pow(a, q);
        var m = s;
        while (t.cmp(one) !== 0) {
          var tmp = t;
          for (var i = 0; tmp.cmp(one) !== 0; i++) tmp = tmp.redSqr();
          assert(i < m);
          var b = this.pow(c, new BN(1).ishln(m - i - 1));
          r = r.redMul(b);
          c = b.redSqr();
          t = t.redMul(c);
          m = i
        }
        return r
      };
      Red.prototype.invm = function invm(a) {
        var inv = a._egcd(new BN(1), this.m);
        if (inv.sign) {
          inv.sign = false;
          return this.imod(inv).redNeg()
        } else {
          return this.imod(inv)
        }
      };
      Red.prototype.pow = function pow(a, num) {
        var w = [];
        var q = num.clone();
        while (q.cmpn(0) !== 0) {
          w.push(q.andln(1));
          q.ishrn(1)
        }
        var res = a;
        for (var i = 0; i < w.length; i++, res = this.sqr(res))
          if (w[i] !== 0) break;
        if (++i < w.length) {
          for (var q = this.sqr(res); i < w.length; i++, q = this.sqr(q)) {
            if (w[i] === 0) continue;
            res = this.mul(res, q)
          }
        }
        return res
      };
      Red.prototype.convertTo = function convertTo(num) {
        return num.clone()
      };
      Red.prototype.convertFrom = function convertFrom(num) {
        var res = num.clone();
        res.red = null;
        return res
      };
      BN.mont = function mont(num) {
        return new Mont(num)
      };

      function Mont(m) {
        Red.call(this, m);
        this.shift = this.m.bitLength();
        if (this.shift % 26 !== 0) this.shift += 26 - this.shift % 26;
        this.r = new BN(1).ishln(this.shift);
        this.r2 = this.imod(this.r.sqr());
        this.rinv = this.r.invm(this.m);
        this.minv = this.rinv.mul(this.r).sub(new BN(1)).div(this.m).neg().mod(this.r)
      }
      inherits(Mont, Red);
      Mont.prototype.convertTo = function convertTo(num) {
        return this.imod(num.shln(this.shift))
      };
      Mont.prototype.convertFrom = function convertFrom(num) {
        var r = this.imod(num.mul(this.rinv));
        r.red = null;
        return r
      };
      Mont.prototype.imul = function imul(a, b) {
        if (a.cmpn(0) === 0 || b.cmpn(0) === 0) {
          a.words[0] = 0;
          a.length = 1;
          return a
        }
        var t = a.imul(b);
        var c = t.maskn(this.shift).mul(this.minv).imaskn(this.shift).mul(this.m);
        var u = t.isub(c).ishrn(this.shift);
        var res = u;
        if (u.cmp(this.m) >= 0) res = u.isub(this.m);
        else if (u.cmpn(0) < 0) res = u.iadd(this.m);
        return res._forceRed(this)
      };
      Mont.prototype.mul = function mul(a, b) {
        if (a.cmpn(0) === 0 || b.cmpn(0) === 0) return new BN(0)._forceRed(this);
        var t = a.mul(b);
        var c = t.maskn(this.shift).mul(this.minv).imaskn(this.shift).mul(this.m);
        var u = t.isub(c).ishrn(this.shift);
        var res = u;
        if (u.cmp(this.m) >= 0) res = u.isub(this.m);
        else if (u.cmpn(0) < 0) res = u.iadd(this.m);
        return res._forceRed(this)
      };
      Mont.prototype.invm = function invm(a) {
        var res = this.imod(a.invm(this.m).mul(this.r2));
        return res._forceRed(this)
      }
    }, {}],
    77: [function(require, module, exports) {
      var elliptic = exports;
      elliptic.version = require("../package.json").version;
      elliptic.utils = require("./elliptic/utils");
      elliptic.rand = require("brorand");
      elliptic.hmacDRBG = require("./elliptic/hmac-drbg");
      elliptic.curve = require("./elliptic/curve");
      elliptic.curves = require("./elliptic/curves");
      elliptic.ec = require("./elliptic/ec")
    }, {
      "../package.json": 96,
      "./elliptic/curve": 80,
      "./elliptic/curves": 83,
      "./elliptic/ec": 84,
      "./elliptic/hmac-drbg": 87,
      "./elliptic/utils": 88,
      brorand: 89
    }],
    78: [function(require, module, exports) {
      var assert = require("assert");
      var bn = require("bn.js");
      var elliptic = require("../../elliptic");
      var getNAF = elliptic.utils.getNAF;
      var getJSF = elliptic.utils.getJSF;

      function BaseCurve(type, conf) {
        this.type = type;
        this.p = new bn(conf.p, 16);
        this.red = conf.prime ? bn.red(conf.prime) : bn.mont(this.p);
        this.zero = new bn(0).toRed(this.red);
        this.one = new bn(1).toRed(this.red);
        this.two = new bn(2).toRed(this.red);
        this.n = conf.n && new bn(conf.n, 16);
        this.g = conf.g && this.pointFromJSON(conf.g, conf.gRed);
        this._wnafT1 = new Array(4);
        this._wnafT2 = new Array(4);
        this._wnafT3 = new Array(4);
        this._wnafT4 = new Array(4)
      }
      module.exports = BaseCurve;
      BaseCurve.prototype.point = function point() {
        throw new Error("Not implemented")
      };
      BaseCurve.prototype.validate = function validate(point) {
        throw new Error("Not implemented")
      };
      BaseCurve.prototype._fixedNafMul = function _fixedNafMul(p, k) {
        var doubles = p._getDoubles();
        var naf = getNAF(k, 1);
        var I = (1 << doubles.step + 1) - (doubles.step % 2 === 0 ? 2 : 1);
        I /= 3;
        var repr = [];
        for (var j = 0; j < naf.length; j += doubles.step) {
          var nafW = 0;
          for (var k = j + doubles.step - 1; k >= j; k--) nafW = (nafW << 1) + naf[k];
          repr.push(nafW)
        }
        var a = this.jpoint(null, null, null);
        var b = this.jpoint(null, null, null);
        for (var i = I; i > 0; i--) {
          for (var j = 0; j < repr.length; j++) {
            var nafW = repr[j];
            if (nafW === i) b = b.mixedAdd(doubles.points[j]);
            else if (nafW === -i) b = b.mixedAdd(doubles.points[j].neg())
          }
          a = a.add(b)
        }
        return a.toP()
      };
      BaseCurve.prototype._wnafMul = function _wnafMul(p, k) {
        var w = 4;
        var nafPoints = p._getNAFPoints(w);
        w = nafPoints.wnd;
        var wnd = nafPoints.points;
        var naf = getNAF(k, w);
        var acc = this.jpoint(null, null, null);
        for (var i = naf.length - 1; i >= 0; i--) {
          for (var k = 0; i >= 0 && naf[i] === 0; i--) k++;
          if (i >= 0) k++;
          acc = acc.dblp(k);
          if (i < 0) break;
          var z = naf[i];
          assert(z !== 0);
          if (p.type === "affine") {
            if (z > 0) acc = acc.mixedAdd(wnd[z - 1 >> 1]);
            else acc = acc.mixedAdd(wnd[-z - 1 >> 1].neg())
          } else {
            if (z > 0) acc = acc.add(wnd[z - 1 >> 1]);
            else acc = acc.add(wnd[-z - 1 >> 1].neg())
          }
        }
        return p.type === "affine" ? acc.toP() : acc
      };
      BaseCurve.prototype._wnafMulAdd = function _wnafMulAdd(defW, points, coeffs, len) {
        var wndWidth = this._wnafT1;
        var wnd = this._wnafT2;
        var naf = this._wnafT3;
        var max = 0;
        for (var i = 0; i < len; i++) {
          var p = points[i];
          var nafPoints = p._getNAFPoints(defW);
          wndWidth[i] = nafPoints.wnd;
          wnd[i] = nafPoints.points
        }
        for (var i = len - 1; i >= 1; i -= 2) {
          var a = i - 1;
          var b = i;
          if (wndWidth[a] !== 1 || wndWidth[b] !== 1) {
            naf[a] = getNAF(coeffs[a], wndWidth[a]);
            naf[b] = getNAF(coeffs[b], wndWidth[b]);
            max = Math.max(naf[a].length, max);
            max = Math.max(naf[b].length, max);
            continue
          }
          var comb = [points[a], null, null, points[b]];
          if (points[a].y.cmp(points[b].y) === 0) {
            comb[1] = points[a].add(points[b]);
            comb[2] = points[a].toJ().mixedAdd(points[b].neg())
          } else if (points[a].y.cmp(points[b].y.redNeg()) === 0) {
            comb[1] = points[a].toJ().mixedAdd(points[b]);
            comb[2] = points[a].add(points[b].neg())
          } else {
            comb[1] = points[a].toJ().mixedAdd(points[b]);
            comb[2] = points[a].toJ().mixedAdd(points[b].neg())
          }
          var index = [-3, -1, -5, -7, 0, 7, 5, 1, 3];
          var jsf = getJSF(coeffs[a], coeffs[b]);
          max = Math.max(jsf[0].length, max);
          naf[a] = new Array(max);
          naf[b] = new Array(max);
          for (var j = 0; j < max; j++) {
            var ja = jsf[0][j] | 0;
            var jb = jsf[1][j] | 0;
            naf[a][j] = index[(ja + 1) * 3 + (jb + 1)];
            naf[b][j] = 0;
            wnd[a] = comb
          }
        }
        var acc = this.jpoint(null, null, null);
        var tmp = this._wnafT4;
        for (var i = max; i >= 0; i--) {
          var k = 0;
          while (i >= 0) {
            var zero = true;
            for (var j = 0; j < len; j++) {
              tmp[j] = naf[j][i] | 0;
              if (tmp[j] !== 0) zero = false
            }
            if (!zero) break;
            k++;
            i--
          }
          if (i >= 0) k++;
          acc = acc.dblp(k);
          if (i < 0) break;
          for (var j = 0; j < len; j++) {
            var z = tmp[j];
            var p;
            if (z === 0) continue;
            else if (z > 0) p = wnd[j][z - 1 >> 1];
            else if (z < 0) p = wnd[j][-z - 1 >> 1].neg();
            if (p.type === "affine") acc = acc.mixedAdd(p);
            else acc = acc.add(p)
          }
        }
        for (var i = 0; i < len; i++) wnd[i] = null;
        return acc.toP()
      };
      BaseCurve.BasePoint = BasePoint;

      function BasePoint(curve, type) {
        this.curve = curve;
        this.type = type;
        this.precomputed = null
      }
      BasePoint.prototype.validate = function validate() {
        return this.curve.validate(this)
      };
      BasePoint.prototype.precompute = function precompute(power, _beta) {
        if (this.precomputed) return this;
        var precomputed = {
          doubles: null,
          naf: null,
          beta: null
        };
        precomputed.naf = this._getNAFPoints(8);
        precomputed.doubles = this._getDoubles(4, power);
        precomputed.beta = this._getBeta();
        this.precomputed = precomputed;
        return this
      };
      BasePoint.prototype._getDoubles = function _getDoubles(step, power) {
        if (this.precomputed && this.precomputed.doubles) return this.precomputed.doubles;
        var doubles = [this];
        var acc = this;
        for (var i = 0; i < power; i += step) {
          for (var j = 0; j < step; j++) acc = acc.dbl();
          doubles.push(acc)
        }
        return {
          step: step,
          points: doubles
        }
      };
      BasePoint.prototype._getNAFPoints = function _getNAFPoints(wnd) {
        if (this.precomputed && this.precomputed.naf) return this.precomputed.naf;
        var res = [this];
        var max = (1 << wnd) - 1;
        var dbl = max === 1 ? null : this.dbl();
        for (var i = 1; i < max; i++) res[i] = res[i - 1].add(dbl);
        return {
          wnd: wnd,
          points: res
        }
      };
      BasePoint.prototype._getBeta = function _getBeta() {
        return null
      };
      BasePoint.prototype.dblp = function dblp(k) {
        var r = this;
        for (var i = 0; i < k; i++) r = r.dbl();
        return r
      }
    }, {
      "../../elliptic": 77,
      assert: 5,
      "bn.js": 76
    }],
    79: [function(require, module, exports) {
      var assert = require("assert");
      var curve = require("../curve");
      var elliptic = require("../../elliptic");
      var bn = require("bn.js");
      var inherits = require("inherits");
      var Base = curve.base;
      var getNAF = elliptic.utils.getNAF;

      function EdwardsCurve(conf) {
        this.twisted = conf.a != 1;
        this.mOneA = this.twisted && conf.a == -1;
        this.extended = this.mOneA;
        Base.call(this, "mont", conf);
        this.a = new bn(conf.a, 16).mod(this.red.m).toRed(this.red);
        this.c = new bn(conf.c, 16).toRed(this.red);
        this.c2 = this.c.redSqr();
        this.d = new bn(conf.d, 16).toRed(this.red);
        this.dd = this.d.redAdd(this.d);
        assert(!this.twisted || this.c.fromRed().cmpn(1) === 0);
        this.oneC = conf.c == 1
      }
      inherits(EdwardsCurve, Base);
      module.exports = EdwardsCurve;
      EdwardsCurve.prototype._mulA = function _mulA(num) {
        if (this.mOneA) return num.redNeg();
        else return this.a.redMul(num)
      };
      EdwardsCurve.prototype._mulC = function _mulC(num) {
        if (this.oneC) return num;
        else return this.c.redMul(num)
      };
      EdwardsCurve.prototype.point = function point(x, y, z, t) {
        return new Point(this, x, y, z, t)
      };
      EdwardsCurve.prototype.jpoint = function jpoint(x, y, z, t) {
        return this.point(x, y, z, t)
      };
      EdwardsCurve.prototype.pointFromJSON = function pointFromJSON(obj) {
        return Point.fromJSON(this, obj)
      };
      EdwardsCurve.prototype.pointFromX = function pointFromX(odd, x) {
        x = new bn(x, 16);
        if (!x.red) x = x.toRed(this.red);
        var x2 = x.redSqr();
        var rhs = this.c2.redSub(this.a.redMul(x2));
        var lhs = this.one.redSub(this.c2.redMul(this.d).redMul(x2));
        var y = rhs.redMul(lhs.redInvm()).redSqrt();
        var isOdd = y.fromRed().isOdd();
        if (odd && !isOdd || !odd && isOdd) y = y.redNeg();
        return this.point(x, y, curve.one)
      };
      EdwardsCurve.prototype.validate = function validate(point) {
        if (point.isInfinity()) return true;
        point.normalize();
        var x2 = point.x.redSqr();
        var y2 = point.y.redSqr();
        var lhs = x2.redMul(this.a).redAdd(y2);
        var rhs = this.c2.redMul(this.one.redAdd(this.d.redMul(x2).redMul(y2)));
        return lhs.cmp(rhs) === 0
      };

      function Point(curve, x, y, z, t) {
        Base.BasePoint.call(this, curve, "projective");
        if (x === null && y === null && z === null) {
          this.x = this.curve.zero;
          this.y = this.curve.one;
          this.z = this.curve.one;
          this.t = this.curve.zero;
          this.zOne = true
        } else {
          this.x = new bn(x, 16);
          this.y = new bn(y, 16);
          this.z = z ? new bn(z, 16) : this.curve.one;
          this.t = t && new bn(t, 16);
          if (!this.x.red) this.x = this.x.toRed(this.curve.red);
          if (!this.y.red) this.y = this.y.toRed(this.curve.red);
          if (!this.z.red) this.z = this.z.toRed(this.curve.red);
          if (this.t && !this.t.red) this.t = this.t.toRed(this.curve.red);
          this.zOne = this.z === this.curve.one;
          if (this.curve.extended && !this.t) {
            this.t = this.x.redMul(this.y);
            if (!this.zOne) this.t = this.t.redMul(this.z.redInvm())
          }
        }
      }
      inherits(Point, Base.BasePoint);
      Point.fromJSON = function fromJSON(curve, obj) {
        return new Point(curve, obj[0], obj[1], obj[2])
      };
      Point.prototype.inspect = function inspect() {
        if (this.isInfinity()) return "<EC Point Infinity>";
        return "<EC Point x: " + this.x.fromRed().toString(16, 2) + " y: " + this.y.fromRed().toString(16, 2) + " z: " + this.z.fromRed().toString(16, 2) + ">"
      };
      Point.prototype.isInfinity = function isInfinity() {
        return this.x.cmpn(0) === 0 && this.y.cmp(this.z) === 0
      };
      Point.prototype._extDbl = function _extDbl() {
        var a = this.x.redSqr();
        var b = this.y.redSqr();
        var c = this.z.redSqr();
        c = c.redIAdd(c);
        var d = this.curve._mulA(a);
        var e = this.x.redAdd(this.y).redSqr().redISub(a).redISub(b);
        var g = d.redAdd(b);
        var f = g.redSub(c);
        var h = d.redSub(b);
        var nx = e.redMul(f);
        var ny = g.redMul(h);
        var nt = e.redMul(h);
        var nz = f.redMul(g);
        return this.curve.point(nx, ny, nz, nt)
      };
      Point.prototype._projDbl = function _projDbl() {
        var b = this.x.redAdd(this.y).redSqr();
        var c = this.x.redSqr();
        var d = this.y.redSqr();
        if (this.curve.twisted) {
          var e = this.curve._mulA(c);
          var f = e.redAdd(d);
          if (this.zOne) {
            var nx = b.redSub(c).redSub(d).redMul(f.redSub(this.curve.two));
            var ny = f.redMul(e.redSub(d));
            var nz = f.redSqr().redSub(f).redSub(f)
          } else {
            var h = this.z.redSqr();
            var j = f.redSub(h).redISub(h);
            var nx = b.redSub(c).redISub(d).redMul(j);
            var ny = f.redMul(e.redSub(d));
            var nz = f.redMul(j)
          }
        } else {
          var e = c.redAdd(d);
          var h = this.curve._mulC(redMul(this.z)).redSqr();
          var j = e.redSub(h).redSub(h);
          var nx = this.curve._mulC(b.redISub(e)).redMul(j);
          var ny = this.curve._mulC(e).redMul(c.redISub(d));
          var nz = e.redMul(j)
        }
        return this.curve.point(nx, ny, nz)
      };
      Point.prototype.dbl = function dbl() {
        if (this.isInfinity()) return this;
        if (this.curve.extended) return this._extDbl();
        else return this._projDbl()
      };
      Point.prototype._extAdd = function _extAdd(p) {
        var a = this.y.redSub(this.x).redMul(p.y.redSub(p.x));
        var b = this.y.redAdd(this.x).redMul(p.y.redAdd(p.x));
        var c = this.t.redMul(this.curve.dd).redMul(p.t);
        var d = this.z.redMul(p.z.redAdd(p.z));
        var e = b.redSub(a);
        var f = d.redSub(c);
        var g = d.redAdd(c);
        var h = b.redAdd(a);
        var nx = e.redMul(f);
        var ny = g.redMul(h);
        var nt = e.redMul(h);
        var nz = f.redMul(g);
        return this.curve.point(nx, ny, nz, nt)
      };
      Point.prototype._projAdd = function _projAdd(p) {
        var a = this.z.redMul(p.z);
        var b = a.redSqr();
        var c = this.x.redMul(p.x);
        var d = this.y.redMul(p.y);
        var e = this.curve.d.redMul(c).redMul(d);
        var f = b.redSub(e);
        var g = b.redAdd(e);
        var tmp = this.x.redAdd(this.y).redMul(p.x.redAdd(p.y)).redISub(c).redISub(d);
        var nx = a.redMul(f).redMul(tmp);
        if (this.curve.twisted) {
          var ny = a.redMul(g).redMul(d.redSub(this.curve._mulA(c)));
          var nz = f.redMul(g)
        } else {
          var ny = a.redMul(g).redMul(d.redSub(c));
          var nz = this.curve._mulC(f).redMul(g)
        }
        return this.curve.point(nx, ny, nz)
      };
      Point.prototype.add = function add(p) {
        if (this.isInfinity()) return p;
        if (p.isInfinity()) return this;
        if (this.curve.extended) return this._extAdd(p);
        else return this._projAdd(p)
      };
      Point.prototype.mul = function mul(k) {
        if (this.precomputed && this.precomputed.doubles) return this.curve._fixedNafMul(this, k);
        else return this.curve._wnafMul(this, k)
      };
      Point.prototype.mulAdd = function mulAdd(k1, p, k2) {
        return this.curve._wnafMulAdd(1, [this, p], [k1, k2], 2)
      };
      Point.prototype.normalize = function normalize() {
        if (this.zOne) return this;
        var zi = this.z.redInvm();
        this.x = this.x.redMul(zi);
        this.y = this.y.redMul(zi);
        if (this.t) this.t = this.t.redMul(zi);
        this.z = this.curve.one;
        this.zOne = true;
        return this
      };
      Point.prototype.neg = function neg() {
        return this.curve.point(this.x.redNeg(), this.y, this.z, this.t && this.t.redNeg())
      };
      Point.prototype.getX = function getX() {
        this.normalize();
        return this.x.fromRed()
      };
      Point.prototype.getY = function getY() {
        this.normalize();
        return this.y.fromRed()
      };
      Point.prototype.toP = Point.prototype.normalize;
      Point.prototype.mixedAdd = Point.prototype.add
    }, {
      "../../elliptic": 77,
      "../curve": 80,
      assert: 5,
      "bn.js": 76,
      inherits: 97
    }],
    80: [function(require, module, exports) {
      var curve = exports;
      curve.base = require("./base");
      curve.short = require("./short");
      curve.mont = require("./mont");
      curve.edwards = require("./edwards")
    }, {
      "./base": 78,
      "./edwards": 79,
      "./mont": 81,
      "./short": 82
    }],
    81: [function(require, module, exports) {
      var assert = require("assert");
      var curve = require("../curve");
      var elliptic = require("../../elliptic");
      var bn = require("bn.js");
      var inherits = require("inherits");
      var Base = curve.base;
      var getNAF = elliptic.utils.getNAF;

      function MontCurve(conf) {
        Base.call(this, "mont", conf);
        this.a = new bn(conf.a, 16).toRed(this.red);
        this.b = new bn(conf.b, 16).toRed(this.red);
        this.i4 = new bn(4).toRed(this.red).redInvm();
        this.two = new bn(2).toRed(this.red);
        this.a24 = this.i4.redMul(this.a.redAdd(this.two))
      }
      inherits(MontCurve, Base);
      module.exports = MontCurve;
      MontCurve.prototype.point = function point(x, z) {
        return new Point(this, x, z)
      };
      MontCurve.prototype.pointFromJSON = function pointFromJSON(obj) {
        return Point.fromJSON(this, obj)
      };
      MontCurve.prototype.validate = function validate(point) {
        var x = point.normalize().x;
        var x2 = x.redSqr();
        var rhs = x2.redMul(x).redAdd(x2.redMul(this.a)).redAdd(x);
        var y = rhs.redSqrt();
        return y.redSqr().cmp(rhs) === 0
      };

      function Point(curve, x, z) {
        Base.BasePoint.call(this, curve, "projective");
        if (x === null && z === null) {
          this.x = this.curve.one;
          this.z = this.curve.zero
        } else {
          this.x = new bn(x, 16);
          this.z = new bn(z, 16);
          if (!this.x.red) this.x = this.x.toRed(this.curve.red);
          if (!this.z.red) this.z = this.z.toRed(this.curve.red)
        }
      }
      inherits(Point, Base.BasePoint);
      Point.prototype.precompute = function precompute() {};
      Point.fromJSON = function fromJSON(curve, obj) {
        return new Point(curve, obj[0], obj[1] || curve.one)
      };
      Point.prototype.inspect = function inspect() {
        if (this.isInfinity()) return "<EC Point Infinity>";
        return "<EC Point x: " + this.x.fromRed().toString(16, 2) + " z: " + this.z.fromRed().toString(16, 2) + ">"
      };
      Point.prototype.isInfinity = function isInfinity() {
        return this.z.cmpn(0) === 0
      };
      Point.prototype.dbl = function dbl() {
        var a = this.x.redAdd(this.z);
        var aa = a.redSqr();
        var b = this.x.redSub(this.z);
        var bb = b.redSqr();
        var c = aa.redSub(bb);
        var nx = aa.redMul(bb);
        var nz = c.redMul(bb.redAdd(this.curve.a24.redMul(c)));
        return this.curve.point(nx, nz)
      };
      Point.prototype.add = function add(p) {
        throw new Error("Not supported on Montgomery curve")
      };
      Point.prototype.diffAdd = function diffAdd(p, diff) {
        var a = this.x.redAdd(this.z);
        var b = this.x.redSub(this.z);
        var c = p.x.redAdd(p.z);
        var d = p.x.redSub(p.z);
        var da = d.redMul(a);
        var cb = c.redMul(b);
        var nx = diff.z.redMul(da.redAdd(cb).redSqr());
        var nz = diff.x.redMul(da.redISub(cb).redSqr());
        return this.curve.point(nx, nz)
      };
      Point.prototype.mul = function mul(k) {
        var t = k.clone();
        var a = this;
        var b = this.curve.point(null, null);
        var c = this;
        for (var bits = []; t.cmpn(0) !== 0; t.ishrn(1)) bits.push(t.andln(1));
        for (var i = bits.length - 1; i >= 0; i--) {
          if (bits[i] === 0) {
            a = a.diffAdd(b, c);
            b = b.dbl()
          } else {
            b = a.diffAdd(b, c);
            a = a.dbl()
          }
        }
        return b
      };
      Point.prototype.mulAdd = function mulAdd() {
        throw new Error("Not supported on Montgomery curve")
      };
      Point.prototype.normalize = function normalize() {
        this.x = this.x.redMul(this.z.redInvm());
        this.z = this.curve.one;
        return this
      };
      Point.prototype.getX = function getX() {
        this.normalize();
        return this.x.fromRed()
      }
    }, {
      "../../elliptic": 77,
      "../curve": 80,
      assert: 5,
      "bn.js": 76,
      inherits: 97
    }],
    82: [function(require, module, exports) {
      var assert = require("assert");
      var curve = require("../curve");
      var elliptic = require("../../elliptic");
      var bn = require("bn.js");
      var inherits = require("inherits");
      var Base = curve.base;
      var getNAF = elliptic.utils.getNAF;

      function ShortCurve(conf) {
        Base.call(this, "short", conf);
        this.a = new bn(conf.a, 16).toRed(this.red);
        this.b = new bn(conf.b, 16).toRed(this.red);
        this.tinv = this.two.redInvm();
        this.zeroA = this.a.fromRed().cmpn(0) === 0;
        this.threeA = this.a.fromRed().sub(this.p).cmpn(-3) === 0;
        this.endo = this._getEndomorphism(conf);
        this._endoWnafT1 = new Array(4);
        this._endoWnafT2 = new Array(4)
      }
      inherits(ShortCurve, Base);
      module.exports = ShortCurve;
      ShortCurve.prototype._getEndomorphism = function _getEndomorphism(conf) {
        if (!this.zeroA || !this.g || !this.n || this.p.modn(3) !== 1) return;
        var beta;
        var lambda;
        if (conf.beta) {
          beta = new bn(conf.beta, 16).toRed(this.red)
        } else {
          var betas = this._getEndoRoots(this.p);
          beta = betas[0].cmp(betas[1]) < 0 ? betas[0] : betas[1];
          beta = beta.toRed(this.red)
        }
        if (conf.lambda) {
          lambda = new bn(conf.lambda, 16)
        } else {
          var lambdas = this._getEndoRoots(this.n);
          if (this.g.mul(lambdas[0]).x.cmp(this.g.x.redMul(beta)) === 0) {
            lambda = lambdas[0]
          } else {
            lambda = lambdas[1];
            assert(this.g.mul(lambda).x.cmp(this.g.x.redMul(beta)) === 0)
          }
        }
        var basis;
        if (conf.basis) {
          basis = conf.basis.map(function(vec) {
            return {
              a: new bn(vec.a, 16),
              b: new bn(vec.b, 16)
            }
          })
        } else {
          basis = this._getEndoBasis(lambda)
        }
        return {
          beta: beta,
          lambda: lambda,
          basis: basis
        }
      };
      ShortCurve.prototype._getEndoRoots = function _getEndoRoots(num) {
        var red = num === this.p ? this.red : bn.mont(num);
        var tinv = new bn(2).toRed(red).redInvm();
        var ntinv = tinv.redNeg();
        var one = new bn(1).toRed(red);
        var s = new bn(3).toRed(red).redNeg().redSqrt().redMul(tinv);
        var l1 = ntinv.redAdd(s).fromRed();
        var l2 = ntinv.redSub(s).fromRed();
        return [l1, l2]
      };
      ShortCurve.prototype._getEndoBasis = function _getEndoBasis(lambda) {
        var aprxSqrt = this.n.shrn(Math.floor(this.n.bitLength() / 2));
        var u = lambda;
        var v = this.n.clone();
        var x1 = new bn(1);
        var y1 = new bn(0);
        var x2 = new bn(0);
        var y2 = new bn(1);
        var a0;
        var b0;
        var a1;
        var b1;
        var a2;
        var b2;
        var prevR;
        var i = 0;
        while (u.cmpn(0) !== 0) {
          var q = v.div(u);
          var r = v.sub(q.mul(u));
          var x = x2.sub(q.mul(x1));
          var y = y2.sub(q.mul(y1));
          if (!a1 && r.cmp(aprxSqrt) < 0) {
            a0 = prevR.neg();
            b0 = x1;
            a1 = r.neg();
            b1 = x
          } else if (a1 && ++i === 2) {
            break
          }
          prevR = r;
          v = u;
          u = r;
          x2 = x1;
          x1 = x;
          y2 = y1;
          y1 = y
        }
        a2 = r.neg();
        b2 = x;
        var len1 = a1.sqr().add(b1.sqr());
        var len2 = a2.sqr().add(b2.sqr());
        if (len2.cmp(len1) >= 0) {
          a2 = a0;
          b2 = b0
        }
        if (a1.sign) {
          a1 = a1.neg();
          b1 = b1.neg()
        }
        if (a2.sign) {
          a2 = a2.neg();
          b2 = b2.neg()
        }
        return [{
          a: a1,
          b: b1
        }, {
          a: a2,
          b: b2
        }]
      };
      ShortCurve.prototype._endoSplit = function _endoSplit(k) {
        var basis = this.endo.basis;
        var v1 = basis[0];
        var v2 = basis[1];
        var c1 = v2.b.mul(k).divRound(this.n);
        var c2 = v1.b.neg().mul(k).divRound(this.n);
        var p1 = c1.mul(v1.a);
        var p2 = c2.mul(v2.a);
        var q1 = c1.mul(v1.b);
        var q2 = c2.mul(v2.b);
        var k1 = k.sub(p1).sub(p2);
        var k2 = q1.add(q2).neg();
        return {
          k1: k1,
          k2: k2
        }
      };
      ShortCurve.prototype.point = function point(x, y, isRed) {
        return new Point(this, x, y, isRed)
      };
      ShortCurve.prototype.pointFromX = function pointFromX(odd, x) {
        x = new bn(x, 16);
        if (!x.red) x = x.toRed(this.red);
        var y2 = x.redSqr().redMul(x).redIAdd(x.redMul(this.a)).redIAdd(this.b);
        var y = y2.redSqrt();
        var isOdd = y.fromRed().isOdd();
        if (odd && !isOdd || !odd && isOdd) y = y.redNeg();
        return this.point(x, y)
      };
      ShortCurve.prototype.jpoint = function jpoint(x, y, z) {
        return new JPoint(this, x, y, z)
      };
      ShortCurve.prototype.pointFromJSON = function pointFromJSON(obj, red) {
        return Point.fromJSON(this, obj, red)
      };
      ShortCurve.prototype.validate = function validate(point) {
        if (point.inf) return true;
        var x = point.x;
        var y = point.y;
        var ax = this.a.redMul(x);
        var rhs = x.redSqr().redMul(x).redIAdd(ax).redIAdd(this.b);
        return y.redSqr().redISub(rhs).cmpn(0) === 0
      };
      ShortCurve.prototype._endoWnafMulAdd = function _endoWnafMulAdd(points, coeffs) {
        var npoints = this._endoWnafT1;
        var ncoeffs = this._endoWnafT2;
        for (var i = 0; i < points.length; i++) {
          var split = this._endoSplit(coeffs[i]);
          var p = points[i];
          var beta = p._getBeta();
          if (split.k1.sign) {
            split.k1.sign = !split.k1.sign;
            p = p.neg(true)
          }
          if (split.k2.sign) {
            split.k2.sign = !split.k2.sign;
            beta = beta.neg(true)
          }
          npoints[i * 2] = p;
          npoints[i * 2 + 1] = beta;
          ncoeffs[i * 2] = split.k1;
          ncoeffs[i * 2 + 1] = split.k2
        }
        var res = this._wnafMulAdd(1, npoints, ncoeffs, i * 2);
        for (var j = 0; j < i * 2; j++) {
          npoints[j] = null;
          ncoeffs[j] = null
        }
        return res
      };

      function Point(curve, x, y, isRed) {
        Base.BasePoint.call(this, curve, "affine");
        if (x === null && y === null) {
          this.x = null;
          this.y = null;
          this.inf = true
        } else {
          this.x = new bn(x, 16);
          this.y = new bn(y, 16);
          if (isRed) {
            this.x.forceRed(this.curve.red);
            this.y.forceRed(this.curve.red)
          }
          if (!this.x.red) this.x = this.x.toRed(this.curve.red);
          if (!this.y.red) this.y = this.y.toRed(this.curve.red);
          this.inf = false
        }
      }
      inherits(Point, Base.BasePoint);
      Point.prototype._getBeta = function _getBeta() {
        if (!this.curve.endo) return;
        var pre = this.precomputed;
        if (pre && pre.beta) return pre.beta;
        var beta = this.curve.point(this.x.redMul(this.curve.endo.beta), this.y);
        if (pre) {
          var curve = this.curve;

          function endoMul(p) {
            return curve.point(p.x.redMul(curve.endo.beta), p.y)
          }
          pre.beta = beta;
          beta.precomputed = {
            beta: null,
            naf: pre.naf && {
              wnd: pre.naf.wnd,
              points: pre.naf.points.map(endoMul)
            },
            doubles: pre.doubles && {
              step: pre.doubles.step,
              points: pre.doubles.points.map(endoMul)
            }
          }
        }
        return beta
      };
      Point.prototype.toJSON = function toJSON() {
        if (!this.precomputed) return [this.x, this.y];
        return [this.x, this.y, this.precomputed && {
          doubles: this.precomputed.doubles && {
            step: this.precomputed.doubles.step,
            points: this.precomputed.doubles.points.slice(1)
          },
          naf: this.precomputed.naf && {
            wnd: this.precomputed.naf.wnd,
            points: this.precomputed.naf.points.slice(1)
          }
        }]
      };
      Point.fromJSON = function fromJSON(curve, obj, red) {
        if (typeof obj === "string") obj = JSON.parse(obj);
        var res = curve.point(obj[0], obj[1], red);
        if (!obj[2]) return res;

        function obj2point(obj) {
          return curve.point(obj[0], obj[1], red)
        }
        var pre = obj[2];
        res.precomputed = {
          beta: null,
          doubles: pre.doubles && {
            step: pre.doubles.step,
            points: [res].concat(pre.doubles.points.map(obj2point))
          },
          naf: pre.naf && {
            wnd: pre.naf.wnd,
            points: [res].concat(pre.naf.points.map(obj2point))
          }
        };
        return res
      };
      Point.prototype.inspect = function inspect() {
        if (this.isInfinity()) return "<EC Point Infinity>";
        return "<EC Point x: " + this.x.fromRed().toString(16, 2) + " y: " + this.y.fromRed().toString(16, 2) + ">"
      };
      Point.prototype.isInfinity = function isInfinity() {
        return this.inf
      };
      Point.prototype.add = function add(p) {
        if (this.inf) return p;
        if (p.inf) return this;
        if (this.eq(p)) return this.dbl();
        if (this.neg().eq(p)) return this.curve.point(null, null);
        if (this.x.cmp(p.x) === 0) return this.curve.point(null, null);
        var c = this.y.redSub(p.y);
        if (c.cmpn(0) !== 0) c = c.redMul(this.x.redSub(p.x).redInvm());
        var nx = c.redSqr().redISub(this.x).redISub(p.x);
        var ny = c.redMul(this.x.redSub(nx)).redISub(this.y);
        return this.curve.point(nx, ny)
      };
      Point.prototype.dbl = function dbl() {
        if (this.inf) return this;
        var ys1 = this.y.redAdd(this.y);
        if (ys1.cmpn(0) === 0) return this.curve.point(null, null);
        var a = this.curve.a;
        var x2 = this.x.redSqr();
        var dyinv = ys1.redInvm();
        var c = x2.redAdd(x2).redIAdd(x2).redIAdd(a).redMul(dyinv);
        var nx = c.redSqr().redISub(this.x.redAdd(this.x));
        var ny = c.redMul(this.x.redSub(nx)).redISub(this.y);
        return this.curve.point(nx, ny)
      };
      Point.prototype.getX = function getX() {
        return this.x.fromRed()
      };
      Point.prototype.getY = function getY() {
        return this.y.fromRed()
      };
      Point.prototype.mul = function mul(k) {
        k = new bn(k, 16);
        if (this.precomputed && this.precomputed.doubles) return this.curve._fixedNafMul(this, k);
        else if (this.curve.endo) return this.curve._endoWnafMulAdd([this], [k]);
        else return this.curve._wnafMul(this, k)
      };
      Point.prototype.mulAdd = function mulAdd(k1, p2, k2) {
        var points = [this, p2];
        var coeffs = [k1, k2];
        if (this.curve.endo) return this.curve._endoWnafMulAdd(points, coeffs);
        else return this.curve._wnafMulAdd(1, points, coeffs, 2)
      };
      Point.prototype.eq = function eq(p) {
        return this === p || this.inf === p.inf && (this.inf || this.x.cmp(p.x) === 0 && this.y.cmp(p.y) === 0)
      };
      Point.prototype.neg = function neg(_precompute) {
        if (this.inf) return this;
        var res = this.curve.point(this.x, this.y.redNeg());
        if (_precompute && this.precomputed) {
          var pre = this.precomputed;

          function negate(p) {
            return p.neg()
          }
          res.precomputed = {
            naf: pre.naf && {
              wnd: pre.naf.wnd,
              points: pre.naf.points.map(negate)
            },
            doubles: pre.doubles && {
              step: pre.doubles.step,
              points: pre.doubles.points.map(negate)
            }
          }
        }
        return res
      };
      Point.prototype.toJ = function toJ() {
        if (this.inf) return this.curve.jpoint(null, null, null);
        var res = this.curve.jpoint(this.x, this.y, this.curve.one);
        return res
      };

      function JPoint(curve, x, y, z) {
        Base.BasePoint.call(this, curve, "jacobian");
        if (x === null && y === null && z === null) {
          this.x = this.curve.one;
          this.y = this.curve.one;
          this.z = new bn(0)
        } else {
          this.x = new bn(x, 16);
          this.y = new bn(y, 16);
          this.z = new bn(z, 16)
        }
        if (!this.x.red) this.x = this.x.toRed(this.curve.red);
        if (!this.y.red) this.y = this.y.toRed(this.curve.red);
        if (!this.z.red) this.z = this.z.toRed(this.curve.red);
        this.zOne = this.z === this.curve.one
      }
      inherits(JPoint, Base.BasePoint);
      JPoint.prototype.toP = function toP() {
        if (this.isInfinity()) return this.curve.point(null, null);
        var zinv = this.z.redInvm();
        var zinv2 = zinv.redSqr();
        var ax = this.x.redMul(zinv2);
        var ay = this.y.redMul(zinv2).redMul(zinv);
        return this.curve.point(ax, ay)
      };
      JPoint.prototype.neg = function neg() {
        return this.curve.jpoint(this.x, this.y.redNeg(), this.z)
      };
      JPoint.prototype.add = function add(p) {
        if (this.isInfinity()) return p;
        if (p.isInfinity()) return this;
        var pz2 = p.z.redSqr();
        var z2 = this.z.redSqr();
        var u1 = this.x.redMul(pz2);
        var u2 = p.x.redMul(z2);
        var s1 = this.y.redMul(pz2.redMul(p.z));
        var s2 = p.y.redMul(z2.redMul(this.z));
        var h = u1.redSub(u2);
        var r = s1.redSub(s2);
        if (h.cmpn(0) === 0) {
          if (r.cmpn(0) !== 0) return this.curve.jpoint(null, null, null);
          else return this.dbl()
        }
        var h2 = h.redSqr();
        var h3 = h2.redMul(h);
        var v = u1.redMul(h2);
        var nx = r.redSqr().redIAdd(h3).redISub(v).redISub(v);
        var ny = r.redMul(v.redISub(nx)).redISub(s1.redMul(h3));
        var nz = this.z.redMul(p.z).redMul(h);
        return this.curve.jpoint(nx, ny, nz)
      };
      JPoint.prototype.mixedAdd = function mixedAdd(p) {
        if (this.isInfinity()) return p.toJ();
        if (p.isInfinity()) return this;
        var z2 = this.z.redSqr();
        var u1 = this.x;
        var u2 = p.x.redMul(z2);
        var s1 = this.y;
        var s2 = p.y.redMul(z2).redMul(this.z);
        var h = u1.redSub(u2);
        var r = s1.redSub(s2);
        if (h.cmpn(0) === 0) {
          if (r.cmpn(0) !== 0) return this.curve.jpoint(null, null, null);
          else return this.dbl()
        }
        var h2 = h.redSqr();
        var h3 = h2.redMul(h);
        var v = u1.redMul(h2);
        var nx = r.redSqr().redIAdd(h3).redISub(v).redISub(v);
        var ny = r.redMul(v.redISub(nx)).redISub(s1.redMul(h3));
        var nz = this.z.redMul(h);
        return this.curve.jpoint(nx, ny, nz)
      };
      JPoint.prototype.dblp = function dblp(pow) {
        if (pow === 0) return this;
        if (this.isInfinity()) return this;
        if (!pow) return this.dbl();
        if (this.curve.zeroA || this.curve.threeA) {
          var r = this;
          for (var i = 0; i < pow; i++) r = r.dbl();
          return r
        }
        var a = this.curve.a;
        var tinv = this.curve.tinv;
        var jx = this.x;
        var jy = this.y;
        var jz = this.z;
        var jz4 = jz.redSqr().redSqr();
        var jyd = jy.redAdd(jy);
        for (var i = 0; i < pow; i++) {
          var jx2 = jx.redSqr();
          var jyd2 = jyd.redSqr();
          var jyd4 = jyd2.redSqr();
          var c = jx2.redAdd(jx2).redIAdd(jx2).redIAdd(a.redMul(jz4));
          var t1 = jx.redMul(jyd2);
          var nx = c.redSqr().redISub(t1.redAdd(t1));
          var t2 = t1.redISub(nx);
          var dny = c.redMul(t2);
          dny = dny.redIAdd(dny).redISub(jyd4);
          var nz = jyd.redMul(jz);
          if (i + 1 < pow) jz4 = jz4.redMul(jyd4);
          jx = nx;
          jz = nz;
          jyd = dny
        }
        return this.curve.jpoint(jx, jyd.redMul(tinv), jz)
      };
      JPoint.prototype.dbl = function dbl() {
        if (this.isInfinity()) return this;
        if (this.curve.zeroA) return this._zeroDbl();
        else if (this.curve.threeA) return this._threeDbl();
        else return this._dbl()
      };
      JPoint.prototype._zeroDbl = function _zeroDbl() {
        if (this.zOne) {
          var xx = this.x.redSqr();
          var yy = this.y.redSqr();
          var yyyy = yy.redSqr();
          var s = this.x.redAdd(yy).redSqr().redISub(xx).redISub(yyyy);
          s = s.redIAdd(s);
          var m = xx.redAdd(xx).redIAdd(xx);
          var t = m.redSqr().redISub(s).redISub(s);
          var yyyy8 = yyyy.redIAdd(yyyy);
          yyyy8 = yyyy8.redIAdd(yyyy8);
          yyyy8 = yyyy8.redIAdd(yyyy8);
          var nx = t;
          var ny = m.redMul(s.redISub(t)).redISub(yyyy8);
          var nz = this.y.redAdd(this.y)
        } else {
          var a = this.x.redSqr();
          var b = this.y.redSqr();
          var c = b.redSqr();
          var d = this.x.redAdd(b).redSqr().redISub(a).redISub(c);
          d = d.redIAdd(d);
          var e = a.redAdd(a).redIAdd(a);
          var f = e.redSqr();
          var c8 = c.redIAdd(c);
          c8 = c8.redIAdd(c8);
          c8 = c8.redIAdd(c8);
          var nx = f.redISub(d).redISub(d);
          var ny = e.redMul(d.redISub(nx)).redISub(c8);
          var nz = this.y.redMul(this.z);
          nz = nz.redIAdd(nz)
        }
        return this.curve.jpoint(nx, ny, nz)
      };
      JPoint.prototype._threeDbl = function _threeDbl() {
        if (this.zOne) {
          var xx = this.x.redSqr();
          var yy = this.y.redSqr();
          var yyyy = yy.redSqr();
          var s = this.x.redAdd(yy).redSqr().redISub(xx).redISub(yyyy);
          s = s.redIAdd(s);
          var m = xx.redAdd(xx).redIAdd(xx).redIAdd(this.curve.a);
          var t = m.redSqr().redISub(s).redISub(s);
          var nx = t;
          var yyyy8 = yyyy.redIAdd(yyyy);
          yyyy8 = yyyy8.redIAdd(yyyy8);
          yyyy8 = yyyy8.redIAdd(yyyy8);
          var ny = m.redMul(s.redISub(t)).redISub(yyyy8);
          var nz = this.y.redAdd(this.y)
        } else {
          var delta = this.z.redSqr();
          var gamma = this.y.redSqr();
          var beta = this.x.redMul(gamma);
          var alpha = this.x.redSub(delta).redMul(this.x.redAdd(delta));
          alpha = alpha.redAdd(alpha).redIAdd(alpha);
          var beta4 = beta.redIAdd(beta);
          beta4 = beta4.redIAdd(beta4);
          var beta8 = beta4.redAdd(beta4);
          var nx = alpha.redSqr().redISub(beta8);
          var nz = this.y.redAdd(this.z).redSqr().redISub(gamma).redISub(delta);
          var ggamma8 = gamma.redSqr();
          ggamma8 = ggamma8.redIAdd(ggamma8);
          ggamma8 = ggamma8.redIAdd(ggamma8);
          ggamma8 = ggamma8.redIAdd(ggamma8);
          var ny = alpha.redMul(beta4.redISub(nx)).redISub(ggamma8)
        }
        return this.curve.jpoint(nx, ny, nz)
      };
      JPoint.prototype._dbl = function _dbl() {
        var a = this.curve.a;
        var tinv = this.curve.tinv;
        var jx = this.x;
        var jy = this.y;
        var jz = this.z;
        var jz4 = jz.redSqr().redSqr();
        var jx2 = jx.redSqr();
        var jy2 = jy.redSqr();
        var c = jx2.redAdd(jx2).redIAdd(jx2).redIAdd(a.redMul(jz4));
        var jxd4 = jx.redAdd(jx);
        jxd4 = jxd4.redIAdd(jxd4);
        var t1 = jxd4.redMul(jy2);
        var nx = c.redSqr().redISub(t1.redAdd(t1));
        var t2 = t1.redISub(nx);
        var jyd8 = jy2.redSqr();
        jyd8 = jyd8.redIAdd(jyd8);
        jyd8 = jyd8.redIAdd(jyd8);
        jyd8 = jyd8.redIAdd(jyd8);
        var ny = c.redMul(t2).redISub(jyd8);
        var nz = jy.redAdd(jy).redMul(jz);
        return this.curve.jpoint(nx, ny, nz)
      };
      JPoint.prototype.trpl = function trpl() {
        if (!this.curve.zeroA) return this.dbl().add(this);
        var xx = this.x.redSqr();
        var yy = this.y.redSqr();
        var zz = this.z.redSqr();
        var yyyy = yy.redSqr();
        var m = xx.redAdd(xx).redIAdd(xx);
        var mm = m.redSqr();
        var e = this.x.redAdd(yy).redSqr().redISub(xx).redISub(yyyy);
        e = e.redIAdd(e);
        e = e.redAdd(e).redIAdd(e);
        e = e.redISub(mm);
        var ee = e.redSqr();
        var t = yyyy.redIAdd(yyyy);
        t = t.redIAdd(t);
        t = t.redIAdd(t);
        t = t.redIAdd(t);
        var u = m.redIAdd(e).redSqr().redISub(mm).redISub(ee).redISub(t);
        var yyu4 = yy.redMul(u);
        yyu4 = yyu4.redIAdd(yyu4);
        yyu4 = yyu4.redIAdd(yyu4);
        var nx = this.x.redMul(ee).redISub(yyu4);
        nx = nx.redIAdd(nx);
        nx = nx.redIAdd(nx);
        var ny = this.y.redMul(u.redMul(t.redISub(u)).redISub(e.redMul(ee)));
        ny = ny.redIAdd(ny);
        ny = ny.redIAdd(ny);
        ny = ny.redIAdd(ny);
        var nz = this.z.redAdd(e).redSqr().redISub(zz).redISub(ee);
        return this.curve.jpoint(nx, ny, nz)
      };
      JPoint.prototype.mul = function mul(k, kbase) {
        k = new bn(k, kbase);
        return this.curve._wnafMul(this, k)
      };
      JPoint.prototype.eq = function eq(p) {
        if (p.type === "affine") return this.eq(p.toJ());
        if (this === p) return true;
        var z2 = this.z.redSqr();
        var pz2 = p.z.redSqr();
        if (this.x.redMul(pz2).redISub(p.x.redMul(z2)).cmpn(0) !== 0) return false;
        var z3 = z2.redMul(this.z);
        var pz3 = pz2.redMul(p.z);
        return this.y.redMul(pz3).redISub(p.y.redMul(z3)).cmpn(0) === 0
      };
      JPoint.prototype.inspect = function inspect() {
        if (this.isInfinity()) return "<EC JPoint Infinity>";
        return "<EC JPoint x: " + this.x.toString(16, 2) + " y: " + this.y.toString(16, 2) + " z: " + this.z.toString(16, 2) + ">"
      };
      JPoint.prototype.isInfinity = function isInfinity() {
        return this.z.cmpn(0) === 0
      }
    }, {
      "../../elliptic": 77,
      "../curve": 80,
      assert: 5,
      "bn.js": 76,
      inherits: 97
    }],
    83: [function(require, module, exports) {
      var curves = exports;
      var assert = require("assert");
      var hash = require("hash.js");
      var bn = require("bn.js");
      var elliptic = require("../elliptic");

      function PresetCurve(options) {
        if (options.type === "short") this.curve = new elliptic.curve.short(options);
        else if (options.type === "edwards") this.curve = new elliptic.curve.edwards(options);
        else this.curve = new elliptic.curve.mont(options);
        this.g = this.curve.g;
        this.n = this.curve.n;
        this.hash = options.hash;
        assert(this.g.validate(), "Invalid curve");
        assert(this.g.mul(this.n).isInfinity(), "Invalid curve, G*N != O")
      }
      curves.PresetCurve = PresetCurve;

      function defineCurve(name, options) {
        Object.defineProperty(curves, name, {
          configurable: true,
          enumerable: true,
          get: function() {
            var curve = new PresetCurve(options);
            Object.defineProperty(curves, name, {
              configurable: true,
              enumerable: true,
              value: curve
            });
            return curve
          }
        })
      }
      defineCurve("p192", {
        type: "short",
        prime: "p192",
        p: "ffffffff ffffffff ffffffff fffffffe ffffffff ffffffff",
        a: "ffffffff ffffffff ffffffff fffffffe ffffffff fffffffc",
        b: "64210519 e59c80e7 0fa7e9ab 72243049 feb8deec c146b9b1",
        n: "ffffffff ffffffff ffffffff 99def836 146bc9b1 b4d22831",
        hash: hash.sha256,
        gRed: false,
        g: ["188da80e b03090f6 7cbf20eb 43a18800 f4ff0afd 82ff1012", "07192b95 ffc8da78 631011ed 6b24cdd5 73f977a1 1e794811"]
      });
      defineCurve("p224", {
        type: "short",
        prime: "p224",
        p: "ffffffff ffffffff ffffffff ffffffff 00000000 00000000 00000001",
        a: "ffffffff ffffffff ffffffff fffffffe ffffffff ffffffff fffffffe",
        b: "b4050a85 0c04b3ab f5413256 5044b0b7 d7bfd8ba 270b3943 2355ffb4",
        n: "ffffffff ffffffff ffffffff ffff16a2 e0b8f03e 13dd2945 5c5c2a3d",
        hash: hash.sha256,
        gRed: false,
        g: ["b70e0cbd 6bb4bf7f 321390b9 4a03c1d3 56c21122 343280d6 115c1d21", "bd376388 b5f723fb 4c22dfe6 cd4375a0 5a074764 44d58199 85007e34"]
      });
      defineCurve("p256", {
        type: "short",
        prime: null,
        p: "ffffffff 00000001 00000000 00000000 00000000 ffffffff ffffffff ffffffff",
        a: "ffffffff 00000001 00000000 00000000 00000000 ffffffff ffffffff fffffffc",
        b: "5ac635d8 aa3a93e7 b3ebbd55 769886bc 651d06b0 cc53b0f6 3bce3c3e 27d2604b",
        n: "ffffffff 00000000 ffffffff ffffffff bce6faad a7179e84 f3b9cac2 fc632551",
        hash: hash.sha256,
        gRed: false,
        g: ["6b17d1f2 e12c4247 f8bce6e5 63a440f2 77037d81 2deb33a0 f4a13945 d898c296", "4fe342e2 fe1a7f9b 8ee7eb4a 7c0f9e16 2bce3357 6b315ece cbb64068 37bf51f5"]
      });
      defineCurve("curve25519", {
        type: "mont",
        prime: "p25519",
        p: "7fffffffffffffff ffffffffffffffff ffffffffffffffff ffffffffffffffed",
        a: "76d06",
        b: "0",
        n: "1000000000000000 0000000000000000 14def9dea2f79cd6 5812631a5cf5d3ed",
        hash: hash.sha256,
        gRed: false,
        g: ["9"]
      });
      defineCurve("ed25519", {
        type: "edwards",
        prime: "p25519",
        p: "7fffffffffffffff ffffffffffffffff ffffffffffffffff ffffffffffffffed",
        a: "-1",
        c: "1",
        d: "52036cee2b6ffe73 8cc740797779e898 00700a4d4141d8ab 75eb4dca135978a3",
        n: "1000000000000000 0000000000000000 14def9dea2f79cd6 5812631a5cf5d3ed",
        hash: hash.sha256,
        gRed: false,
        g: ["216936d3cd6e53fec0a4e231fdd6dc5c692cc7609525a7b2c9562d608f25d51a", "6666666666666666666666666666666666666666666666666666666666666658"]
      });
      defineCurve("secp256k1", {
        type: "short",
        prime: "k256",
        p: "ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff fffffffe fffffc2f",
        a: "0",
        b: "7",
        n: "ffffffff ffffffff ffffffff fffffffe baaedce6 af48a03b bfd25e8c d0364141",
        h: "1",
        hash: hash.sha256,
        beta: "7ae96a2b657c07106e64479eac3434e99cf0497512f58995c1396c28719501ee",
        lambda: "5363ad4cc05c30e0a5261c028812645a122e22ea20816678df02967c1b23bd72",
        basis: [{
          a: "3086d221a7d46bcde86c90e49284eb15",
          b: "-e4437ed6010e88286f547fa90abfe4c3"
        }, {
          a: "114ca50f7a8e2f3f657c1108d9d44cfd8",
          b: "3086d221a7d46bcde86c90e49284eb15"
        }],
        gRed: false,
        g: ["79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798", "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8", {
          doubles: {
            step: 4,
            points: [
              ["e60fce93b59e9ec53011aabc21c23e97b2a31369b87a5ae9c44ee89e2a6dec0a", "f7e3507399e595929db99f34f57937101296891e44d23f0be1f32cce69616821"],
              ["8282263212c609d9ea2a6e3e172de238d8c39cabd5ac1ca10646e23fd5f51508", "11f8a8098557dfe45e8256e830b60ace62d613ac2f7b17bed31b6eaff6e26caf"],
              ["175e159f728b865a72f99cc6c6fc846de0b93833fd2222ed73fce5b551e5b739", "d3506e0d9e3c79eba4ef97a51ff71f5eacb5955add24345c6efa6ffee9fed695"],
              ["363d90d447b00c9c99ceac05b6262ee053441c7e55552ffe526bad8f83ff4640", "4e273adfc732221953b445397f3363145b9a89008199ecb62003c7f3bee9de9"],
              ["8b4b5f165df3c2be8c6244b5b745638843e4a781a15bcd1b69f79a55dffdf80c", "4aad0a6f68d308b4b3fbd7813ab0da04f9e336546162ee56b3eff0c65fd4fd36"],
              ["723cbaa6e5db996d6bf771c00bd548c7b700dbffa6c0e77bcb6115925232fcda", "96e867b5595cc498a921137488824d6e2660a0653779494801dc069d9eb39f5f"],
              ["eebfa4d493bebf98ba5feec812c2d3b50947961237a919839a533eca0e7dd7fa", "5d9a8ca3970ef0f269ee7edaf178089d9ae4cdc3a711f712ddfd4fdae1de8999"],
              ["100f44da696e71672791d0a09b7bde459f1215a29b3c03bfefd7835b39a48db0", "cdd9e13192a00b772ec8f3300c090666b7ff4a18ff5195ac0fbd5cd62bc65a09"],
              ["e1031be262c7ed1b1dc9227a4a04c017a77f8d4464f3b3852c8acde6e534fd2d", "9d7061928940405e6bb6a4176597535af292dd419e1ced79a44f18f29456a00d"],
              ["feea6cae46d55b530ac2839f143bd7ec5cf8b266a41d6af52d5e688d9094696d", "e57c6b6c97dce1bab06e4e12bf3ecd5c981c8957cc41442d3155debf18090088"],
              ["da67a91d91049cdcb367be4be6ffca3cfeed657d808583de33fa978bc1ec6cb1", "9bacaa35481642bc41f463f7ec9780e5dec7adc508f740a17e9ea8e27a68be1d"],
              ["53904faa0b334cdda6e000935ef22151ec08d0f7bb11069f57545ccc1a37b7c0", "5bc087d0bc80106d88c9eccac20d3c1c13999981e14434699dcb096b022771c8"],
              ["8e7bcd0bd35983a7719cca7764ca906779b53a043a9b8bcaeff959f43ad86047", "10b7770b2a3da4b3940310420ca9514579e88e2e47fd68b3ea10047e8460372a"],
              ["385eed34c1cdff21e6d0818689b81bde71a7f4f18397e6690a841e1599c43862", "283bebc3e8ea23f56701de19e9ebf4576b304eec2086dc8cc0458fe5542e5453"],
              ["6f9d9b803ecf191637c73a4413dfa180fddf84a5947fbc9c606ed86c3fac3a7", "7c80c68e603059ba69b8e2a30e45c4d47ea4dd2f5c281002d86890603a842160"],
              ["3322d401243c4e2582a2147c104d6ecbf774d163db0f5e5313b7e0e742d0e6bd", "56e70797e9664ef5bfb019bc4ddaf9b72805f63ea2873af624f3a2e96c28b2a0"],
              ["85672c7d2de0b7da2bd1770d89665868741b3f9af7643397721d74d28134ab83", "7c481b9b5b43b2eb6374049bfa62c2e5e77f17fcc5298f44c8e3094f790313a6"],
              ["948bf809b1988a46b06c9f1919413b10f9226c60f668832ffd959af60c82a0a", "53a562856dcb6646dc6b74c5d1c3418c6d4dff08c97cd2bed4cb7f88d8c8e589"],
              ["6260ce7f461801c34f067ce0f02873a8f1b0e44dfc69752accecd819f38fd8e8", "bc2da82b6fa5b571a7f09049776a1ef7ecd292238051c198c1a84e95b2b4ae17"],
              ["e5037de0afc1d8d43d8348414bbf4103043ec8f575bfdc432953cc8d2037fa2d", "4571534baa94d3b5f9f98d09fb990bddbd5f5b03ec481f10e0e5dc841d755bda"],
              ["e06372b0f4a207adf5ea905e8f1771b4e7e8dbd1c6a6c5b725866a0ae4fce725", "7a908974bce18cfe12a27bb2ad5a488cd7484a7787104870b27034f94eee31dd"],
              ["213c7a715cd5d45358d0bbf9dc0ce02204b10bdde2a3f58540ad6908d0559754", "4b6dad0b5ae462507013ad06245ba190bb4850f5f36a7eeddff2c27534b458f2"],
              ["4e7c272a7af4b34e8dbb9352a5419a87e2838c70adc62cddf0cc3a3b08fbd53c", "17749c766c9d0b18e16fd09f6def681b530b9614bff7dd33e0b3941817dcaae6"],
              ["fea74e3dbe778b1b10f238ad61686aa5c76e3db2be43057632427e2840fb27b6", "6e0568db9b0b13297cf674deccb6af93126b596b973f7b77701d3db7f23cb96f"],
              ["76e64113f677cf0e10a2570d599968d31544e179b760432952c02a4417bdde39", "c90ddf8dee4e95cf577066d70681f0d35e2a33d2b56d2032b4b1752d1901ac01"],
              ["c738c56b03b2abe1e8281baa743f8f9a8f7cc643df26cbee3ab150242bcbb891", "893fb578951ad2537f718f2eacbfbbbb82314eef7880cfe917e735d9699a84c3"],
              ["d895626548b65b81e264c7637c972877d1d72e5f3a925014372e9f6588f6c14b", "febfaa38f2bc7eae728ec60818c340eb03428d632bb067e179363ed75d7d991f"],
              ["b8da94032a957518eb0f6433571e8761ceffc73693e84edd49150a564f676e03", "2804dfa44805a1e4d7c99cc9762808b092cc584d95ff3b511488e4e74efdf6e7"],
              ["e80fea14441fb33a7d8adab9475d7fab2019effb5156a792f1a11778e3c0df5d", "eed1de7f638e00771e89768ca3ca94472d155e80af322ea9fcb4291b6ac9ec78"],
              ["a301697bdfcd704313ba48e51d567543f2a182031efd6915ddc07bbcc4e16070", "7370f91cfb67e4f5081809fa25d40f9b1735dbf7c0a11a130c0d1a041e177ea1"],
              ["90ad85b389d6b936463f9d0512678de208cc330b11307fffab7ac63e3fb04ed4", "e507a3620a38261affdcbd9427222b839aefabe1582894d991d4d48cb6ef150"],
              ["8f68b9d2f63b5f339239c1ad981f162ee88c5678723ea3351b7b444c9ec4c0da", "662a9f2dba063986de1d90c2b6be215dbbea2cfe95510bfdf23cbf79501fff82"],
              ["e4f3fb0176af85d65ff99ff9198c36091f48e86503681e3e6686fd5053231e11", "1e63633ad0ef4f1c1661a6d0ea02b7286cc7e74ec951d1c9822c38576feb73bc"],
              ["8c00fa9b18ebf331eb961537a45a4266c7034f2f0d4e1d0716fb6eae20eae29e", "efa47267fea521a1a9dc343a3736c974c2fadafa81e36c54e7d2a4c66702414b"],
              ["e7a26ce69dd4829f3e10cec0a9e98ed3143d084f308b92c0997fddfc60cb3e41", "2a758e300fa7984b471b006a1aafbb18d0a6b2c0420e83e20e8a9421cf2cfd51"],
              ["b6459e0ee3662ec8d23540c223bcbdc571cbcb967d79424f3cf29eb3de6b80ef", "67c876d06f3e06de1dadf16e5661db3c4b3ae6d48e35b2ff30bf0b61a71ba45"],
              ["d68a80c8280bb840793234aa118f06231d6f1fc67e73c5a5deda0f5b496943e8", "db8ba9fff4b586d00c4b1f9177b0e28b5b0e7b8f7845295a294c84266b133120"],
              ["324aed7df65c804252dc0270907a30b09612aeb973449cea4095980fc28d3d5d", "648a365774b61f2ff130c0c35aec1f4f19213b0c7e332843967224af96ab7c84"],
              ["4df9c14919cde61f6d51dfdbe5fee5dceec4143ba8d1ca888e8bd373fd054c96", "35ec51092d8728050974c23a1d85d4b5d506cdc288490192ebac06cad10d5d"],
              ["9c3919a84a474870faed8a9c1cc66021523489054d7f0308cbfc99c8ac1f98cd", "ddb84f0f4a4ddd57584f044bf260e641905326f76c64c8e6be7e5e03d4fc599d"],
              ["6057170b1dd12fdf8de05f281d8e06bb91e1493a8b91d4cc5a21382120a959e5", "9a1af0b26a6a4807add9a2daf71df262465152bc3ee24c65e899be932385a2a8"],
              ["a576df8e23a08411421439a4518da31880cef0fba7d4df12b1a6973eecb94266", "40a6bf20e76640b2c92b97afe58cd82c432e10a7f514d9f3ee8be11ae1b28ec8"],
              ["7778a78c28dec3e30a05fe9629de8c38bb30d1f5cf9a3a208f763889be58ad71", "34626d9ab5a5b22ff7098e12f2ff580087b38411ff24ac563b513fc1fd9f43ac"],
              ["928955ee637a84463729fd30e7afd2ed5f96274e5ad7e5cb09eda9c06d903ac", "c25621003d3f42a827b78a13093a95eeac3d26efa8a8d83fc5180e935bcd091f"],
              ["85d0fef3ec6db109399064f3a0e3b2855645b4a907ad354527aae75163d82751", "1f03648413a38c0be29d496e582cf5663e8751e96877331582c237a24eb1f962"],
              ["ff2b0dce97eece97c1c9b6041798b85dfdfb6d8882da20308f5404824526087e", "493d13fef524ba188af4c4dc54d07936c7b7ed6fb90e2ceb2c951e01f0c29907"],
              ["827fbbe4b1e880ea9ed2b2e6301b212b57f1ee148cd6dd28780e5e2cf856e241", "c60f9c923c727b0b71bef2c67d1d12687ff7a63186903166d605b68baec293ec"],
              ["eaa649f21f51bdbae7be4ae34ce6e5217a58fdce7f47f9aa7f3b58fa2120e2b3", "be3279ed5bbbb03ac69a80f89879aa5a01a6b965f13f7e59d47a5305ba5ad93d"],
              ["e4a42d43c5cf169d9391df6decf42ee541b6d8f0c9a137401e23632dda34d24f", "4d9f92e716d1c73526fc99ccfb8ad34ce886eedfa8d8e4f13a7f7131deba9414"],
              ["1ec80fef360cbdd954160fadab352b6b92b53576a88fea4947173b9d4300bf19", "aeefe93756b5340d2f3a4958a7abbf5e0146e77f6295a07b671cdc1cc107cefd"],
              ["146a778c04670c2f91b00af4680dfa8bce3490717d58ba889ddb5928366642be", "b318e0ec3354028add669827f9d4b2870aaa971d2f7e5ed1d0b297483d83efd0"],
              ["fa50c0f61d22e5f07e3acebb1aa07b128d0012209a28b9776d76a8793180eef9", "6b84c6922397eba9b72cd2872281a68a5e683293a57a213b38cd8d7d3f4f2811"],
              ["da1d61d0ca721a11b1a5bf6b7d88e8421a288ab5d5bba5220e53d32b5f067ec2", "8157f55a7c99306c79c0766161c91e2966a73899d279b48a655fba0f1ad836f1"],
              ["a8e282ff0c9706907215ff98e8fd416615311de0446f1e062a73b0610d064e13", "7f97355b8db81c09abfb7f3c5b2515888b679a3e50dd6bd6cef7c73111f4cc0c"],
              ["174a53b9c9a285872d39e56e6913cab15d59b1fa512508c022f382de8319497c", "ccc9dc37abfc9c1657b4155f2c47f9e6646b3a1d8cb9854383da13ac079afa73"],
              ["959396981943785c3d3e57edf5018cdbe039e730e4918b3d884fdff09475b7ba", "2e7e552888c331dd8ba0386a4b9cd6849c653f64c8709385e9b8abf87524f2fd"],
              ["d2a63a50ae401e56d645a1153b109a8fcca0a43d561fba2dbb51340c9d82b151", "e82d86fb6443fcb7565aee58b2948220a70f750af484ca52d4142174dcf89405"],
              ["64587e2335471eb890ee7896d7cfdc866bacbdbd3839317b3436f9b45617e073", "d99fcdd5bf6902e2ae96dd6447c299a185b90a39133aeab358299e5e9faf6589"],
              ["8481bde0e4e4d885b3a546d3e549de042f0aa6cea250e7fd358d6c86dd45e458", "38ee7b8cba5404dd84a25bf39cecb2ca900a79c42b262e556d64b1b59779057e"],
              ["13464a57a78102aa62b6979ae817f4637ffcfed3c4b1ce30bcd6303f6caf666b", "69be159004614580ef7e433453ccb0ca48f300a81d0942e13f495a907f6ecc27"],
              ["bc4a9df5b713fe2e9aef430bcc1dc97a0cd9ccede2f28588cada3a0d2d83f366", "d3a81ca6e785c06383937adf4b798caa6e8a9fbfa547b16d758d666581f33c1"],
              ["8c28a97bf8298bc0d23d8c749452a32e694b65e30a9472a3954ab30fe5324caa", "40a30463a3305193378fedf31f7cc0eb7ae784f0451cb9459e71dc73cbef9482"],
              ["8ea9666139527a8c1dd94ce4f071fd23c8b350c5a4bb33748c4ba111faccae0", "620efabbc8ee2782e24e7c0cfb95c5d735b783be9cf0f8e955af34a30e62b945"],
              ["dd3625faef5ba06074669716bbd3788d89bdde815959968092f76cc4eb9a9787", "7a188fa3520e30d461da2501045731ca941461982883395937f68d00c644a573"],
              ["f710d79d9eb962297e4f6232b40e8f7feb2bc63814614d692c12de752408221e", "ea98e67232d3b3295d3b535532115ccac8612c721851617526ae47a9c77bfc82"]
            ]
          },
          naf: {
            wnd: 7,
            points: [
              ["f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9", "388f7b0f632de8140fe337e62a37f3566500a99934c2231b6cb9fd7584b8e672"],
              ["2f8bde4d1a07209355b4a7250a5c5128e88b84bddc619ab7cba8d569b240efe4", "d8ac222636e5e3d6d4dba9dda6c9c426f788271bab0d6840dca87d3aa6ac62d6"],
              ["5cbdf0646e5db4eaa398f365f2ea7a0e3d419b7e0330e39ce92bddedcac4f9bc", "6aebca40ba255960a3178d6d861a54dba813d0b813fde7b5a5082628087264da"],
              ["acd484e2f0c7f65309ad178a9f559abde09796974c57e714c35f110dfc27ccbe", "cc338921b0a7d9fd64380971763b61e9add888a4375f8e0f05cc262ac64f9c37"],
              ["774ae7f858a9411e5ef4246b70c65aac5649980be5c17891bbec17895da008cb", "d984a032eb6b5e190243dd56d7b7b365372db1e2dff9d6a8301d74c9c953c61b"],
              ["f28773c2d975288bc7d1d205c3748651b075fbc6610e58cddeeddf8f19405aa8", "ab0902e8d880a89758212eb65cdaf473a1a06da521fa91f29b5cb52db03ed81"],
              ["d7924d4f7d43ea965a465ae3095ff41131e5946f3c85f79e44adbcf8e27e080e", "581e2872a86c72a683842ec228cc6defea40af2bd896d3a5c504dc9ff6a26b58"],
              ["defdea4cdb677750a420fee807eacf21eb9898ae79b9768766e4faa04a2d4a34", "4211ab0694635168e997b0ead2a93daeced1f4a04a95c0f6cfb199f69e56eb77"],
              ["2b4ea0a797a443d293ef5cff444f4979f06acfebd7e86d277475656138385b6c", "85e89bc037945d93b343083b5a1c86131a01f60c50269763b570c854e5c09b7a"],
              ["352bbf4a4cdd12564f93fa332ce333301d9ad40271f8107181340aef25be59d5", "321eb4075348f534d59c18259dda3e1f4a1b3b2e71b1039c67bd3d8bcf81998c"],
              ["2fa2104d6b38d11b0230010559879124e42ab8dfeff5ff29dc9cdadd4ecacc3f", "2de1068295dd865b64569335bd5dd80181d70ecfc882648423ba76b532b7d67"],
              ["9248279b09b4d68dab21a9b066edda83263c3d84e09572e269ca0cd7f5453714", "73016f7bf234aade5d1aa71bdea2b1ff3fc0de2a887912ffe54a32ce97cb3402"],
              ["daed4f2be3a8bf278e70132fb0beb7522f570e144bf615c07e996d443dee8729", "a69dce4a7d6c98e8d4a1aca87ef8d7003f83c230f3afa726ab40e52290be1c55"],
              ["c44d12c7065d812e8acf28d7cbb19f9011ecd9e9fdf281b0e6a3b5e87d22e7db", "2119a460ce326cdc76c45926c982fdac0e106e861edf61c5a039063f0e0e6482"],
              ["6a245bf6dc698504c89a20cfded60853152b695336c28063b61c65cbd269e6b4", "e022cf42c2bd4a708b3f5126f16a24ad8b33ba48d0423b6efd5e6348100d8a82"],
              ["1697ffa6fd9de627c077e3d2fe541084ce13300b0bec1146f95ae57f0d0bd6a5", "b9c398f186806f5d27561506e4557433a2cf15009e498ae7adee9d63d01b2396"],
              ["605bdb019981718b986d0f07e834cb0d9deb8360ffb7f61df982345ef27a7479", "2972d2de4f8d20681a78d93ec96fe23c26bfae84fb14db43b01e1e9056b8c49"],
              ["62d14dab4150bf497402fdc45a215e10dcb01c354959b10cfe31c7e9d87ff33d", "80fc06bd8cc5b01098088a1950eed0db01aa132967ab472235f5642483b25eaf"],
              ["80c60ad0040f27dade5b4b06c408e56b2c50e9f56b9b8b425e555c2f86308b6f", "1c38303f1cc5c30f26e66bad7fe72f70a65eed4cbe7024eb1aa01f56430bd57a"],
              ["7a9375ad6167ad54aa74c6348cc54d344cc5dc9487d847049d5eabb0fa03c8fb", "d0e3fa9eca8726909559e0d79269046bdc59ea10c70ce2b02d499ec224dc7f7"],
              ["d528ecd9b696b54c907a9ed045447a79bb408ec39b68df504bb51f459bc3ffc9", "eecf41253136e5f99966f21881fd656ebc4345405c520dbc063465b521409933"],
              ["49370a4b5f43412ea25f514e8ecdad05266115e4a7ecb1387231808f8b45963", "758f3f41afd6ed428b3081b0512fd62a54c3f3afbb5b6764b653052a12949c9a"],
              ["77f230936ee88cbbd73df930d64702ef881d811e0e1498e2f1c13eb1fc345d74", "958ef42a7886b6400a08266e9ba1b37896c95330d97077cbbe8eb3c7671c60d6"],
              ["f2dac991cc4ce4b9ea44887e5c7c0bce58c80074ab9d4dbaeb28531b7739f530", "e0dedc9b3b2f8dad4da1f32dec2531df9eb5fbeb0598e4fd1a117dba703a3c37"],
              ["463b3d9f662621fb1b4be8fbbe2520125a216cdfc9dae3debcba4850c690d45b", "5ed430d78c296c3543114306dd8622d7c622e27c970a1de31cb377b01af7307e"],
              ["f16f804244e46e2a09232d4aff3b59976b98fac14328a2d1a32496b49998f247", "cedabd9b82203f7e13d206fcdf4e33d92a6c53c26e5cce26d6579962c4e31df6"],
              ["caf754272dc84563b0352b7a14311af55d245315ace27c65369e15f7151d41d1", "cb474660ef35f5f2a41b643fa5e460575f4fa9b7962232a5c32f908318a04476"],
              ["2600ca4b282cb986f85d0f1709979d8b44a09c07cb86d7c124497bc86f082120", "4119b88753c15bd6a693b03fcddbb45d5ac6be74ab5f0ef44b0be9475a7e4b40"],
              ["7635ca72d7e8432c338ec53cd12220bc01c48685e24f7dc8c602a7746998e435", "91b649609489d613d1d5e590f78e6d74ecfc061d57048bad9e76f302c5b9c61"],
              ["754e3239f325570cdbbf4a87deee8a66b7f2b33479d468fbc1a50743bf56cc18", "673fb86e5bda30fb3cd0ed304ea49a023ee33d0197a695d0c5d98093c536683"],
              ["e3e6bd1071a1e96aff57859c82d570f0330800661d1c952f9fe2694691d9b9e8", "59c9e0bba394e76f40c0aa58379a3cb6a5a2283993e90c4167002af4920e37f5"],
              ["186b483d056a033826ae73d88f732985c4ccb1f32ba35f4b4cc47fdcf04aa6eb", "3b952d32c67cf77e2e17446e204180ab21fb8090895138b4a4a797f86e80888b"],
              ["df9d70a6b9876ce544c98561f4be4f725442e6d2b737d9c91a8321724ce0963f", "55eb2dafd84d6ccd5f862b785dc39d4ab157222720ef9da217b8c45cf2ba2417"],
              ["5edd5cc23c51e87a497ca815d5dce0f8ab52554f849ed8995de64c5f34ce7143", "efae9c8dbc14130661e8cec030c89ad0c13c66c0d17a2905cdc706ab7399a868"],
              ["290798c2b6476830da12fe02287e9e777aa3fba1c355b17a722d362f84614fba", "e38da76dcd440621988d00bcf79af25d5b29c094db2a23146d003afd41943e7a"],
              ["af3c423a95d9f5b3054754efa150ac39cd29552fe360257362dfdecef4053b45", "f98a3fd831eb2b749a93b0e6f35cfb40c8cd5aa667a15581bc2feded498fd9c6"],
              ["766dbb24d134e745cccaa28c99bf274906bb66b26dcf98df8d2fed50d884249a", "744b1152eacbe5e38dcc887980da38b897584a65fa06cedd2c924f97cbac5996"],
              ["59dbf46f8c94759ba21277c33784f41645f7b44f6c596a58ce92e666191abe3e", "c534ad44175fbc300f4ea6ce648309a042ce739a7919798cd85e216c4a307f6e"],
              ["f13ada95103c4537305e691e74e9a4a8dd647e711a95e73cb62dc6018cfd87b8", "e13817b44ee14de663bf4bc808341f326949e21a6a75c2570778419bdaf5733d"],
              ["7754b4fa0e8aced06d4167a2c59cca4cda1869c06ebadfb6488550015a88522c", "30e93e864e669d82224b967c3020b8fa8d1e4e350b6cbcc537a48b57841163a2"],
              ["948dcadf5990e048aa3874d46abef9d701858f95de8041d2a6828c99e2262519", "e491a42537f6e597d5d28a3224b1bc25df9154efbd2ef1d2cbba2cae5347d57e"],
              ["7962414450c76c1689c7b48f8202ec37fb224cf5ac0bfa1570328a8a3d7c77ab", "100b610ec4ffb4760d5c1fc133ef6f6b12507a051f04ac5760afa5b29db83437"],
              ["3514087834964b54b15b160644d915485a16977225b8847bb0dd085137ec47ca", "ef0afbb2056205448e1652c48e8127fc6039e77c15c2378b7e7d15a0de293311"],
              ["d3cc30ad6b483e4bc79ce2c9dd8bc54993e947eb8df787b442943d3f7b527eaf", "8b378a22d827278d89c5e9be8f9508ae3c2ad46290358630afb34db04eede0a4"],
              ["1624d84780732860ce1c78fcbfefe08b2b29823db913f6493975ba0ff4847610", "68651cf9b6da903e0914448c6cd9d4ca896878f5282be4c8cc06e2a404078575"],
              ["733ce80da955a8a26902c95633e62a985192474b5af207da6df7b4fd5fc61cd4", "f5435a2bd2badf7d485a4d8b8db9fcce3e1ef8e0201e4578c54673bc1dc5ea1d"],
              ["15d9441254945064cf1a1c33bbd3b49f8966c5092171e699ef258dfab81c045c", "d56eb30b69463e7234f5137b73b84177434800bacebfc685fc37bbe9efe4070d"],
              ["a1d0fcf2ec9de675b612136e5ce70d271c21417c9d2b8aaaac138599d0717940", "edd77f50bcb5a3cab2e90737309667f2641462a54070f3d519212d39c197a629"],
              ["e22fbe15c0af8ccc5780c0735f84dbe9a790badee8245c06c7ca37331cb36980", "a855babad5cd60c88b430a69f53a1a7a38289154964799be43d06d77d31da06"],
              ["311091dd9860e8e20ee13473c1155f5f69635e394704eaa74009452246cfa9b3", "66db656f87d1f04fffd1f04788c06830871ec5a64feee685bd80f0b1286d8374"],
              ["34c1fd04d301be89b31c0442d3e6ac24883928b45a9340781867d4232ec2dbdf", "9414685e97b1b5954bd46f730174136d57f1ceeb487443dc5321857ba73abee"],
              ["f219ea5d6b54701c1c14de5b557eb42a8d13f3abbcd08affcc2a5e6b049b8d63", "4cb95957e83d40b0f73af4544cccf6b1f4b08d3c07b27fb8d8c2962a400766d1"],
              ["d7b8740f74a8fbaab1f683db8f45de26543a5490bca627087236912469a0b448", "fa77968128d9c92ee1010f337ad4717eff15db5ed3c049b3411e0315eaa4593b"],
              ["32d31c222f8f6f0ef86f7c98d3a3335ead5bcd32abdd94289fe4d3091aa824bf", "5f3032f5892156e39ccd3d7915b9e1da2e6dac9e6f26e961118d14b8462e1661"],
              ["7461f371914ab32671045a155d9831ea8793d77cd59592c4340f86cbc18347b5", "8ec0ba238b96bec0cbdddcae0aa442542eee1ff50c986ea6b39847b3cc092ff6"],
              ["ee079adb1df1860074356a25aa38206a6d716b2c3e67453d287698bad7b2b2d6", "8dc2412aafe3be5c4c5f37e0ecc5f9f6a446989af04c4e25ebaac479ec1c8c1e"],
              ["16ec93e447ec83f0467b18302ee620f7e65de331874c9dc72bfd8616ba9da6b5", "5e4631150e62fb40d0e8c2a7ca5804a39d58186a50e497139626778e25b0674d"],
              ["eaa5f980c245f6f038978290afa70b6bd8855897f98b6aa485b96065d537bd99", "f65f5d3e292c2e0819a528391c994624d784869d7e6ea67fb18041024edc07dc"],
              ["78c9407544ac132692ee1910a02439958ae04877151342ea96c4b6b35a49f51", "f3e0319169eb9b85d5404795539a5e68fa1fbd583c064d2462b675f194a3ddb4"],
              ["494f4be219a1a77016dcd838431aea0001cdc8ae7a6fc688726578d9702857a5", "42242a969283a5f339ba7f075e36ba2af925ce30d767ed6e55f4b031880d562c"],
              ["a598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5", "204b5d6f84822c307e4b4a7140737aec23fc63b65b35f86a10026dbd2d864e6b"],
              ["c41916365abb2b5d09192f5f2dbeafec208f020f12570a184dbadc3e58595997", "4f14351d0087efa49d245b328984989d5caf9450f34bfc0ed16e96b58fa9913"],
              ["841d6063a586fa475a724604da03bc5b92a2e0d2e0a36acfe4c73a5514742881", "73867f59c0659e81904f9a1c7543698e62562d6744c169ce7a36de01a8d6154"],
              ["5e95bb399a6971d376026947f89bde2f282b33810928be4ded112ac4d70e20d5", "39f23f366809085beebfc71181313775a99c9aed7d8ba38b161384c746012865"],
              ["36e4641a53948fd476c39f8a99fd974e5ec07564b5315d8bf99471bca0ef2f66", "d2424b1b1abe4eb8164227b085c9aa9456ea13493fd563e06fd51cf5694c78fc"],
              ["336581ea7bfbbb290c191a2f507a41cf5643842170e914faeab27c2c579f726", "ead12168595fe1be99252129b6e56b3391f7ab1410cd1e0ef3dcdcabd2fda224"],
              ["8ab89816dadfd6b6a1f2634fcf00ec8403781025ed6890c4849742706bd43ede", "6fdcef09f2f6d0a044e654aef624136f503d459c3e89845858a47a9129cdd24e"],
              ["1e33f1a746c9c5778133344d9299fcaa20b0938e8acff2544bb40284b8c5fb94", "60660257dd11b3aa9c8ed618d24edff2306d320f1d03010e33a7d2057f3b3b6"],
              ["85b7c1dcb3cec1b7ee7f30ded79dd20a0ed1f4cc18cbcfcfa410361fd8f08f31", "3d98a9cdd026dd43f39048f25a8847f4fcafad1895d7a633c6fed3c35e999511"],
              ["29df9fbd8d9e46509275f4b125d6d45d7fbe9a3b878a7af872a2800661ac5f51", "b4c4fe99c775a606e2d8862179139ffda61dc861c019e55cd2876eb2a27d84b"],
              ["a0b1cae06b0a847a3fea6e671aaf8adfdfe58ca2f768105c8082b2e449fce252", "ae434102edde0958ec4b19d917a6a28e6b72da1834aff0e650f049503a296cf2"],
              ["4e8ceafb9b3e9a136dc7ff67e840295b499dfb3b2133e4ba113f2e4c0e121e5", "cf2174118c8b6d7a4b48f6d534ce5c79422c086a63460502b827ce62a326683c"],
              ["d24a44e047e19b6f5afb81c7ca2f69080a5076689a010919f42725c2b789a33b", "6fb8d5591b466f8fc63db50f1c0f1c69013f996887b8244d2cdec417afea8fa3"],
              ["ea01606a7a6c9cdd249fdfcfacb99584001edd28abbab77b5104e98e8e3b35d4", "322af4908c7312b0cfbfe369f7a7b3cdb7d4494bc2823700cfd652188a3ea98d"],
              ["af8addbf2b661c8a6c6328655eb96651252007d8c5ea31be4ad196de8ce2131f", "6749e67c029b85f52a034eafd096836b2520818680e26ac8f3dfbcdb71749700"],
              ["e3ae1974566ca06cc516d47e0fb165a674a3dabcfca15e722f0e3450f45889", "2aeabe7e4531510116217f07bf4d07300de97e4874f81f533420a72eeb0bd6a4"],
              ["591ee355313d99721cf6993ffed1e3e301993ff3ed258802075ea8ced397e246", "b0ea558a113c30bea60fc4775460c7901ff0b053d25ca2bdeee98f1a4be5d196"],
              ["11396d55fda54c49f19aa97318d8da61fa8584e47b084945077cf03255b52984", "998c74a8cd45ac01289d5833a7beb4744ff536b01b257be4c5767bea93ea57a4"],
              ["3c5d2a1ba39c5a1790000738c9e0c40b8dcdfd5468754b6405540157e017aa7a", "b2284279995a34e2f9d4de7396fc18b80f9b8b9fdd270f6661f79ca4c81bd257"],
              ["cc8704b8a60a0defa3a99a7299f2e9c3fbc395afb04ac078425ef8a1793cc030", "bdd46039feed17881d1e0862db347f8cf395b74fc4bcdc4e940b74e3ac1f1b13"],
              ["c533e4f7ea8555aacd9777ac5cad29b97dd4defccc53ee7ea204119b2889b197", "6f0a256bc5efdf429a2fb6242f1a43a2d9b925bb4a4b3a26bb8e0f45eb596096"],
              ["c14f8f2ccb27d6f109f6d08d03cc96a69ba8c34eec07bbcf566d48e33da6593", "c359d6923bb398f7fd4473e16fe1c28475b740dd098075e6c0e8649113dc3a38"],
              ["a6cbc3046bc6a450bac24789fa17115a4c9739ed75f8f21ce441f72e0b90e6ef", "21ae7f4680e889bb130619e2c0f95a360ceb573c70603139862afd617fa9b9f"],
              ["347d6d9a02c48927ebfb86c1359b1caf130a3c0267d11ce6344b39f99d43cc38", "60ea7f61a353524d1c987f6ecec92f086d565ab687870cb12689ff1e31c74448"],
              ["da6545d2181db8d983f7dcb375ef5866d47c67b1bf31c8cf855ef7437b72656a", "49b96715ab6878a79e78f07ce5680c5d6673051b4935bd897fea824b77dc208a"],
              ["c40747cc9d012cb1a13b8148309c6de7ec25d6945d657146b9d5994b8feb1111", "5ca560753be2a12fc6de6caf2cb489565db936156b9514e1bb5e83037e0fa2d4"],
              ["4e42c8ec82c99798ccf3a610be870e78338c7f713348bd34c8203ef4037f3502", "7571d74ee5e0fb92a7a8b33a07783341a5492144cc54bcc40a94473693606437"],
              ["3775ab7089bc6af823aba2e1af70b236d251cadb0c86743287522a1b3b0dedea", "be52d107bcfa09d8bcb9736a828cfa7fac8db17bf7a76a2c42ad961409018cf7"],
              ["cee31cbf7e34ec379d94fb814d3d775ad954595d1314ba8846959e3e82f74e26", "8fd64a14c06b589c26b947ae2bcf6bfa0149ef0be14ed4d80f448a01c43b1c6d"],
              ["b4f9eaea09b6917619f6ea6a4eb5464efddb58fd45b1ebefcdc1a01d08b47986", "39e5c9925b5a54b07433a4f18c61726f8bb131c012ca542eb24a8ac07200682a"],
              ["d4263dfc3d2df923a0179a48966d30ce84e2515afc3dccc1b77907792ebcc60e", "62dfaf07a0f78feb30e30d6295853ce189e127760ad6cf7fae164e122a208d54"],
              ["48457524820fa65a4f8d35eb6930857c0032acc0a4a2de422233eeda897612c4", "25a748ab367979d98733c38a1fa1c2e7dc6cc07db2d60a9ae7a76aaa49bd0f77"],
              ["dfeeef1881101f2cb11644f3a2afdfc2045e19919152923f367a1767c11cceda", "ecfb7056cf1de042f9420bab396793c0c390bde74b4bbdff16a83ae09a9a7517"],
              ["6d7ef6b17543f8373c573f44e1f389835d89bcbc6062ced36c82df83b8fae859", "cd450ec335438986dfefa10c57fea9bcc521a0959b2d80bbf74b190dca712d10"],
              ["e75605d59102a5a2684500d3b991f2e3f3c88b93225547035af25af66e04541f", "f5c54754a8f71ee540b9b48728473e314f729ac5308b06938360990e2bfad125"],
              ["eb98660f4c4dfaa06a2be453d5020bc99a0c2e60abe388457dd43fefb1ed620c", "6cb9a8876d9cb8520609af3add26cd20a0a7cd8a9411131ce85f44100099223e"],
              ["13e87b027d8514d35939f2e6892b19922154596941888336dc3563e3b8dba942", "fef5a3c68059a6dec5d624114bf1e91aac2b9da568d6abeb2570d55646b8adf1"],
              ["ee163026e9fd6fe017c38f06a5be6fc125424b371ce2708e7bf4491691e5764a", "1acb250f255dd61c43d94ccc670d0f58f49ae3fa15b96623e5430da0ad6c62b2"],
              ["b268f5ef9ad51e4d78de3a750c2dc89b1e626d43505867999932e5db33af3d80", "5f310d4b3c99b9ebb19f77d41c1dee018cf0d34fd4191614003e945a1216e423"],
              ["ff07f3118a9df035e9fad85eb6c7bfe42b02f01ca99ceea3bf7ffdba93c4750d", "438136d603e858a3a5c440c38eccbaddc1d2942114e2eddd4740d098ced1f0d8"],
              ["8d8b9855c7c052a34146fd20ffb658bea4b9f69e0d825ebec16e8c3ce2b526a1", "cdb559eedc2d79f926baf44fb84ea4d44bcf50fee51d7ceb30e2e7f463036758"],
              ["52db0b5384dfbf05bfa9d472d7ae26dfe4b851ceca91b1eba54263180da32b63", "c3b997d050ee5d423ebaf66a6db9f57b3180c902875679de924b69d84a7b375"],
              ["e62f9490d3d51da6395efd24e80919cc7d0f29c3f3fa48c6fff543becbd43352", "6d89ad7ba4876b0b22c2ca280c682862f342c8591f1daf5170e07bfd9ccafa7d"],
              ["7f30ea2476b399b4957509c88f77d0191afa2ff5cb7b14fd6d8e7d65aaab1193", "ca5ef7d4b231c94c3b15389a5f6311e9daff7bb67b103e9880ef4bff637acaec"],
              ["5098ff1e1d9f14fb46a210fada6c903fef0fb7b4a1dd1d9ac60a0361800b7a00", "9731141d81fc8f8084d37c6e7542006b3ee1b40d60dfe5362a5b132fd17ddc0"],
              ["32b78c7de9ee512a72895be6b9cbefa6e2f3c4ccce445c96b9f2c81e2778ad58", "ee1849f513df71e32efc3896ee28260c73bb80547ae2275ba497237794c8753c"],
              ["e2cb74fddc8e9fbcd076eef2a7c72b0ce37d50f08269dfc074b581550547a4f7", "d3aa2ed71c9dd2247a62df062736eb0baddea9e36122d2be8641abcb005cc4a4"],
              ["8438447566d4d7bedadc299496ab357426009a35f235cb141be0d99cd10ae3a8", "c4e1020916980a4da5d01ac5e6ad330734ef0d7906631c4f2390426b2edd791f"],
              ["4162d488b89402039b584c6fc6c308870587d9c46f660b878ab65c82c711d67e", "67163e903236289f776f22c25fb8a3afc1732f2b84b4e95dbda47ae5a0852649"],
              ["3fad3fa84caf0f34f0f89bfd2dcf54fc175d767aec3e50684f3ba4a4bf5f683d", "cd1bc7cb6cc407bb2f0ca647c718a730cf71872e7d0d2a53fa20efcdfe61826"],
              ["674f2600a3007a00568c1a7ce05d0816c1fb84bf1370798f1c69532faeb1a86b", "299d21f9413f33b3edf43b257004580b70db57da0b182259e09eecc69e0d38a5"],
              ["d32f4da54ade74abb81b815ad1fb3b263d82d6c692714bcff87d29bd5ee9f08f", "f9429e738b8e53b968e99016c059707782e14f4535359d582fc416910b3eea87"],
              ["30e4e670435385556e593657135845d36fbb6931f72b08cb1ed954f1e3ce3ff6", "462f9bce619898638499350113bbc9b10a878d35da70740dc695a559eb88db7b"],
              ["be2062003c51cc3004682904330e4dee7f3dcd10b01e580bf1971b04d4cad297", "62188bc49d61e5428573d48a74e1c655b1c61090905682a0d5558ed72dccb9bc"],
              ["93144423ace3451ed29e0fb9ac2af211cb6e84a601df5993c419859fff5df04a", "7c10dfb164c3425f5c71a3f9d7992038f1065224f72bb9d1d902a6d13037b47c"],
              ["b015f8044f5fcbdcf21ca26d6c34fb8197829205c7b7d2a7cb66418c157b112c", "ab8c1e086d04e813744a655b2df8d5f83b3cdc6faa3088c1d3aea1454e3a1d5f"],
              ["d5e9e1da649d97d89e4868117a465a3a4f8a18de57a140d36b3f2af341a21b52", "4cb04437f391ed73111a13cc1d4dd0db1693465c2240480d8955e8592f27447a"],
              ["d3ae41047dd7ca065dbf8ed77b992439983005cd72e16d6f996a5316d36966bb", "bd1aeb21ad22ebb22a10f0303417c6d964f8cdd7df0aca614b10dc14d125ac46"],
              ["463e2763d885f958fc66cdd22800f0a487197d0a82e377b49f80af87c897b065", "bfefacdb0e5d0fd7df3a311a94de062b26b80c61fbc97508b79992671ef7ca7f"],
              ["7985fdfd127c0567c6f53ec1bb63ec3158e597c40bfe747c83cddfc910641917", "603c12daf3d9862ef2b25fe1de289aed24ed291e0ec6708703a5bd567f32ed03"],
              ["74a1ad6b5f76e39db2dd249410eac7f99e74c59cb83d2d0ed5ff1543da7703e9", "cc6157ef18c9c63cd6193d83631bbea0093e0968942e8c33d5737fd790e0db08"],
              ["30682a50703375f602d416664ba19b7fc9bab42c72747463a71d0896b22f6da3", "553e04f6b018b4fa6c8f39e7f311d3176290d0e0f19ca73f17714d9977a22ff8"],
              ["9e2158f0d7c0d5f26c3791efefa79597654e7a2b2464f52b1ee6c1347769ef57", "712fcdd1b9053f09003a3481fa7762e9ffd7c8ef35a38509e2fbf2629008373"],
              ["176e26989a43c9cfeba4029c202538c28172e566e3c4fce7322857f3be327d66", "ed8cc9d04b29eb877d270b4878dc43c19aefd31f4eee09ee7b47834c1fa4b1c3"],
              ["75d46efea3771e6e68abb89a13ad747ecf1892393dfc4f1b7004788c50374da8", "9852390a99507679fd0b86fd2b39a868d7efc22151346e1a3ca4726586a6bed8"],
              ["809a20c67d64900ffb698c4c825f6d5f2310fb0451c869345b7319f645605721", "9e994980d9917e22b76b061927fa04143d096ccc54963e6a5ebfa5f3f8e286c1"],
              ["1b38903a43f7f114ed4500b4eac7083fdefece1cf29c63528d563446f972c180", "4036edc931a60ae889353f77fd53de4a2708b26b6f5da72ad3394119daf408f9"]
            ]
          }
        }]
      })
    }, {
      "../elliptic": 77,
      assert: 5,
      "bn.js": 76,
      "hash.js": 90
    }],
    84: [function(require, module, exports) {
      var assert = require("assert");
      var bn = require("bn.js");
      var elliptic = require("../../elliptic");
      var utils = elliptic.utils;
      var KeyPair = require("./key");
      var Signature = require("./signature");

      function EC(options) {
        if (!(this instanceof EC)) return new EC(options);
        if (typeof options === "string") {
          assert(elliptic.curves.hasOwnProperty(options), "Unknown curve " + options);
          options = elliptic.curves[options]
        }
        if (options instanceof elliptic.curves.PresetCurve) options = {
          curve: options
        };
        this.curve = options.curve.curve;
        this.n = this.curve.n;
        this.nh = this.n.shrn(1);
        this.g = this.curve.g;
        this.g = options.curve.g;
        this.g.precompute(options.curve.n.bitLength() + 1);
        this.hash = options.hash || options.curve.hash
      }
      module.exports = EC;
      EC.prototype.keyPair = function keyPair(priv, pub) {
        return new KeyPair(this, priv, pub)
      };
      EC.prototype.genKeyPair = function genKeyPair(options) {
        if (!options) options = {};
        var drbg = new elliptic.hmacDRBG({
          hash: this.hash,
          pers: options.pers,
          entropy: options.entropy || elliptic.rand(this.hash.hmacStrength),
          nonce: this.n.toArray()
        });
        var bytes = this.n.byteLength();
        var ns2 = this.n.sub(new bn(2));
        do {
          var priv = new bn(drbg.generate(bytes));
          if (priv.cmp(ns2) > 0) continue;
          priv.iaddn(1);
          return this.keyPair(priv)
        } while (true)
      };
      EC.prototype._truncateToN = function truncateToN(msg, truncOnly) {
        var delta = msg.byteLength() * 8 - this.n.bitLength();
        if (delta > 0) msg = msg.shrn(delta);
        if (!truncOnly && msg.cmp(this.n) >= 0) return msg.sub(this.n);
        else return msg
      };
      EC.prototype.sign = function sign(msg, key, options) {
        key = this.keyPair(key, "hex");
        msg = this._truncateToN(new bn(msg, 16));
        if (!options) options = {};
        var bytes = this.n.byteLength();
        var bkey = key.getPrivate().toArray();
        for (var i = bkey.length; i < 21; i++) bkey.unshift(0);
        var nonce = msg.toArray();
        for (var i = nonce.length; i < bytes; i++) nonce.unshift(0);
        var drbg = new elliptic.hmacDRBG({
          hash: this.hash,
          entropy: bkey,
          nonce: nonce
        });
        var ns1 = this.n.sub(new bn(1));
        do {
          var k = new bn(drbg.generate(this.n.byteLength()));
          k = this._truncateToN(k, true);
          if (k.cmpn(1) <= 0 || k.cmp(ns1) >= 0) continue;
          var kp = this.g.mul(k);
          if (kp.isInfinity()) continue;
          var r = kp.getX().mod(this.n);
          if (r.cmpn(0) === 0) continue;
          var s = k.invm(this.n).mul(r.mul(key.getPrivate()).iadd(msg)).mod(this.n);
          if (s.cmpn(0) === 0) continue;
          if (options.canonical && s.cmp(this.nh) > 0) s = this.n.sub(s);
          return new Signature(r, s)
        } while (true)
      };
      EC.prototype.verify = function verify(msg, signature, key) {
        msg = this._truncateToN(new bn(msg, 16));
        key = this.keyPair(key, "hex");
        signature = new Signature(signature, "hex");
        var r = signature.r;
        var s = signature.s;
        if (r.cmpn(1) < 0 || r.cmp(this.n) >= 0) return false;
        if (s.cmpn(1) < 0 || s.cmp(this.n) >= 0) return false;
        var sinv = s.invm(this.n);
        var u1 = sinv.mul(msg).mod(this.n);
        var u2 = sinv.mul(r).mod(this.n);
        var p = this.g.mulAdd(u1, key.getPublic(), u2);
        if (p.isInfinity()) return false;
        return p.getX().mod(this.n).cmp(r) === 0
      }
    }, {
      "../../elliptic": 77,
      "./key": 85,
      "./signature": 86,
      assert: 5,
      "bn.js": 76
    }],
    85: [function(require, module, exports) {
      var assert = require("assert");
      var bn = require("bn.js");
      var elliptic = require("../../elliptic");
      var utils = elliptic.utils;

      function KeyPair(ec, priv, pub) {
        if (priv instanceof KeyPair) return priv;
        if (pub instanceof KeyPair) return pub;
        if (!priv) {
          priv = pub;
          pub = null
        }
        if (priv !== null && typeof priv === "object") {
          if (priv.x) {
            pub = priv;
            priv = null
          } else if (priv.priv || priv.pub) {
            pub = priv.pub;
            priv = priv.priv
          }
        }
        this.ec = ec;
        this.priv = null;
        this.pub = null;
        if (this._importPublicHex(priv, pub)) return;
        if (pub === "hex") pub = null;
        if (priv) this._importPrivate(priv);
        if (pub) this._importPublic(pub)
      }
      module.exports = KeyPair;
      KeyPair.prototype.validate = function validate() {
        var pub = this.getPublic();
        if (pub.isInfinity()) return {
          result: false,
          reason: "Invalid public key"
        };
        if (!pub.validate()) return {
          result: false,
          reason: "Public key is not a point"
        };
        if (!pub.mul(this.ec.curve.n).isInfinity()) return {
          result: false,
          reason: "Public key * N != O"
        };
        return {
          result: true,
          reason: null
        }
      };
      KeyPair.prototype.getPublic = function getPublic(compact, enc) {
        if (!this.pub) this.pub = this.ec.g.mul(this.priv);
        if (typeof compact === "string") {
          enc = compact;
          compact = null
        }
        if (!enc) return this.pub;
        var len = this.ec.curve.p.byteLength();
        var x = this.pub.getX().toArray();
        for (var i = x.length; i < len; i++) x.unshift(0);
        if (compact) {
          var res = [this.pub.getY().isEven() ? 2 : 3].concat(x)
        } else {
          var y = this.pub.getY().toArray();
          for (var i = y.length; i < len; i++) y.unshift(0);
          var res = [4].concat(x, y)
        }
        return utils.encode(res, enc)
      };
      KeyPair.prototype.getPrivate = function getPrivate(enc) {
        if (enc === "hex") return this.priv.toString(16, 2);
        else return this.priv
      };
      KeyPair.prototype._importPrivate = function _importPrivate(key) {
        this.priv = new bn(key, 16);
        this.priv = this.priv.mod(this.ec.curve.n)
      };
      KeyPair.prototype._importPublic = function _importPublic(key) {
        this.pub = this.ec.curve.point(key.x, key.y)
      };
      KeyPair.prototype._importPublicHex = function _importPublic(key, enc) {
        key = utils.toArray(key, enc);
        var len = this.ec.curve.p.byteLength();
        if (key[0] === 4 && key.length - 1 === 2 * len) {
          this.pub = this.ec.curve.point(key.slice(1, 1 + len), key.slice(1 + len, 1 + 2 * len))
        } else if ((key[0] === 2 || key[0] === 3) && key.length - 1 === len) {
          this.pub = this.ec.curve.pointFromX(key[0] === 3, key.slice(1, 1 + len))
        } else {
          return false
        }
        return true
      };
      KeyPair.prototype.derive = function derive(pub) {
        return pub.mul(this.priv).getX()
      };
      KeyPair.prototype.sign = function sign(msg) {
        return this.ec.sign(msg, this)
      };
      KeyPair.prototype.verify = function verify(msg, signature) {
        return this.ec.verify(msg, signature, this)
      };
      KeyPair.prototype.inspect = function inspect() {
        return "<Key priv: " + (this.priv && this.priv.toString(16, 2)) + " pub: " + (this.pub && this.pub.inspect()) + " >"
      }
    }, {
      "../../elliptic": 77,
      assert: 5,
      "bn.js": 76
    }],
    86: [function(require, module, exports) {
      var assert = require("assert");
      var bn = require("bn.js");
      var elliptic = require("../../elliptic");
      var utils = elliptic.utils;

      function Signature(r, s) {
        if (r instanceof Signature) return r;
        if (this._importDER(r, s)) return;
        assert(r && s, "Signature without r or s");
        this.r = new bn(r, 16);
        this.s = new bn(s, 16)
      }
      module.exports = Signature;
      Signature.prototype._importDER = function _importDER(data, enc) {
        data = utils.toArray(data, enc);
        if (data.length < 6 || data[0] !== 48 || data[2] !== 2) return false;
        var total = data[1];
        if (1 + total > data.length) return false;
        var rlen = data[3];
        if (rlen >= 128) return false;
        if (4 + rlen + 2 >= data.length) return false;
        if (data[4 + rlen] !== 2) return false;
        var slen = data[5 + rlen];
        if (slen >= 128) return false;
        if (4 + rlen + 2 + slen > data.length) return false;
        this.r = new bn(data.slice(4, 4 + rlen));
        this.s = new bn(data.slice(4 + rlen + 2, 4 + rlen + 2 + slen));
        return true
      };
      Signature.prototype.toDER = function toDER(enc) {
        var r = this.r.toArray();
        var s = this.s.toArray();
        if (r[0] & 128) r = [0].concat(r);
        if (s[0] & 128) s = [0].concat(s);
        var total = r.length + s.length + 4;
        var res = [48, total, 2, r.length];
        res = res.concat(r, [2, s.length], s);
        return utils.encode(res, enc)
      }
    }, {
      "../../elliptic": 77,
      assert: 5,
      "bn.js": 76
    }],
    87: [function(require, module, exports) {
      var assert = require("assert");
      var hash = require("hash.js");
      var elliptic = require("../elliptic");
      var utils = elliptic.utils;

      function HmacDRBG(options) {
        if (!(this instanceof HmacDRBG)) return new HmacDRBG(options);
        this.hash = options.hash;
        this.predResist = !!options.predResist;
        this.outLen = this.hash.outSize;
        this.minEntropy = options.minEntropy || this.hash.hmacStrength;
        this.reseed = null;
        this.reseedInterval = null;
        this.K = null;
        this.V = null;
        var entropy = utils.toArray(options.entropy, options.entropyEnc);
        var nonce = utils.toArray(options.nonce, options.nonceEnc);
        var pers = utils.toArray(options.pers, options.persEnc);
        assert(entropy.length >= this.minEntropy / 8, "Not enough entropy. Minimum is: " + this.minEntropy + " bits");
        this._init(entropy, nonce, pers)
      }
      module.exports = HmacDRBG;
      HmacDRBG.prototype._init = function init(entropy, nonce, pers) {
        var seed = entropy.concat(nonce).concat(pers);
        this.K = new Array(this.outLen / 8);
        this.V = new Array(this.outLen / 8);
        for (var i = 0; i < this.V.length; i++) {
          this.K[i] = 0;
          this.V[i] = 1
        }
        this._update(seed);
        this.reseed = 1;
        this.reseedInterval = 281474976710656
      };
      HmacDRBG.prototype._hmac = function hmac() {
        return new hash.hmac(this.hash, this.K)
      };
      HmacDRBG.prototype._update = function update(seed) {
        var kmac = this._hmac().update(this.V).update([0]);
        if (seed) kmac = kmac.update(seed);
        this.K = kmac.digest();
        this.V = this._hmac().update(this.V).digest();
        if (!seed) return;
        this.K = this._hmac().update(this.V).update([1]).update(seed).digest();
        this.V = this._hmac().update(this.V).digest()
      };
      HmacDRBG.prototype.reseed = function reseed(entropy, entropyEnc, add, addEnc) {
        if (typeof entropyEnc !== "string") {
          addEnc = add;
          add = entropyEnc;
          entropyEnc = null
        }
        entropy = utils.toBuffer(entropy, entropyEnc);
        add = utils.toBuffer(add, addEnc);
        assert(entropy.length >= this.minEntropy / 8, "Not enough entropy. Minimum is: " + this.minEntropy + " bits");
        this._update(entropy.concat(add || []));
        this.reseed = 1
      };
      HmacDRBG.prototype.generate = function generate(len, enc, add, addEnc) {
        if (this.reseed > this.reseedInterval) throw new Error("Reseed is required");
        if (typeof enc !== "string") {
          addEnc = add;
          add = enc;
          enc = null
        }
        if (add) {
          add = utils.toArray(add, addEnc);
          this._update(add)
        }
        var temp = [];
        while (temp.length < len) {
          this.V = this._hmac().update(this.V).digest();
          temp = temp.concat(this.V)
        }
        var res = temp.slice(0, len);
        this._update(add);
        this.reseed++;
        return utils.encode(res, enc)
      }
    }, {
      "../elliptic": 77,
      assert: 5,
      "hash.js": 90
    }],
    88: [function(require, module, exports) {
      var assert = require("assert");
      var bn = require("bn.js");
      var utils = exports;

      function toArray(msg, enc) {
        if (Array.isArray(msg)) return msg.slice();
        if (!msg) return [];
        var res = [];
        if (typeof msg === "string") {
          if (!enc) {
            for (var i = 0; i < msg.length; i++) {
              var c = msg.charCodeAt(i);
              var hi = c >> 8;
              var lo = c & 255;
              if (hi) res.push(hi, lo);
              else res.push(lo)
            }
          } else if (enc === "hex") {
            msg = msg.replace(/[^a-z0-9]+/gi, "");
            if (msg.length % 2 !== 0) msg = "0" + msg;
            for (var i = 0; i < msg.length; i += 2) res.push(parseInt(msg[i] + msg[i + 1], 16))
          }
        } else {
          for (var i = 0; i < msg.length; i++) res[i] = msg[i] | 0
        }
        return res
      }
      utils.toArray = toArray;

      function toHex(msg) {
        var res = "";
        for (var i = 0; i < msg.length; i++) res += zero2(msg[i].toString(16));
        return res
      }
      utils.toHex = toHex;
      utils.encode = function encode(arr, enc) {
        if (enc === "hex") return toHex(arr);
        else return arr
      };

      function zero2(word) {
        if (word.length === 1) return "0" + word;
        else return word
      }
      utils.zero2 = zero2;

      function getNAF(num, w) {
        var naf = [];
        var ws = 1 << w + 1;
        var k = num.clone();
        while (k.cmpn(1) >= 0) {
          var z;
          if (k.isOdd()) {
            var mod = k.andln(ws - 1);
            if (mod > (ws >> 1) - 1) z = (ws >> 1) - mod;
            else z = mod;
            k.isubn(z)
          } else {
            z = 0
          }
          naf.push(z);
          var shift = k.cmpn(0) !== 0 && k.andln(ws - 1) === 0 ? w + 1 : 1;
          for (var i = 1; i < shift; i++) naf.push(0);
          k.ishrn(shift)
        }
        return naf
      }
      utils.getNAF = getNAF;

      function getJSF(k1, k2) {
        var jsf = [
          [],
          []
        ];
        k1 = k1.clone();
        k2 = k2.clone();
        var d1 = 0;
        var d2 = 0;
        while (k1.cmpn(-d1) > 0 || k2.cmpn(-d2) > 0) {
          var m14 = k1.andln(3) + d1 & 3;
          var m24 = k2.andln(3) + d2 & 3;
          if (m14 === 3) m14 = -1;
          if (m24 === 3) m24 = -1;
          var u1;
          if ((m14 & 1) === 0) {
            u1 = 0
          } else {
            var m8 = k1.andln(7) + d1 & 7;
            if ((m8 === 3 || m8 === 5) && m24 === 2) u1 = -m14;
            else u1 = m14
          }
          jsf[0].push(u1);
          var u2;
          if ((m24 & 1) === 0) {
            u2 = 0
          } else {
            var m8 = k2.andln(7) + d2 & 7;
            if ((m8 === 3 || m8 === 5) && m14 === 2) u2 = -m24;
            else u2 = m24
          }
          jsf[1].push(u2);
          if (2 * d1 === u1 + 1) d1 = 1 - d1;
          if (2 * d2 === u2 + 1) d2 = 1 - d2;
          k1.ishrn(1);
          k2.ishrn(1)
        }
        return jsf
      }
      utils.getJSF = getJSF
    }, {
      assert: 5,
      "bn.js": 76
    }],
    89: [function(require, module, exports) {
      var r;
      module.exports = function rand(len) {
        if (!r) r = new Rand(null);
        return r.generate(len)
      };

      function Rand(rand) {
        this.rand = rand
      }
      module.exports.Rand = Rand;
      Rand.prototype.generate = function generate(len) {
        return this._rand(len)
      };
      if (typeof window === "object") {
        if (window.crypto && window.crypto.getRandomValues) {
          Rand.prototype._rand = function _rand(n) {
            var arr = new Uint8Array(n);
            window.crypto.getRandomValues(arr);
            return arr
          }
        } else if (window.msCrypto && window.msCrypto.getRandomValues) {
          Rand.prototype._rand = function _rand(n) {
            var arr = new Uint8Array(n);
            window.msCrypto.getRandomValues(arr);
            return arr
          }
        } else {
          Rand.prototype._rand = function() {
            throw new Error("Not implemented yet")
          }
        }
      } else {
        try {
          var crypto = require("cry" + "pto");
          Rand.prototype._rand = function _rand(n) {
            return crypto.randomBytes(n)
          }
        } catch (e) {
          Rand.prototype._rand = function _rand(n) {
            var res = new Uint8Array(n);
            for (var i = 0; i < res.length; i++) res[i] = this.rand.getByte();
            return res
          }
        }
      }
    }, {}],
    90: [function(require, module, exports) {
      var hash = exports;
      hash.utils = require("./hash/utils");
      hash.common = require("./hash/common");
      hash.sha = require("./hash/sha");
      hash.ripemd = require("./hash/ripemd");
      hash.hmac = require("./hash/hmac");
      hash.sha256 = hash.sha.sha256;
      hash.sha224 = hash.sha.sha224;
      hash.ripemd160 = hash.ripemd.ripemd160
    }, {
      "./hash/common": 91,
      "./hash/hmac": 92,
      "./hash/ripemd": 93,
      "./hash/sha": 94,
      "./hash/utils": 95
    }],
    91: [function(require, module, exports) {
      var hash = require("../hash");
      var utils = hash.utils;
      var assert = utils.assert;

      function BlockHash() {
        this.pending = null;
        this.pendingTotal = 0;
        this.blockSize = this.constructor.blockSize;
        this.outSize = this.constructor.outSize;
        this.hmacStrength = this.constructor.hmacStrength;
        this.endian = "big"
      }
      exports.BlockHash = BlockHash;
      BlockHash.prototype.update = function update(msg, enc) {
        msg = utils.toArray(msg, enc);
        if (!this.pending) this.pending = msg;
        else this.pending = this.pending.concat(msg);
        this.pendingTotal += msg.length;
        if (this.pending.length >= this.blockSize / 8) {
          msg = this.pending;
          var r = msg.length % (this.blockSize / 8);
          this.pending = msg.slice(msg.length - r, msg.length);
          if (this.pending.length === 0) this.pending = null;
          msg = utils.join32(msg.slice(0, msg.length - r), this.endian);
          for (var i = 0; i < msg.length; i += this.blockSize / 32) this._update(msg.slice(i, i + this.blockSize / 32))
        }
        return this
      };
      BlockHash.prototype.digest = function digest(enc) {
        this.update(this._pad());
        assert(this.pending === null);
        return this._digest(enc)
      };
      BlockHash.prototype._pad = function pad() {
        var len = this.pendingTotal;
        var bytes = this.blockSize / 8;
        var k = bytes - (len + 8) % bytes;
        var res = new Array(k + 8);
        res[0] = 128;
        for (var i = 1; i < k; i++) res[i] = 0;
        len <<= 3;
        if (this.endian === "big") {
          res[i++] = 0;
          res[i++] = 0;
          res[i++] = 0;
          res[i++] = 0;
          res[i++] = len >>> 24 & 255;
          res[i++] = len >>> 16 & 255;
          res[i++] = len >>> 8 & 255;
          res[i++] = len & 255
        } else {
          res[i++] = len & 255;
          res[i++] = len >>> 8 & 255;
          res[i++] = len >>> 16 & 255;
          res[i++] = len >>> 24 & 255;
          res[i++] = 0;
          res[i++] = 0;
          res[i++] = 0;
          res[i++] = 0
        }
        return res
      }
    }, {
      "../hash": 90
    }],
    92: [function(require, module, exports) {
      var hmac = exports;
      var hash = require("../hash");
      var utils = hash.utils;
      var assert = utils.assert;

      function Hmac(hash, key, enc) {
        if (!(this instanceof Hmac)) return new Hmac(hash, key, enc);
        this.Hash = hash;
        this.blockSize = hash.blockSize / 8;
        this.outSize = hash.outSize / 8;
        this._init(utils.toArray(key, enc))
      }
      module.exports = Hmac;
      Hmac.prototype._init = function init(key) {
        if (key.length > this.blockSize) key = (new this.Hash).update(key).digest();
        assert(key.length <= this.blockSize);
        for (var i = key.length; i < this.blockSize; i++) key.push(0);
        var okey = key.slice();
        for (var i = 0; i < key.length; i++) {
          key[i] ^= 54;
          okey[i] ^= 92
        }
        this.hash = {
          inner: (new this.Hash).update(key),
          outer: (new this.Hash).update(okey)
        }
      };
      Hmac.prototype.update = function update(msg, enc) {
        this.hash.inner.update(msg, enc);
        return this
      };
      Hmac.prototype.digest = function digest(enc) {
        this.hash.outer.update(this.hash.inner.digest());
        return this.hash.outer.digest(enc)
      }
    }, {
      "../hash": 90
    }],
    93: [function(require, module, exports) {
      var hash = require("../hash");
      var utils = hash.utils;
      var rotl32 = utils.rotl32;
      var sum32 = utils.sum32;
      var sum32_3 = utils.sum32_3;
      var sum32_4 = utils.sum32_4;
      var BlockHash = hash.common.BlockHash;

      function RIPEMD160() {
        if (!(this instanceof RIPEMD160)) return new RIPEMD160;
        BlockHash.call(this);
        this.h = [1732584193, 4023233417, 2562383102, 271733878, 3285377520];
        this.endian = "little"
      }
      utils.inherits(RIPEMD160, BlockHash);
      exports.ripemd160 = RIPEMD160;
      RIPEMD160.blockSize = 512;
      RIPEMD160.outSize = 160;
      RIPEMD160.hmacStrength = 192;
      RIPEMD160.prototype._update = function update(msg) {
        var A = this.h[0];
        var B = this.h[1];
        var C = this.h[2];
        var D = this.h[3];
        var E = this.h[4];
        var Ah = A;
        var Bh = B;
        var Ch = C;
        var Dh = D;
        var Eh = E;
        for (var j = 0; j < 80; j++) {
          var T = sum32(rotl32(sum32_4(A, f(j, B, C, D), msg[r[j]], K(j)), s[j]), E);
          A = E;
          E = D;
          D = rotl32(C, 10);
          C = B;
          B = T;
          T = sum32(rotl32(sum32_4(Ah, f(79 - j, Bh, Ch, Dh), msg[rh[j]], Kh(j)), sh[j]), Eh);
          Ah = Eh;
          Eh = Dh;
          Dh = rotl32(Ch, 10);
          Ch = Bh;
          Bh = T
        }
        T = sum32_3(this.h[1], C, Dh);
        this.h[1] = sum32_3(this.h[2], D, Eh);
        this.h[2] = sum32_3(this.h[3], E, Ah);
        this.h[3] = sum32_3(this.h[4], A, Bh);
        this.h[4] = sum32_3(this.h[0], B, Ch);
        this.h[0] = T
      };
      RIPEMD160.prototype._digest = function digest(enc) {
        if (enc === "hex") return utils.toHex32(this.h, "little");
        else return utils.split32(this.h, "little")
      };

      function f(j, x, y, z) {
        if (j <= 15) return x ^ y ^ z;
        else if (j <= 31) return x & y | ~x & z;
        else if (j <= 47) return (x | ~y) ^ z;
        else if (j <= 63) return x & z | y & ~z;
        else return x ^ (y | ~z)
      }

      function K(j) {
        if (j <= 15) return 0;
        else if (j <= 31) return 1518500249;
        else if (j <= 47) return 1859775393;
        else if (j <= 63) return 2400959708;
        else return 2840853838
      }

      function Kh(j) {
        if (j <= 15) return 1352829926;
        else if (j <= 31) return 1548603684;
        else if (j <= 47) return 1836072691;
        else if (j <= 63) return 2053994217;
        else return 0
      }
      var r = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8, 3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12, 1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2, 4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13];
      var rh = [5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12, 6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2, 15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13, 8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14, 12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11];
      var s = [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8, 7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12, 11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5, 11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12, 9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6];
      var sh = [8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6, 9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11, 9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5, 15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8, 8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11]
    }, {
      "../hash": 90
    }],
    94: [function(require, module, exports) {
      var hash = require("../hash");
      var utils = hash.utils;
      var assert = utils.assert;
      var rotr32 = utils.rotr32;
      var rotl32 = utils.rotl32;
      var sum32 = utils.sum32;
      var sum32_4 = utils.sum32_4;
      var sum32_5 = utils.sum32_5;
      var BlockHash = hash.common.BlockHash;
      var sha256_K = [1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221, 3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580, 3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986, 2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895, 666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037, 2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344, 430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779, 1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298];

      function SHA256() {
        if (!(this instanceof SHA256)) return new SHA256;
        BlockHash.call(this);
        this.h = [1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225];
        this.k = sha256_K
      }
      utils.inherits(SHA256, BlockHash);
      exports.sha256 = SHA256;
      SHA256.blockSize = 512;
      SHA256.outSize = 256;
      SHA256.hmacStrength = 192;
      SHA256.prototype._update = function _update(msg) {
        var W = new Array(64);
        for (var i = 0; i < 16; i++) W[i] = msg[i];
        for (; i < W.length; i++) W[i] = sum32_4(g1_256(W[i - 2]), W[i - 7], g0_256(W[i - 15]), W[i - 16]);
        var a = this.h[0];
        var b = this.h[1];
        var c = this.h[2];
        var d = this.h[3];
        var e = this.h[4];
        var f = this.h[5];
        var g = this.h[6];
        var h = this.h[7];
        assert(this.k.length === W.length);
        for (var i = 0; i < W.length; i++) {
          var T1 = sum32_5(h, s1_256(e), ch32(e, f, g), this.k[i], W[i]);
          var T2 = sum32(s0_256(a), maj32(a, b, c));
          h = g;
          g = f;
          f = e;
          e = sum32(d, T1);
          d = c;
          c = b;
          b = a;
          a = sum32(T1, T2)
        }
        this.h[0] = sum32(this.h[0], a);
        this.h[1] = sum32(this.h[1], b);
        this.h[2] = sum32(this.h[2], c);
        this.h[3] = sum32(this.h[3], d);
        this.h[4] = sum32(this.h[4], e);
        this.h[5] = sum32(this.h[5], f);
        this.h[6] = sum32(this.h[6], g);
        this.h[7] = sum32(this.h[7], h)
      };
      SHA256.prototype._digest = function digest(enc) {
        if (enc === "hex") return utils.toHex32(this.h, "big");
        else return utils.split32(this.h, "big")
      };

      function SHA224() {
        if (!(this instanceof SHA224)) return new SHA224;
        SHA256.call(this);
        this.h = [3238371032, 914150663, 812702999, 4144912697, 4290775857, 1750603025, 1694076839, 3204075428]
      }
      utils.inherits(SHA224, SHA256);
      exports.sha224 = SHA224;
      SHA224.blockSize = 512;
      SHA224.outSize = 224;
      SHA224.hmacStrength = 192;
      SHA224.prototype._digest = function digest(enc) {
        if (enc === "hex") return utils.toHex32(this.h.slice(0, 7), "big");
        else return utils.split32(this.h.slice(0, 7), "big")
      };

      function ch32(x, y, z) {
        return x & y ^ ~x & z
      }

      function maj32(x, y, z) {
        return x & y ^ x & z ^ y & z
      }

      function s0_256(x) {
        return rotr32(x, 2) ^ rotr32(x, 13) ^ rotr32(x, 22)
      }

      function s1_256(x) {
        return rotr32(x, 6) ^ rotr32(x, 11) ^ rotr32(x, 25)
      }

      function g0_256(x) {
        return rotr32(x, 7) ^ rotr32(x, 18) ^ x >>> 3
      }

      function g1_256(x) {
        return rotr32(x, 17) ^ rotr32(x, 19) ^ x >>> 10
      }
    }, {
      "../hash": 90
    }],
    95: [function(require, module, exports) {
      var utils = exports;

      function toArray(msg, enc) {
        if (Array.isArray(msg)) return msg.slice();
        if (!msg) return [];
        var res = [];
        if (typeof msg === "string") {
          if (!enc) {
            for (var i = 0; i < msg.length; i++) {
              var c = msg.charCodeAt(i);
              var hi = c >> 8;
              var lo = c & 255;
              if (hi) res.push(hi, lo);
              else res.push(lo)
            }
          } else if (enc === "hex") {
            msg = msg.replace(/[^a-z0-9]+/gi, "");
            if (msg.length % 2 != 0) msg = "0" + msg;
            for (var i = 0; i < msg.length; i += 2) res.push(parseInt(msg[i] + msg[i + 1], 16))
          }
        } else {
          for (var i = 0; i < msg.length; i++) res[i] = msg[i] | 0
        }
        return res
      }
      utils.toArray = toArray;

      function toHex(msg) {
        var res = "";
        for (var i = 0; i < msg.length; i++) res += zero2(msg[i].toString(16));
        return res
      }
      utils.toHex = toHex;

      function toHex32(msg, endian) {
        var res = "";
        for (var i = 0; i < msg.length; i++) {
          var w = msg[i];
          if (endian === "little") {
            w = w >>> 24 | w >>> 8 & 65280 | w << 8 & 16711680 | (w & 255) << 24;
            if (w < 0) w += 4294967296
          }
          res += zero8(w.toString(16))
        }
        return res
      }
      utils.toHex32 = toHex32;

      function zero2(word) {
        if (word.length === 1) return "0" + word;
        else return word
      }
      utils.zero2 = zero2;

      function zero8(word) {
        if (word.length === 7) return "0" + word;
        else if (word.length === 6) return "00" + word;
        else if (word.length === 5) return "000" + word;
        else if (word.length === 4) return "0000" + word;
        else if (word.length === 3) return "00000" + word;
        else if (word.length === 2) return "000000" + word;
        else if (word.length === 1) return "0000000" + word;
        else return word
      }
      utils.zero8 = zero8;

      function join32(msg, endian) {
        assert(msg.length % 4 === 0);
        var res = new Array(msg.length / 4);
        for (var i = 0, k = 0; i < res.length; i++, k += 4) {
          var w;
          if (endian === "big") w = msg[k] << 24 | msg[k + 1] << 16 | msg[k + 2] << 8 | msg[k + 3];
          else w = msg[k + 3] << 24 | msg[k + 2] << 16 | msg[k + 1] << 8 | msg[k];
          if (w < 0) w += 4294967296;
          res[i] = w
        }
        return res
      }
      utils.join32 = join32;

      function split32(msg, endian) {
        var res = new Array(msg.length * 4);
        for (var i = 0, k = 0; i < msg.length; i++, k += 4) {
          var m = msg[i];
          if (endian === "big") {
            res[k] = m >>> 24;
            res[k + 1] = m >>> 16 & 255;
            res[k + 2] = m >>> 8 & 255;
            res[k + 3] = m & 255
          } else {
            res[k + 3] = m >>> 24;
            res[k + 2] = m >>> 16 & 255;
            res[k + 1] = m >>> 8 & 255;
            res[k] = m & 255
          }
        }
        return res
      }
      utils.split32 = split32;

      function rotr32(w, b) {
        return w >>> b | w << 32 - b
      }
      utils.rotr32 = rotr32;

      function rotl32(w, b) {
        return w << b | w >>> 32 - b
      }
      utils.rotl32 = rotl32;

      function sum32(a, b) {
        var r = a + b & 4294967295;
        if (r < 0) r += 4294967296;
        return r
      }
      utils.sum32 = sum32;

      function sum32_3(a, b, c) {
        var r = a + b + c & 4294967295;
        if (r < 0) r += 4294967296;
        return r
      }
      utils.sum32_3 = sum32_3;

      function sum32_4(a, b, c, d) {
        var r = a + b + c + d & 4294967295;
        if (r < 0) r += 4294967296;
        return r
      }
      utils.sum32_4 = sum32_4;

      function sum32_5(a, b, c, d, e) {
        var r = a + b + c + d + e & 4294967295;
        if (r < 0) r += 4294967296;
        return r
      }
      utils.sum32_5 = sum32_5;

      function assert(cond, msg) {
        if (!cond) throw new Error(msg || "Assertion failed")
      }
      utils.assert = assert;
      if (typeof Object.create === "function") {
        utils.inherits = function inherits(ctor, superCtor) {
          ctor.super_ = superCtor;
          ctor.prototype = Object.create(superCtor.prototype, {
            constructor: {
              value: ctor,
              enumerable: false,
              writable: true,
              configurable: true
            }
          })
        }
      } else {
        utils.inherits = function inherits(ctor, superCtor) {
          ctor.super_ = superCtor;
          var TempCtor = function() {};
          TempCtor.prototype = superCtor.prototype;
          ctor.prototype = new TempCtor;
          ctor.prototype.constructor = ctor
        }
      }
    }, {}],
    96: [function(require, module, exports) {
      module.exports = {
        name: "elliptic",
        version: "0.15.15",
        description: "EC cryptography",
        main: "lib/elliptic.js",
        scripts: {
          test: "mocha --reporter=spec test/*-test.js"
        },
        repository: {
          type: "git",
          url: "git@github.com:indutny/elliptic"
        },
        keywords: ["EC", "Elliptic", "curve", "Cryptography"],
        author: {
          name: "Fedor Indutny",
          email: "fedor@indutny.com"
        },
        license: "MIT",
        bugs: {
          url: "https://github.com/indutny/elliptic/issues"
        },
        homepage: "https://github.com/indutny/elliptic",
        devDependencies: {
          browserify: "^3.44.2",
          mocha: "^1.18.2",
          "uglify-js": "^2.4.13"
        },
        dependencies: {
          "bn.js": "^0.15.0",
          brorand: "^1.0.1",
          "hash.js": "^0.2.0",
          inherits: "^2.0.1"
        },
        gitHead: "4bf1f50607285bff4ae19521217dbc801c3d36af",
        _id: "elliptic@0.15.15",
        _shasum: "63269184a856d6e00871e84f37a8401ff84e4aea",
        _from: "elliptic@^0.15.14",
        _npmVersion: "2.1.6",
        _nodeVersion: "0.10.33",
        _npmUser: {
          name: "indutny",
          email: "fedor@indutny.com"
        },
        maintainers: [{
          name: "indutny",
          email: "fedor@indutny.com"
        }],
        dist: {
          shasum: "63269184a856d6e00871e84f37a8401ff84e4aea",
          tarball: "http://registry.npmjs.org/elliptic/-/elliptic-0.15.15.tgz"
        },
        directories: {},
        _resolved: "https://registry.npmjs.org/elliptic/-/elliptic-0.15.15.tgz"
      }
    }, {}],
    97: [function(require, module, exports) {
      module.exports = require(12)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/inherits/inherits_browser.js": 12
    }],
    98: [function(require, module, exports) {
      exports.strip = function strip(artifact) {
        artifact = artifact.toString();
        var startRegex = /^-----BEGIN (.*)-----\n/;
        var match = startRegex.exec(artifact);
        var tag = match[1];
        var endRegex = new RegExp("\n-----END " + tag + "-----(\n*)$");
        var base64 = artifact.slice(match[0].length).replace(endRegex, "").replace(/\n/g, "");
        return {
          tag: tag,
          base64: base64
        }
      };
      var wrap = function wrap(str, l) {
        var chunks = [];
        while (str) {
          if (str.length < l) {
            chunks.push(str);
            break
          } else {
            chunks.push(str.substr(0, l));
            str = str.substr(l)
          }
        }
        return chunks.join("\n")
      };
      exports.assemble = function assemble(info) {
        var tag = info.tag;
        var base64 = info.base64;
        var startLine = "-----BEGIN " + tag + "-----";
        var endLine = "-----END " + tag + "-----";
        return startLine + "\n" + wrap(base64, 64) + "\n" + endLine + "\n"
      }
    }, {}],
    99: [function(require, module, exports) {
      module.exports = require(16)
    }, {
      "./_stream_readable": 101,
      "./_stream_writable": 103,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js": 16,
      _process: 14,
      "core-util-is": 104,
      inherits: 97
    }],
    100: [function(require, module, exports) {
      module.exports = require(17)
    }, {
      "./_stream_transform": 102,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/lib/_stream_passthrough.js": 17,
      "core-util-is": 104,
      inherits: 97
    }],
    101: [function(require, module, exports) {
      module.exports = require(18)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/lib/_stream_readable.js": 18,
      _process: 14,
      buffer: 7,
      "core-util-is": 104,
      events: 11,
      inherits: 97,
      isarray: 105,
      stream: 26,
      "string_decoder/": 106
    }],
    102: [function(require, module, exports) {
      module.exports = require(19)
    }, {
      "./_stream_duplex": 99,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/lib/_stream_transform.js": 19,
      "core-util-is": 104,
      inherits: 97
    }],
    103: [function(require, module, exports) {
      module.exports = require(20)
    }, {
      "./_stream_duplex": 99,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/lib/_stream_writable.js": 20,
      _process: 14,
      buffer: 7,
      "core-util-is": 104,
      inherits: 97,
      stream: 26
    }],
    104: [function(require, module, exports) {
      module.exports = require(21)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js": 21,
      buffer: 7
    }],
    105: [function(require, module, exports) {
      module.exports = require(13)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/isarray/index.js": 13
    }],
    106: [function(require, module, exports) {
      module.exports = require(27)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/string_decoder/index.js": 27,
      buffer: 7
    }],
    107: [function(require, module, exports) {
      module.exports = require(23)
    }, {
      "./lib/_stream_duplex.js": 99,
      "./lib/_stream_passthrough.js": 100,
      "./lib/_stream_readable.js": 101,
      "./lib/_stream_transform.js": 102,
      "./lib/_stream_writable.js": 103,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/readable-stream/readable.js": 23,
      stream: 26
    }],
    108: [function(require, module, exports) {
      (function(Buffer) {
        var pemstrip = require("pemstrip");
        var asn1 = require("./asn1");
        var aesid = require("./aesid.json");
        module.exports = parseKeys;

        function parseKeys(buffer, crypto) {
          var password;
          if (typeof buffer === "object" && !Buffer.isBuffer(buffer)) {
            password = buffer.passphrase;
            buffer = buffer.key
          }
          var stripped = pemstrip.strip(buffer);
          var type = stripped.tag;
          var data = new Buffer(stripped.base64, "base64");
          var subtype, ndata;
          switch (type) {
            case "PUBLIC KEY":
              ndata = asn1.PublicKey.decode(data, "der");
              subtype = ndata.algorithm.algorithm.join(".");
              switch (subtype) {
                case "1.2.840.113549.1.1.1":
                  return asn1.RSAPublicKey.decode(ndata.subjectPublicKey.data, "der");
                case "1.2.840.10045.2.1":
                  return {
                    type: "ec",
                    data: asn1.ECPublicKey.decode(data, "der")
                  };
                default:
                  throw new Error("unknown key id " + subtype)
              }
              throw new Error("unknown key type " + type);
            case "ENCRYPTED PRIVATE KEY":
              data = asn1.EncryptedPrivateKey.decode(data, "der");
              data = decrypt(crypto, data, password);
            case "PRIVATE KEY":
              ndata = asn1.PrivateKey.decode(data, "der");
              subtype = ndata.algorithm.algorithm.join(".");
              switch (subtype) {
                case "1.2.840.113549.1.1.1":
                  return asn1.RSAPrivateKey.decode(ndata.subjectPrivateKey, "der");
                case "1.2.840.10045.2.1":
                  ndata = asn1.ECPrivateWrap.decode(data, "der");
                  return {
                    curve: ndata.algorithm.curve,
                    privateKey: asn1.ECPrivateKey.decode(ndata.subjectPrivateKey, "der").privateKey
                  };
                default:
                  throw new Error("unknown key id " + subtype)
              }
              throw new Error("unknown key type " + type);
            case "RSA PUBLIC KEY":
              return asn1.RSAPublicKey.decode(data, "der");
            case "RSA PRIVATE KEY":
              return asn1.RSAPrivateKey.decode(data, "der");
            case "EC PRIVATE KEY":
              data = asn1.ECPrivateKey.decode(data, "der");
              return {
                curve: data.parameters.value,
                privateKey: data.privateKey
              };
            default:
              throw new Error("unknown key type " + type)
          }
        }

        function decrypt(crypto, data, password) {
          var salt = data.algorithm.decrypt.kde.kdeparams.salt;
          var iters = data.algorithm.decrypt.kde.kdeparams.iters;
          var algo = aesid[data.algorithm.decrypt.cipher.algo.join(".")];
          var iv = data.algorithm.decrypt.cipher.iv;
          var cipherText = data.subjectPrivateKey;
          var keylen = parseInt(algo.split("-")[1], 10) / 8;
          var key = crypto.pbkdf2Sync(password, salt, iters, keylen);
          var cipher = crypto.createDecipheriv(algo, key, iv);
          var out = [];
          out.push(cipher.update(cipherText));
          out.push(cipher.final());
          return Buffer.concat(out)
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./aesid.json": 58,
      "./asn1": 60,
      buffer: 7,
      pemstrip: 98
    }],
    109: [function(require, module, exports) {
      (function(Buffer) {
        var parseKeys = require("./parseKeys");
        var bn = require("bn.js");
        var elliptic = require("elliptic");
        module.exports = sign;

        function sign(hash, key, crypto) {
          var priv = parseKeys(key, crypto);
          if (priv.curve) {
            return ecSign(hash, priv, crypto)
          }
          var len = priv.modulus.byteLength();
          var pad = [0, 1];
          while (hash.length + pad.length + 1 < len) {
            pad.push(255)
          }
          pad.push(0);
          var i = -1;
          while (++i < hash.length) {
            pad.push(hash[i])
          }
          var out = crt(pad, priv);
          if (out.length < len) {
            var prefix = new Buffer(len - out.length);
            prefix.fill(0);
            out = Buffer.concat([prefix, out], len)
          }
          return out
        }

        function crt(msg, priv) {
          var c1 = new bn(msg).toRed(bn.mont(priv.prime1));
          var c2 = new bn(msg).toRed(bn.mont(priv.prime2));
          var qinv = new bn(priv.coefficient);
          var p = new bn(priv.prime1);
          var q = new bn(priv.prime2);
          var m1 = c1.redPow(priv.exponent1);
          var m2 = c2.redPow(priv.exponent2);
          m1 = m1.fromRed();
          m2 = m2.fromRed();
          var h = m1.isub(m2).imul(qinv).mod(p);
          h.imul(q);
          m2.iadd(h);
          return new Buffer(m2.toArray())
        }

        function ecSign(hash, priv, crypto) {
          elliptic.rand = crypto.randomBytes;
          var curve;
          if (priv.curve.join(".") === "1.3.132.0.10") {
            curve = new elliptic.ec("secp256k1")
          }
          var key = curve.genKeyPair();
          key._importPrivate(priv.privateKey);
          var out = key.sign(hash);
          return new Buffer(out.toDER())
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./parseKeys": 108,
      "bn.js": 76,
      buffer: 7,
      elliptic: 77
    }],
    110: [function(require, module, exports) {
      (function(Buffer) {
        var parseKeys = require("./parseKeys");
        var elliptic = require("elliptic");
        var bn = require("bn.js");
        module.exports = verify;

        function verify(sig, hash, key) {
          var pub = parseKeys(key);
          if (pub.type === "ec") {
            return ecVerify(sig, hash, pub)
          }
          var red = bn.mont(pub.modulus);
          sig = new bn(sig).toRed(red);
          sig = sig.redPow(new bn(pub.publicExponent));
          sig = new Buffer(sig.fromRed().toArray());
          sig = sig.slice(sig.length - hash.length);
          var out = 0;
          var len = sig.length;
          var i = -1;
          while (++i < len) {
            out += sig[i] ^ hash[i]
          }
          return !out
        }

        function ecVerify(sig, hash, pub) {
          var curve;
          if (pub.data.algorithm.curve.join(".") === "1.3.132.0.10") {
            curve = new elliptic.ec("secp256k1")
          }
          var pubkey = pub.data.subjectPrivateKey.data;
          return curve.verify(hash.toString("hex"), sig.toString("hex"), pubkey.toString("hex"))
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./parseKeys": 108,
      "bn.js": 76,
      buffer: 7,
      elliptic: 77
    }],
    111: [function(require, module, exports) {
      (function(Buffer) {
        var elliptic = require("elliptic");
        var BN = require("bn.js");
        module.exports = ECDH;

        function ECDH(curve, crypto) {
          elliptic.rand = crypto.randomBytes;
          this.curve = new elliptic.ec(curve);
          this.keys = void 0
        }
        ECDH.prototype.generateKeys = function(enc, format) {
          this.keys = this.curve.genKeyPair();
          return this.getPublicKey(enc, format)
        };
        ECDH.prototype.computeSecret = function(other, inenc, enc) {
          inenc = inenc || "utf8";
          if (!Buffer.isBuffer(other)) {
            other = new Buffer(other, inenc)
          }
          other = new BN(other);
          other = other.toString(16);
          var otherPub = this.curve.keyPair(other, "hex").getPublic();
          var out = otherPub.mul(this.keys.getPrivate()).getX();
          return returnValue(out, enc)
        };
        ECDH.prototype.getPublicKey = function(enc, format) {
          var key = this.keys.getPublic(format === "compressed", true);
          if (format === "hybrid") {
            if (key[key.length - 1] % 2) {
              key[0] = 7
            } else {
              key[0] = 6
            }
          }
          return returnValue(key, enc)
        };
        ECDH.prototype.getPrivateKey = function(enc) {
          return returnValue(this.keys.getPrivate(), enc)
        };
        ECDH.prototype.setPublicKey = function(pub, enc) {
          enc = enc || "utf8";
          if (!Buffer.isBuffer(pub)) {
            pub = new Buffer(pub, enc)
          }
          var pkey = new BN(pub);
          pkey = pkey.toArray();
          this.keys._importPublicHex(pkey)
        };
        ECDH.prototype.setPrivateKey = function(priv, enc) {
          enc = enc || "utf8";
          if (!Buffer.isBuffer(priv)) {
            priv = new Buffer(priv, enc)
          }
          var _priv = new BN(priv);
          _priv = _priv.toString(16);
          this.keys._importPrivate(_priv)
        };

        function returnValue(bn, enc) {
          if (!Array.isArray(bn)) {
            bn = bn.toArray()
          }
          var buf = new Buffer(bn);
          if (!enc) {
            return buf
          } else {
            return buf.toString(enc)
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "bn.js": 113,
      buffer: 7,
      elliptic: 114
    }],
    112: [function(require, module, exports) {
      var ECDH = require("./ecdh");
      module.exports = function(crypto, exports) {
        exports.createECDH = function(curve) {
          return new ECDH(curve, crypto)
        }
      }
    }, {
      "./ecdh": 111
    }],
    113: [function(require, module, exports) {
      module.exports = require(76)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/bn.js/lib/bn.js": 76
    }],
    114: [function(require, module, exports) {
      module.exports = require(77)
    }, {
      "../package.json": 134,
      "./elliptic/curve": 117,
      "./elliptic/curves": 120,
      "./elliptic/ec": 121,
      "./elliptic/hmac-drbg": 124,
      "./elliptic/utils": 125,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic.js": 77,
      brorand: 126
    }],
    115: [function(require, module, exports) {
      module.exports = require(78)
    }, {
      "../../elliptic": 114,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/curve/base.js": 78,
      assert: 5,
      "bn.js": 113
    }],
    116: [function(require, module, exports) {
      module.exports = require(79)
    }, {
      "../../elliptic": 114,
      "../curve": 117,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/curve/edwards.js": 79,
      assert: 5,
      "bn.js": 113,
      inherits: 133
    }],
    117: [function(require, module, exports) {
      module.exports = require(80)
    }, {
      "./base": 115,
      "./edwards": 116,
      "./mont": 118,
      "./short": 119,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/curve/index.js": 80
    }],
    118: [function(require, module, exports) {
      module.exports = require(81)
    }, {
      "../../elliptic": 114,
      "../curve": 117,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/curve/mont.js": 81,
      assert: 5,
      "bn.js": 113,
      inherits: 133
    }],
    119: [function(require, module, exports) {
      module.exports = require(82)
    }, {
      "../../elliptic": 114,
      "../curve": 117,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/curve/short.js": 82,
      assert: 5,
      "bn.js": 113,
      inherits: 133
    }],
    120: [function(require, module, exports) {
      module.exports = require(83)
    }, {
      "../elliptic": 114,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/curves.js": 83,
      assert: 5,
      "bn.js": 113,
      "hash.js": 127
    }],
    121: [function(require, module, exports) {
      module.exports = require(84)
    }, {
      "../../elliptic": 114,
      "./key": 122,
      "./signature": 123,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/ec/index.js": 84,
      assert: 5,
      "bn.js": 113
    }],
    122: [function(require, module, exports) {
      module.exports = require(85)
    }, {
      "../../elliptic": 114,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/ec/key.js": 85,
      assert: 5,
      "bn.js": 113
    }],
    123: [function(require, module, exports) {
      module.exports = require(86)
    }, {
      "../../elliptic": 114,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/ec/signature.js": 86,
      assert: 5,
      "bn.js": 113
    }],
    124: [function(require, module, exports) {
      module.exports = require(87)
    }, {
      "../elliptic": 114,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/hmac-drbg.js": 87,
      assert: 5,
      "hash.js": 127
    }],
    125: [function(require, module, exports) {
      module.exports = require(88)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/lib/elliptic/utils.js": 88,
      assert: 5,
      "bn.js": 113
    }],
    126: [function(require, module, exports) {
      module.exports = require(89)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/brorand/index.js": 89
    }],
    127: [function(require, module, exports) {
      module.exports = require(90)
    }, {
      "./hash/common": 128,
      "./hash/hmac": 129,
      "./hash/ripemd": 130,
      "./hash/sha": 131,
      "./hash/utils": 132,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/hash.js/lib/hash.js": 90
    }],
    128: [function(require, module, exports) {
      module.exports = require(91)
    }, {
      "../hash": 127,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/hash.js/lib/hash/common.js": 91
    }],
    129: [function(require, module, exports) {
      module.exports = require(92)
    }, {
      "../hash": 127,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/hash.js/lib/hash/hmac.js": 92
    }],
    130: [function(require, module, exports) {
      module.exports = require(93)
    }, {
      "../hash": 127,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/hash.js/lib/hash/ripemd.js": 93
    }],
    131: [function(require, module, exports) {
      module.exports = require(94)
    }, {
      "../hash": 127,
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/hash.js/lib/hash/sha.js": 94
    }],
    132: [function(require, module, exports) {
      module.exports = require(95)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/hash.js/lib/hash/utils.js": 95
    }],
    133: [function(require, module, exports) {
      module.exports = require(12)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/browserify/node_modules/inherits/inherits_browser.js": 12
    }],
    134: [function(require, module, exports) {
      module.exports = require(96)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/package.json": 96
    }],
    135: [function(require, module, exports) {
      (function(Buffer) {
        var BN = require("bn.js");
        var MillerRabin = require("miller-rabin");
        var millerRabin = new MillerRabin;
        var TWENTYFOUR = new BN(24);
        var ELEVEN = new BN(11);
        var TEN = new BN(10);
        var THREE = new BN(3);
        var SEVEN = new BN(7);
        var primes = require("./generatePrime");
        module.exports = DH;

        function setPublicKey(pub, enc) {
          enc = enc || "utf8";
          if (!Buffer.isBuffer(pub)) {
            pub = new Buffer(pub, enc)
          }
          this._pub = new BN(pub)
        }

        function setPrivateKey(priv, enc) {
          enc = enc || "utf8";
          if (!Buffer.isBuffer(priv)) {
            priv = new Buffer(priv, enc)
          }
          this._priv = new BN(priv)
        }
        var primeCache = {};

        function checkPrime(prime, generator) {
          var gen = generator.toString("hex");
          var hex = [gen, prime.toString(16)].join("_");
          if (hex in primeCache) {
            return primeCache[hex]
          }
          var error = 0;
          if (prime.isEven() || !primes.simpleSieve || !primes.fermatTest(prime) || !millerRabin.test(prime)) {
            error += 1;
            if (gen === "02" || gen === "05") {
              error += 8
            } else {
              error += 4
            }
            primeCache[hex] = error;
            return error
          }
          if (!millerRabin.test(prime.shrn(1))) {
            error += 2
          }
          var gen = generator.toString("hex");
          var rem;
          switch (gen) {
            case "02":
              if (prime.mod(TWENTYFOUR).cmp(ELEVEN)) {
                error += 8
              }
              break;
            case "05":
              rem = prime.mod(TEN);
              if (rem.cmp(THREE) && rem.cmp(SEVEN)) {
                error += 8
              }
              break;
            default:
              error += 4
          }
          primeCache[hex] = error;
          return error
        }

        function defineError(self, error) {
          try {
            Object.defineProperty(self, "verifyError", {
              enumerable: true,
              value: error,
              writable: false
            })
          } catch (e) {
            self.verifyError = error
          }
        }

        function DH(prime, generator, crypto, malleable) {
          this.setGenerator(generator);
          this.__prime = new BN(prime);
          this._prime = BN.mont(this.__prime);
          this._pub = void 0;
          this._priv = void 0;
          if (malleable) {
            this.setPublicKey = setPublicKey;
            this.setPrivateKey = setPrivateKey;
            defineError(this, checkPrime(this.__prime, generator))
          } else {
            defineError(this, 8)
          }
          this._makeNum = function makeNum() {
            return crypto.randomBytes(192)
          }
        }
        DH.prototype.generateKeys = function() {
          if (!this._priv) {
            this._priv = new BN(this._makeNum())
          }
          this._pub = this._gen.toRed(this._prime).redPow(this._priv).fromRed();
          return this.getPublicKey()
        };
        DH.prototype.computeSecret = function(other) {
          other = new BN(other);
          other = other.toRed(this._prime);
          var secret = other.redPow(this._priv).fromRed();
          var out = new Buffer(secret.toArray());
          var prime = this.getPrime();
          if (out.length < prime.length) {
            var front = new Buffer(prime.length - out.length);
            front.fill(0);
            out = Buffer.concat([front, out])
          }
          return out
        };
        DH.prototype.getPublicKey = function getPublicKey(enc) {
          return returnValue(this._pub, enc)
        };
        DH.prototype.getPrivateKey = function getPrivateKey(enc) {
          return returnValue(this._priv, enc)
        };
        DH.prototype.getPrime = function(enc) {
          return returnValue(this.__prime, enc)
        };
        DH.prototype.getGenerator = function(enc) {
          return returnValue(this._gen, enc)
        };
        DH.prototype.setGenerator = function(gen, enc) {
          enc = enc || "utf8";
          if (!Buffer.isBuffer(gen)) {
            gen = new Buffer(gen, enc)
          }
          this._gen = new BN(gen)
        };

        function returnValue(bn, enc) {
          var buf = new Buffer(bn.toArray());
          if (!enc) {
            return buf
          } else {
            return buf.toString(enc)
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./generatePrime": 136,
      "bn.js": 138,
      buffer: 7,
      "miller-rabin": 139
    }],
    136: [function(require, module, exports) {
      module.exports = findPrime;
      findPrime.simpleSieve = simpleSieve;
      findPrime.fermatTest = fermatTest;
      var BN = require("bn.js");
      var TWENTYFOUR = new BN(24);
      var MillerRabin = require("miller-rabin");
      var millerRabin = new MillerRabin;
      var ONE = new BN(1);
      var TWO = new BN(2);
      var FIVE = new BN(5);
      var SIXTEEN = new BN(16);
      var EIGHT = new BN(8);
      var TEN = new BN(10);
      var THREE = new BN(3);
      var SEVEN = new BN(7);
      var ELEVEN = new BN(11);
      var FOUR = new BN(4);
      var TWELVE = new BN(12);
      var primes = null;

      function _getPrimes() {
        if (primes !== null) return primes;
        var limit = 1048576;
        var res = [];
        res[0] = 2;
        for (var i = 1, k = 3; k < limit; k += 2) {
          var sqrt = Math.ceil(Math.sqrt(k));
          for (var j = 0; j < i && res[j] <= sqrt; j++)
            if (k % res[j] === 0) break;
          if (i !== j && res[j] <= sqrt) continue;
          res[i++] = k
        }
        primes = res;
        return res
      }

      function simpleSieve(p) {
        var primes = _getPrimes();
        for (var i = 0; i < primes.length; i++)
          if (p.modn(primes[i]) === 0) return false;
        return true
      }

      function fermatTest(p) {
        var red = BN.mont(p);
        return TWO.toRed(red).redPow(p.subn(1)).fromRed().cmpn(1) === 0
      }

      function findPrime(bits, gen, crypto) {
        gen = new BN(gen);
        var runs, comp;

        function generateRandom(bits) {
          runs = -1;
          var r = crypto.randomBytes(Math.ceil(bits / 8));
          r[0] |= 192;
          r[r.length - 1] |= 3;
          var rem;
          var out = new BN(r);
          if (!gen.cmp(TWO)) {
            while (out.mod(TWENTYFOUR).cmp(ELEVEN)) {
              out.iadd(FOUR)
            }
            comp = {
              major: [TWENTYFOUR],
              minor: [TWELVE]
            }
          } else if (!gen.cmp(FIVE)) {
            rem = out.mod(TEN);
            while (rem.cmp(THREE)) {
              out.iadd(FOUR);
              rem = out.mod(TEN)
            }
            comp = {
              major: [FOUR, SIXTEEN],
              minor: [TWO, EIGHT]
            }
          } else {
            comp = {
              major: [FOUR],
              minor: [TWO]
            }
          }
          return out
        }
        var num = generateRandom(bits);
        var n2 = num.shrn(1);
        while (true) {
          if (num.bitLength() > bits) {
            num = generateRandom(bits);
            n2 = num.shrn(1)
          }
          runs++;
          if (simpleSieve(n2) && fermatTest(n2) && millerRabin.test(n2) && simpleSieve(num) && fermatTest(num) && millerRabin.test(num)) {
            return num
          }
          num.iadd(comp.major[runs % comp.major.length]);
          n2.iadd(comp.minor[runs % comp.minor.length])
        }
      }
    }, {
      "bn.js": 138,
      "miller-rabin": 139
    }],
    137: [function(require, module, exports) {
      (function(Buffer) {
        var primes = require("./primes.json");
        var DH = require("./dh");
        var generatePrime = require("./generatePrime");
        module.exports = function(crypto, exports) {
          exports.DiffieHellmanGroup = exports.createDiffieHellmanGroup = exports.getDiffieHellman = DiffieHellmanGroup;

          function DiffieHellmanGroup(mod) {
            return new DH(new Buffer(primes[mod].prime, "hex"), new Buffer(primes[mod].gen, "hex"), crypto)
          }
          exports.createDiffieHellman = exports.DiffieHellman = DiffieHellman;

          function DiffieHellman(prime, enc, generator, genc) {
            if (Buffer.isBuffer(enc) || typeof enc === "string" && ["hex", "binary", "base64"].indexOf(enc) === -1) {
              genc = generator;
              generator = enc;
              enc = void 0
            }
            enc = enc || "binary";
            genc = genc || "binary";
            generator = generator || new Buffer([2]);
            if (!Buffer.isBuffer(generator)) {
              generator = new Buffer(generator, genc)
            }
            if (typeof prime === "number") {
              return new DH(generatePrime(prime, generator, crypto), generator, crypto, true)
            }
            if (!Buffer.isBuffer(prime)) {
              prime = new Buffer(prime, enc)
            }
            return new DH(prime, generator, crypto, true)
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./dh": 135,
      "./generatePrime": 136,
      "./primes.json": 141,
      buffer: 7
    }],
    138: [function(require, module, exports) {
      module.exports = require(76)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/bn.js/lib/bn.js": 76
    }],
    139: [function(require, module, exports) {
      var bn = require("bn.js");
      var brorand = require("brorand");

      function MillerRabin(rand) {
        this.rand = rand || new brorand.Rand
      }
      module.exports = MillerRabin;
      MillerRabin.create = function create(rand) {
        return new MillerRabin(rand)
      };
      MillerRabin.prototype._rand = function _rand(n) {
        var len = n.bitLength();
        var buf = this.rand.generate(Math.ceil(len / 8));
        buf[0] |= 3;
        var mask = len & 7;
        if (mask !== 0) buf[buf.length - 1] >>= 7 - mask;
        return new bn(buf)
      };
      MillerRabin.prototype.test = function test(n, k, cb) {
        var len = n.bitLength();
        var red = bn.mont(n);
        var rone = new bn(1).toRed(red);
        if (!k) k = Math.max(1, len / 48 | 0);
        var n1 = n.subn(1);
        var n2 = n1.subn(1);
        for (var s = 0; !n1.testn(s); s++) {}
        var d = n.shrn(s);
        var rn1 = n1.toRed(red);
        var prime = true;
        for (; k > 0; k--) {
          var a = this._rand(n2);
          if (cb) cb(a);
          var x = a.toRed(red).redPow(d);
          if (x.cmp(rone) === 0 || x.cmp(rn1) === 0) continue;
          for (var i = 1; i < s; i++) {
            x = x.redSqr();
            if (x.cmp(rone) === 0) return false;
            if (x.cmp(rn1) === 0) break
          }
          if (i === s) return false
        }
        return prime
      };
      MillerRabin.prototype.getDivisor = function getDivisor(n, k) {
        var len = n.bitLength();
        var red = bn.mont(n);
        var rone = new bn(1).toRed(red);
        if (!k) k = Math.max(1, len / 48 | 0);
        var n1 = n.subn(1);
        var n2 = n1.subn(1);
        for (var s = 0; !n1.testn(s); s++) {}
        var d = n.shrn(s);
        var rn1 = n1.toRed(red);
        var prime = true;
        for (; k > 0; k--) {
          var a = this._rand(n2);
          var g = n.gcd(a);
          if (g.cmpn(1) !== 0) return g;
          var x = a.toRed(red).redPow(d);
          if (x.cmp(rone) === 0 || x.cmp(rn1) === 0) continue;
          for (var i = 1; i < s; i++) {
            x = x.redSqr();
            if (x.cmp(rone) === 0) return x.fromRed().subn(1).gcd(n);
            if (x.cmp(rn1) === 0) break
          }
          if (i === s) {
            x = x.redSqr();
            return x.fromRed().subn(1).gcd(n)
          }
        }
        return prime
      }
    }, {
      "bn.js": 138,
      brorand: 140
    }],
    140: [function(require, module, exports) {
      module.exports = require(89)
    }, {
      "/Users/pollas_p/Desktop/bitcoinjs-lib/node_modules/crypto-browserify/node_modules/browserify-sign/node_modules/elliptic/node_modules/brorand/index.js": 89
    }],
    141: [function(require, module, exports) {
      module.exports = {
        modp1: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a63a3620ffffffffffffffff"
        },
        modp2: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece65381ffffffffffffffff"
        },
        modp5: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c354e4abc9804f1746c08ca237327ffffffffffffffff"
        },
        modp14: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c354e4abc9804f1746c08ca18217c32905e462e36ce3be39e772c180e86039b2783a2ec07a28fb5c55df06f4c52c9de2bcbf6955817183995497cea956ae515d2261898fa051015728e5a8aacaa68ffffffffffffffff"
        },
        modp15: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c354e4abc9804f1746c08ca18217c32905e462e36ce3be39e772c180e86039b2783a2ec07a28fb5c55df06f4c52c9de2bcbf6955817183995497cea956ae515d2261898fa051015728e5a8aaac42dad33170d04507a33a85521abdf1cba64ecfb850458dbef0a8aea71575d060c7db3970f85a6e1e4c7abf5ae8cdb0933d71e8c94e04a25619dcee3d2261ad2ee6bf12ffa06d98a0864d87602733ec86a64521f2b18177b200cbbe117577a615d6c770988c0bad946e208e24fa074e5ab3143db5bfce0fd108e4b82d120a93ad2caffffffffffffffff"
        },
        modp16: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c354e4abc9804f1746c08ca18217c32905e462e36ce3be39e772c180e86039b2783a2ec07a28fb5c55df06f4c52c9de2bcbf6955817183995497cea956ae515d2261898fa051015728e5a8aaac42dad33170d04507a33a85521abdf1cba64ecfb850458dbef0a8aea71575d060c7db3970f85a6e1e4c7abf5ae8cdb0933d71e8c94e04a25619dcee3d2261ad2ee6bf12ffa06d98a0864d87602733ec86a64521f2b18177b200cbbe117577a615d6c770988c0bad946e208e24fa074e5ab3143db5bfce0fd108e4b82d120a92108011a723c12a787e6d788719a10bdba5b2699c327186af4e23c1a946834b6150bda2583e9ca2ad44ce8dbbbc2db04de8ef92e8efc141fbecaa6287c59474e6bc05d99b2964fa090c3a2233ba186515be7ed1f612970cee2d7afb81bdd762170481cd0069127d5b05aa993b4ea988d8fddc186ffb7dc90a6c08f4df435c934063199ffffffffffffffff"
        },
        modp17: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c354e4abc9804f1746c08ca18217c32905e462e36ce3be39e772c180e86039b2783a2ec07a28fb5c55df06f4c52c9de2bcbf6955817183995497cea956ae515d2261898fa051015728e5a8aaac42dad33170d04507a33a85521abdf1cba64ecfb850458dbef0a8aea71575d060c7db3970f85a6e1e4c7abf5ae8cdb0933d71e8c94e04a25619dcee3d2261ad2ee6bf12ffa06d98a0864d87602733ec86a64521f2b18177b200cbbe117577a615d6c770988c0bad946e208e24fa074e5ab3143db5bfce0fd108e4b82d120a92108011a723c12a787e6d788719a10bdba5b2699c327186af4e23c1a946834b6150bda2583e9ca2ad44ce8dbbbc2db04de8ef92e8efc141fbecaa6287c59474e6bc05d99b2964fa090c3a2233ba186515be7ed1f612970cee2d7afb81bdd762170481cd0069127d5b05aa993b4ea988d8fddc186ffb7dc90a6c08f4df435c93402849236c3fab4d27c7026c1d4dcb2602646dec9751e763dba37bdf8ff9406ad9e530ee5db382f413001aeb06a53ed9027d831179727b0865a8918da3edbebcf9b14ed44ce6cbaced4bb1bdb7f1447e6cc254b332051512bd7af426fb8f401378cd2bf5983ca01c64b92ecf032ea15d1721d03f482d7ce6e74fef6d55e702f46980c82b5a84031900b1c9e59e7c97fbec7e8f323a97a7e36cc88be0f1d45b7ff585ac54bd407b22b4154aacc8f6d7ebf48e1d814cc5ed20f8037e0a79715eef29be32806a1d58bb7c5da76f550aa3d8a1fbff0eb19ccb1a313d55cda56c9ec2ef29632387fe8d76e3c0468043e8f663f4860ee12bf2d5b0b7474d6e694f91e6dcc4024ffffffffffffffff"
        },
        modp18: {
          gen: "02",
          prime: "ffffffffffffffffc90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b139b22514a08798e3404ddef9519b3cd3a431b302b0a6df25f14374fe1356d6d51c245e485b576625e7ec6f44c42e9a637ed6b0bff5cb6f406b7edee386bfb5a899fa5ae9f24117c4b1fe649286651ece45b3dc2007cb8a163bf0598da48361c55d39a69163fa8fd24cf5f83655d23dca3ad961c62f356208552bb9ed529077096966d670c354e4abc9804f1746c08ca18217c32905e462e36ce3be39e772c180e86039b2783a2ec07a28fb5c55df06f4c52c9de2bcbf6955817183995497cea956ae515d2261898fa051015728e5a8aaac42dad33170d04507a33a85521abdf1cba64ecfb850458dbef0a8aea71575d060c7db3970f85a6e1e4c7abf5ae8cdb0933d71e8c94e04a25619dcee3d2261ad2ee6bf12ffa06d98a0864d87602733ec86a64521f2b18177b200cbbe117577a615d6c770988c0bad946e208e24fa074e5ab3143db5bfce0fd108e4b82d120a92108011a723c12a787e6d788719a10bdba5b2699c327186af4e23c1a946834b6150bda2583e9ca2ad44ce8dbbbc2db04de8ef92e8efc141fbecaa6287c59474e6bc05d99b2964fa090c3a2233ba186515be7ed1f612970cee2d7afb81bdd762170481cd0069127d5b05aa993b4ea988d8fddc186ffb7dc90a6c08f4df435c93402849236c3fab4d27c7026c1d4dcb2602646dec9751e763dba37bdf8ff9406ad9e530ee5db382f413001aeb06a53ed9027d831179727b0865a8918da3edbebcf9b14ed44ce6cbaced4bb1bdb7f1447e6cc254b332051512bd7af426fb8f401378cd2bf5983ca01c64b92ecf032ea15d1721d03f482d7ce6e74fef6d55e702f46980c82b5a84031900b1c9e59e7c97fbec7e8f323a97a7e36cc88be0f1d45b7ff585ac54bd407b22b4154aacc8f6d7ebf48e1d814cc5ed20f8037e0a79715eef29be32806a1d58bb7c5da76f550aa3d8a1fbff0eb19ccb1a313d55cda56c9ec2ef29632387fe8d76e3c0468043e8f663f4860ee12bf2d5b0b7474d6e694f91e6dbe115974a3926f12fee5e438777cb6a932df8cd8bec4d073b931ba3bc832b68d9dd300741fa7bf8afc47ed2576f6936ba424663aab639c5ae4f5683423b4742bf1c978238f16cbe39d652de3fdb8befc848ad922222e04a4037c0713eb57a81a23f0c73473fc646cea306b4bcbc8862f8385ddfa9d4b7fa2c087e879683303ed5bdd3a062b3cf5b3a278a66d2a13f83f44f82ddf310ee074ab6a364597e899a0255dc164f31cc50846851df9ab48195ded7ea1b1d510bd7ee74d73faf36bc31ecfa268359046f4eb879f924009438b481c6cd7889a002ed5ee382bc9190da6fc026e479558e4475677e9aa9e3050e2765694dfc81f56e880b96e7160c980dd98edd3dfffffffffffffffff"
        }
      }
    }, {}],
    142: [function(require, module, exports) {
      (function(Buffer) {
        module.exports = function(crypto) {
          function pbkdf2(password, salt, iterations, keylen, digest, callback) {
            if ("function" === typeof digest) {
              callback = digest;
              digest = undefined
            }
            if ("function" !== typeof callback) throw new Error("No callback provided to pbkdf2");
            setTimeout(function() {
              var result;
              try {
                result = pbkdf2Sync(password, salt, iterations, keylen, digest)
              } catch (e) {
                return callback(e)
              }
              callback(undefined, result)
            })
          }

          function pbkdf2Sync(password, salt, iterations, keylen, digest) {
            if ("number" !== typeof iterations) throw new TypeError("Iterations not a number");
            if (iterations < 0) throw new TypeError("Bad iterations");
            if ("number" !== typeof keylen) throw new TypeError("Key length not a number");
            if (keylen < 0) throw new TypeError("Bad key length");
            digest = digest || "sha1";
            if (!Buffer.isBuffer(password)) password = new Buffer(password);
            if (!Buffer.isBuffer(salt)) salt = new Buffer(salt);
            var hLen, l = 1,
                r, T;
            var DK = new Buffer(keylen);
            var block1 = new Buffer(salt.length + 4);
            salt.copy(block1, 0, 0, salt.length);
            for (var i = 1; i <= l; i++) {
              block1.writeUInt32BE(i, salt.length);
              var U = crypto.createHmac(digest, password).update(block1).digest();
              if (!hLen) {
                hLen = U.length;
                T = new Buffer(hLen);
                l = Math.ceil(keylen / hLen);
                r = keylen - (l - 1) * hLen;
                if (keylen > (Math.pow(2, 32) - 1) * hLen) throw new TypeError("keylen exceeds maximum length")
              }
              U.copy(T, 0, 0, hLen);
              for (var j = 1; j < iterations; j++) {
                U = crypto.createHmac(digest, password).update(U).digest();
                for (var k = 0; k < hLen; k++) {
                  T[k] ^= U[k]
                }
              }
              var destPos = (i - 1) * hLen;
              var len = i == l ? r : hLen;
              T.copy(DK, destPos, 0, len)
            }
            return DK
          }
          return {
            pbkdf2: pbkdf2,
            pbkdf2Sync: pbkdf2Sync
          }
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    143: [function(require, module, exports) {
      (function(Buffer) {
        module.exports = ripemd160;
        var zl = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8, 3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12, 1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2, 4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13];
        var zr = [5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12, 6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2, 15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13, 8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14, 12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11];
        var sl = [11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8, 7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12, 11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5, 11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12, 9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6];
        var sr = [8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6, 9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11, 9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5, 15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8, 8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11];
        var hl = [0, 1518500249, 1859775393, 2400959708, 2840853838];
        var hr = [1352829926, 1548603684, 1836072691, 2053994217, 0];
        var bytesToWords = function(bytes) {
          var words = [];
          for (var i = 0, b = 0; i < bytes.length; i++, b += 8) {
            words[b >>> 5] |= bytes[i] << 24 - b % 32
          }
          return words
        };
        var wordsToBytes = function(words) {
          var bytes = [];
          for (var b = 0; b < words.length * 32; b += 8) {
            bytes.push(words[b >>> 5] >>> 24 - b % 32 & 255)
          }
          return bytes
        };
        var processBlock = function(H, M, offset) {
          for (var i = 0; i < 16; i++) {
            var offset_i = offset + i;
            var M_offset_i = M[offset_i];
            M[offset_i] = (M_offset_i << 8 | M_offset_i >>> 24) & 16711935 | (M_offset_i << 24 | M_offset_i >>> 8) & 4278255360
          }
          var al, bl, cl, dl, el;
          var ar, br, cr, dr, er;
          ar = al = H[0];
          br = bl = H[1];
          cr = cl = H[2];
          dr = dl = H[3];
          er = el = H[4];
          var t;
          for (var i = 0; i < 80; i += 1) {
            t = al + M[offset + zl[i]] | 0;
            if (i < 16) {
              t += f1(bl, cl, dl) + hl[0]
            } else if (i < 32) {
              t += f2(bl, cl, dl) + hl[1]
            } else if (i < 48) {
              t += f3(bl, cl, dl) + hl[2]
            } else if (i < 64) {
              t += f4(bl, cl, dl) + hl[3]
            } else {
              t += f5(bl, cl, dl) + hl[4]
            }
            t = t | 0;
            t = rotl(t, sl[i]);
            t = t + el | 0;
            al = el;
            el = dl;
            dl = rotl(cl, 10);
            cl = bl;
            bl = t;
            t = ar + M[offset + zr[i]] | 0;
            if (i < 16) {
              t += f5(br, cr, dr) + hr[0]
            } else if (i < 32) {
              t += f4(br, cr, dr) + hr[1]
            } else if (i < 48) {
              t += f3(br, cr, dr) + hr[2]
            } else if (i < 64) {
              t += f2(br, cr, dr) + hr[3]
            } else {
              t += f1(br, cr, dr) + hr[4]
            }
            t = t | 0;
            t = rotl(t, sr[i]);
            t = t + er | 0;
            ar = er;
            er = dr;
            dr = rotl(cr, 10);
            cr = br;
            br = t
          }
          t = H[1] + cl + dr | 0;
          H[1] = H[2] + dl + er | 0;
          H[2] = H[3] + el + ar | 0;
          H[3] = H[4] + al + br | 0;
          H[4] = H[0] + bl + cr | 0;
          H[0] = t
        };

        function f1(x, y, z) {
          return x ^ y ^ z
        }

        function f2(x, y, z) {
          return x & y | ~x & z
        }

        function f3(x, y, z) {
          return (x | ~y) ^ z
        }

        function f4(x, y, z) {
          return x & z | y & ~z
        }

        function f5(x, y, z) {
          return x ^ (y | ~z)
        }

        function rotl(x, n) {
          return x << n | x >>> 32 - n
        }

        function ripemd160(message) {
          var H = [1732584193, 4023233417, 2562383102, 271733878, 3285377520];
          if (typeof message == "string") message = new Buffer(message, "utf8");
          var m = bytesToWords(message);
          var nBitsLeft = message.length * 8;
          var nBitsTotal = message.length * 8;
          m[nBitsLeft >>> 5] |= 128 << 24 - nBitsLeft % 32;
          m[(nBitsLeft + 64 >>> 9 << 4) + 14] = (nBitsTotal << 8 | nBitsTotal >>> 24) & 16711935 | (nBitsTotal << 24 | nBitsTotal >>> 8) & 4278255360;
          for (var i = 0; i < m.length; i += 16) {
            processBlock(H, m, i)
          }
          for (var i = 0; i < 5; i++) {
            var H_i = H[i];
            H[i] = (H_i << 8 | H_i >>> 24) & 16711935 | (H_i << 24 | H_i >>> 8) & 4278255360
          }
          var digestbytes = wordsToBytes(H);
          return new Buffer(digestbytes)
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    144: [function(require, module, exports) {
      (function(Buffer) {
        function Hash(blockSize, finalSize) {
          this._block = new Buffer(blockSize);
          this._finalSize = finalSize;
          this._blockSize = blockSize;
          this._len = 0;
          this._s = 0
        }
        Hash.prototype.init = function() {
          this._s = 0;
          this._len = 0
        };
        Hash.prototype.update = function(data, enc) {
          if ("string" === typeof data) {
            enc = enc || "utf8";
            data = new Buffer(data, enc)
          }
          var l = this._len += data.length;
          var s = this._s = this._s || 0;
          var f = 0;
          var buffer = this._block;
          while (s < l) {
            var t = Math.min(data.length, f + this._blockSize - s % this._blockSize);
            var ch = t - f;
            for (var i = 0; i < ch; i++) {
              buffer[s % this._blockSize + i] = data[i + f]
            }
            s += ch;
            f += ch;
            if (s % this._blockSize === 0) {
              this._update(buffer)
            }
          }
          this._s = s;
          return this
        };
        Hash.prototype.digest = function(enc) {
          var l = this._len * 8;
          this._block[this._len % this._blockSize] = 128;
          this._block.fill(0, this._len % this._blockSize + 1);
          if (l % (this._blockSize * 8) >= this._finalSize * 8) {
            this._update(this._block);
            this._block.fill(0)
          }
          this._block.writeInt32BE(l, this._blockSize - 4);
          var hash = this._update(this._block) || this._hash();
          return enc ? hash.toString(enc) : hash
        };
        Hash.prototype._update = function() {
          throw new Error("_update must be implemented by subclass")
        };
        module.exports = Hash
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    145: [function(require, module, exports) {
      var exports = module.exports = function(alg) {
        var Alg = exports[alg.toLowerCase()];
        if (!Alg) throw new Error(alg + " is not supported (we accept pull requests)");
        return new Alg
      };
      exports.sha1 = require("./sha1");
      exports.sha224 = require("./sha224");
      exports.sha256 = require("./sha256");
      exports.sha384 = require("./sha384");
      exports.sha512 = require("./sha512")
    }, {
      "./sha1": 146,
      "./sha224": 147,
      "./sha256": 148,
      "./sha384": 149,
      "./sha512": 150
    }],
    146: [function(require, module, exports) {
      (function(Buffer) {
        var inherits = require("util").inherits;
        var Hash = require("./hash");
        var A = 0 | 0;
        var B = 4 | 0;
        var C = 8 | 0;
        var D = 12 | 0;
        var E = 16 | 0;
        var W = new(typeof Int32Array === "undefined" ? Array : Int32Array)(80);
        var POOL = [];

        function Sha1() {
          if (POOL.length) return POOL.pop().init();
          if (!(this instanceof Sha1)) return new Sha1;
          this._w = W;
          Hash.call(this, 16 * 4, 14 * 4);
          this._h = null;
          this.init()
        }
        inherits(Sha1, Hash);
        Sha1.prototype.init = function() {
          this._a = 1732584193;
          this._b = 4023233417;
          this._c = 2562383102;
          this._d = 271733878;
          this._e = 3285377520;
          Hash.prototype.init.call(this);
          return this
        };
        Sha1.prototype._POOL = POOL;
        Sha1.prototype._update = function(X) {
          var a, b, c, d, e, _a, _b, _c, _d, _e;
          a = _a = this._a;
          b = _b = this._b;
          c = _c = this._c;
          d = _d = this._d;
          e = _e = this._e;
          var w = this._w;
          for (var j = 0; j < 80; j++) {
            var W = w[j] = j < 16 ? X.readInt32BE(j * 4) : rol(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
            var t = add(add(rol(a, 5), sha1_ft(j, b, c, d)), add(add(e, W), sha1_kt(j)));
            e = d;
            d = c;
            c = rol(b, 30);
            b = a;
            a = t
          }
          this._a = add(a, _a);
          this._b = add(b, _b);
          this._c = add(c, _c);
          this._d = add(d, _d);
          this._e = add(e, _e)
        };
        Sha1.prototype._hash = function() {
          if (POOL.length < 100) POOL.push(this);
          var H = new Buffer(20);
          H.writeInt32BE(this._a | 0, A);
          H.writeInt32BE(this._b | 0, B);
          H.writeInt32BE(this._c | 0, C);
          H.writeInt32BE(this._d | 0, D);
          H.writeInt32BE(this._e | 0, E);
          return H
        };

        function sha1_ft(t, b, c, d) {
          if (t < 20) return b & c | ~b & d;
          if (t < 40) return b ^ c ^ d;
          if (t < 60) return b & c | b & d | c & d;
          return b ^ c ^ d
        }

        function sha1_kt(t) {
          return t < 20 ? 1518500249 : t < 40 ? 1859775393 : t < 60 ? -1894007588 : -899497514
        }

        function add(x, y) {
          return x + y | 0
        }

        function rol(num, cnt) {
          return num << cnt | num >>> 32 - cnt
        }
        module.exports = Sha1
      }).call(this, require("buffer").Buffer)
    }, {
      "./hash": 144,
      buffer: 7,
      util: 29
    }],
    147: [function(require, module, exports) {
      (function(Buffer) {
        var inherits = require("util").inherits;
        var SHA256 = require("./sha256");
        var Hash = require("./hash");
        var W = new Array(64);

        function Sha224() {
          this.init();
          this._w = W;
          Hash.call(this, 16 * 4, 14 * 4)
        }
        inherits(Sha224, SHA256);
        Sha224.prototype.init = function() {
          this._a = 3238371032 | 0;
          this._b = 914150663 | 0;
          this._c = 812702999 | 0;
          this._d = 4144912697 | 0;
          this._e = 4290775857 | 0;
          this._f = 1750603025 | 0;
          this._g = 1694076839 | 0;
          this._h = 3204075428 | 0;
          this._len = this._s = 0;
          return this
        };
        Sha224.prototype._hash = function() {
          var H = new Buffer(28);
          H.writeInt32BE(this._a, 0);
          H.writeInt32BE(this._b, 4);
          H.writeInt32BE(this._c, 8);
          H.writeInt32BE(this._d, 12);
          H.writeInt32BE(this._e, 16);
          H.writeInt32BE(this._f, 20);
          H.writeInt32BE(this._g, 24);
          return H
        };
        module.exports = Sha224
      }).call(this, require("buffer").Buffer)
    }, {
      "./hash": 144,
      "./sha256": 148,
      buffer: 7,
      util: 29
    }],
    148: [function(require, module, exports) {
      (function(Buffer) {
        var inherits = require("util").inherits;
        var Hash = require("./hash");
        var K = [1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221, 3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580, 3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986, 2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895, 666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037, 2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344, 430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779, 1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298];
        var W = new Array(64);

        function Sha256() {
          this.init();
          this._w = W;
          Hash.call(this, 16 * 4, 14 * 4)
        }
        inherits(Sha256, Hash);
        Sha256.prototype.init = function() {
          this._a = 1779033703 | 0;
          this._b = 3144134277 | 0;
          this._c = 1013904242 | 0;
          this._d = 2773480762 | 0;
          this._e = 1359893119 | 0;
          this._f = 2600822924 | 0;
          this._g = 528734635 | 0;
          this._h = 1541459225 | 0;
          this._len = this._s = 0;
          return this
        };

        function S(X, n) {
          return X >>> n | X << 32 - n
        }

        function R(X, n) {
          return X >>> n
        }

        function Ch(x, y, z) {
          return x & y ^ ~x & z
        }

        function Maj(x, y, z) {
          return x & y ^ x & z ^ y & z
        }

        function Sigma0256(x) {
          return S(x, 2) ^ S(x, 13) ^ S(x, 22)
        }

        function Sigma1256(x) {
          return S(x, 6) ^ S(x, 11) ^ S(x, 25)
        }

        function Gamma0256(x) {
          return S(x, 7) ^ S(x, 18) ^ R(x, 3)
        }

        function Gamma1256(x) {
          return S(x, 17) ^ S(x, 19) ^ R(x, 10)
        }
        Sha256.prototype._update = function(M) {
          var W = this._w;
          var a, b, c, d, e, f, g, h;
          var T1, T2;
          a = this._a | 0;
          b = this._b | 0;
          c = this._c | 0;
          d = this._d | 0;
          e = this._e | 0;
          f = this._f | 0;
          g = this._g | 0;
          h = this._h | 0;
          for (var j = 0; j < 64; j++) {
            var w = W[j] = j < 16 ? M.readInt32BE(j * 4) : Gamma1256(W[j - 2]) + W[j - 7] + Gamma0256(W[j - 15]) + W[j - 16];
            T1 = h + Sigma1256(e) + Ch(e, f, g) + K[j] + w;
            T2 = Sigma0256(a) + Maj(a, b, c);
            h = g;
            g = f;
            f = e;
            e = d + T1;
            d = c;
            c = b;
            b = a;
            a = T1 + T2
          }
          this._a = a + this._a | 0;
          this._b = b + this._b | 0;
          this._c = c + this._c | 0;
          this._d = d + this._d | 0;
          this._e = e + this._e | 0;
          this._f = f + this._f | 0;
          this._g = g + this._g | 0;
          this._h = h + this._h | 0
        };
        Sha256.prototype._hash = function() {
          var H = new Buffer(32);
          H.writeInt32BE(this._a, 0);
          H.writeInt32BE(this._b, 4);
          H.writeInt32BE(this._c, 8);
          H.writeInt32BE(this._d, 12);
          H.writeInt32BE(this._e, 16);
          H.writeInt32BE(this._f, 20);
          H.writeInt32BE(this._g, 24);
          H.writeInt32BE(this._h, 28);
          return H
        };
        module.exports = Sha256
      }).call(this, require("buffer").Buffer)
    }, {
      "./hash": 144,
      buffer: 7,
      util: 29
    }],
    149: [function(require, module, exports) {
      (function(Buffer) {
        var inherits = require("util").inherits;
        var SHA512 = require("./sha512");
        var Hash = require("./hash");
        var W = new Array(160);

        function Sha384() {
          this.init();
          this._w = W;
          Hash.call(this, 128, 112)
        }
        inherits(Sha384, SHA512);
        Sha384.prototype.init = function() {
          this._a = 3418070365 | 0;
          this._b = 1654270250 | 0;
          this._c = 2438529370 | 0;
          this._d = 355462360 | 0;
          this._e = 1731405415 | 0;
          this._f = 2394180231 | 0;
          this._g = 3675008525 | 0;
          this._h = 1203062813 | 0;
          this._al = 3238371032 | 0;
          this._bl = 914150663 | 0;
          this._cl = 812702999 | 0;
          this._dl = 4144912697 | 0;
          this._el = 4290775857 | 0;
          this._fl = 1750603025 | 0;
          this._gl = 1694076839 | 0;
          this._hl = 3204075428 | 0;
          this._len = this._s = 0;
          return this
        };
        Sha384.prototype._hash = function() {
          var H = new Buffer(48);

          function writeInt64BE(h, l, offset) {
            H.writeInt32BE(h, offset);
            H.writeInt32BE(l, offset + 4)
          }
          writeInt64BE(this._a, this._al, 0);
          writeInt64BE(this._b, this._bl, 8);
          writeInt64BE(this._c, this._cl, 16);
          writeInt64BE(this._d, this._dl, 24);
          writeInt64BE(this._e, this._el, 32);
          writeInt64BE(this._f, this._fl, 40);
          return H
        };
        module.exports = Sha384
      }).call(this, require("buffer").Buffer)
    }, {
      "./hash": 144,
      "./sha512": 150,
      buffer: 7,
      util: 29
    }],
    150: [function(require, module, exports) {
      (function(Buffer) {
        var inherits = require("util").inherits;
        var Hash = require("./hash");
        var K = [1116352408, 3609767458, 1899447441, 602891725, 3049323471, 3964484399, 3921009573, 2173295548, 961987163, 4081628472, 1508970993, 3053834265, 2453635748, 2937671579, 2870763221, 3664609560, 3624381080, 2734883394, 310598401, 1164996542, 607225278, 1323610764, 1426881987, 3590304994, 1925078388, 4068182383, 2162078206, 991336113, 2614888103, 633803317, 3248222580, 3479774868, 3835390401, 2666613458, 4022224774, 944711139, 264347078, 2341262773, 604807628, 2007800933, 770255983, 1495990901, 1249150122, 1856431235, 1555081692, 3175218132, 1996064986, 2198950837, 2554220882, 3999719339, 2821834349, 766784016, 2952996808, 2566594879, 3210313671, 3203337956, 3336571891, 1034457026, 3584528711, 2466948901, 113926993, 3758326383, 338241895, 168717936, 666307205, 1188179964, 773529912, 1546045734, 1294757372, 1522805485, 1396182291, 2643833823, 1695183700, 2343527390, 1986661051, 1014477480, 2177026350, 1206759142, 2456956037, 344077627, 2730485921, 1290863460, 2820302411, 3158454273, 3259730800, 3505952657, 3345764771, 106217008, 3516065817, 3606008344, 3600352804, 1432725776, 4094571909, 1467031594, 275423344, 851169720, 430227734, 3100823752, 506948616, 1363258195, 659060556, 3750685593, 883997877, 3785050280, 958139571, 3318307427, 1322822218, 3812723403, 1537002063, 2003034995, 1747873779, 3602036899, 1955562222, 1575990012, 2024104815, 1125592928, 2227730452, 2716904306, 2361852424, 442776044, 2428436474, 593698344, 2756734187, 3733110249, 3204031479, 2999351573, 3329325298, 3815920427, 3391569614, 3928383900, 3515267271, 566280711, 3940187606, 3454069534, 4118630271, 4000239992, 116418474, 1914138554, 174292421, 2731055270, 289380356, 3203993006, 460393269, 320620315, 685471733, 587496836, 852142971, 1086792851, 1017036298, 365543100, 1126000580, 2618297676, 1288033470, 3409855158, 1501505948, 4234509866, 1607167915, 987167468, 1816402316, 1246189591];
        var W = new Array(160);

        function Sha512() {
          this.init();
          this._w = W;
          Hash.call(this, 128, 112)
        }
        inherits(Sha512, Hash);
        Sha512.prototype.init = function() {
          this._a = 1779033703 | 0;
          this._b = 3144134277 | 0;
          this._c = 1013904242 | 0;
          this._d = 2773480762 | 0;
          this._e = 1359893119 | 0;
          this._f = 2600822924 | 0;
          this._g = 528734635 | 0;
          this._h = 1541459225 | 0;
          this._al = 4089235720 | 0;
          this._bl = 2227873595 | 0;
          this._cl = 4271175723 | 0;
          this._dl = 1595750129 | 0;
          this._el = 2917565137 | 0;
          this._fl = 725511199 | 0;
          this._gl = 4215389547 | 0;
          this._hl = 327033209 | 0;
          this._len = this._s = 0;
          return this
        };

        function S(X, Xl, n) {
          return X >>> n | Xl << 32 - n
        }

        function Ch(x, y, z) {
          return x & y ^ ~x & z
        }

        function Maj(x, y, z) {
          return x & y ^ x & z ^ y & z
        }
        Sha512.prototype._update = function(M) {
          var W = this._w;
          var a, b, c, d, e, f, g, h;
          var al, bl, cl, dl, el, fl, gl, hl;
          a = this._a | 0;
          b = this._b | 0;
          c = this._c | 0;
          d = this._d | 0;
          e = this._e | 0;
          f = this._f | 0;
          g = this._g | 0;
          h = this._h | 0;
          al = this._al | 0;
          bl = this._bl | 0;
          cl = this._cl | 0;
          dl = this._dl | 0;
          el = this._el | 0;
          fl = this._fl | 0;
          gl = this._gl | 0;
          hl = this._hl | 0;
          for (var i = 0; i < 80; i++) {
            var j = i * 2;
            var Wi, Wil;
            if (i < 16) {
              Wi = W[j] = M.readInt32BE(j * 4);
              Wil = W[j + 1] = M.readInt32BE(j * 4 + 4)
            } else {
              var x = W[j - 15 * 2];
              var xl = W[j - 15 * 2 + 1];
              var gamma0 = S(x, xl, 1) ^ S(x, xl, 8) ^ x >>> 7;
              var gamma0l = S(xl, x, 1) ^ S(xl, x, 8) ^ S(xl, x, 7);
              x = W[j - 2 * 2];
              xl = W[j - 2 * 2 + 1];
              var gamma1 = S(x, xl, 19) ^ S(xl, x, 29) ^ x >>> 6;
              var gamma1l = S(xl, x, 19) ^ S(x, xl, 29) ^ S(xl, x, 6);
              var Wi7 = W[j - 7 * 2];
              var Wi7l = W[j - 7 * 2 + 1];
              var Wi16 = W[j - 16 * 2];
              var Wi16l = W[j - 16 * 2 + 1];
              Wil = gamma0l + Wi7l;
              Wi = gamma0 + Wi7 + (Wil >>> 0 < gamma0l >>> 0 ? 1 : 0);
              Wil = Wil + gamma1l;
              Wi = Wi + gamma1 + (Wil >>> 0 < gamma1l >>> 0 ? 1 : 0);
              Wil = Wil + Wi16l;
              Wi = Wi + Wi16 + (Wil >>> 0 < Wi16l >>> 0 ? 1 : 0);
              W[j] = Wi;
              W[j + 1] = Wil
            }
            var maj = Maj(a, b, c);
            var majl = Maj(al, bl, cl);
            var sigma0h = S(a, al, 28) ^ S(al, a, 2) ^ S(al, a, 7);
            var sigma0l = S(al, a, 28) ^ S(a, al, 2) ^ S(a, al, 7);
            var sigma1h = S(e, el, 14) ^ S(e, el, 18) ^ S(el, e, 9);
            var sigma1l = S(el, e, 14) ^ S(el, e, 18) ^ S(e, el, 9);
            var Ki = K[j];
            var Kil = K[j + 1];
            var ch = Ch(e, f, g);
            var chl = Ch(el, fl, gl);
            var t1l = hl + sigma1l;
            var t1 = h + sigma1h + (t1l >>> 0 < hl >>> 0 ? 1 : 0);
            t1l = t1l + chl;
            t1 = t1 + ch + (t1l >>> 0 < chl >>> 0 ? 1 : 0);
            t1l = t1l + Kil;
            t1 = t1 + Ki + (t1l >>> 0 < Kil >>> 0 ? 1 : 0);
            t1l = t1l + Wil;
            t1 = t1 + Wi + (t1l >>> 0 < Wil >>> 0 ? 1 : 0);
            var t2l = sigma0l + majl;
            var t2 = sigma0h + maj + (t2l >>> 0 < sigma0l >>> 0 ? 1 : 0);
            h = g;
            hl = gl;
            g = f;
            gl = fl;
            f = e;
            fl = el;
            el = dl + t1l | 0;
            e = d + t1 + (el >>> 0 < dl >>> 0 ? 1 : 0) | 0;
            d = c;
            dl = cl;
            c = b;
            cl = bl;
            b = a;
            bl = al;
            al = t1l + t2l | 0;
            a = t1 + t2 + (al >>> 0 < t1l >>> 0 ? 1 : 0) | 0
          }
          this._al = this._al + al | 0;
          this._bl = this._bl + bl | 0;
          this._cl = this._cl + cl | 0;
          this._dl = this._dl + dl | 0;
          this._el = this._el + el | 0;
          this._fl = this._fl + fl | 0;
          this._gl = this._gl + gl | 0;
          this._hl = this._hl + hl | 0;
          this._a = this._a + a + (this._al >>> 0 < al >>> 0 ? 1 : 0) | 0;
          this._b = this._b + b + (this._bl >>> 0 < bl >>> 0 ? 1 : 0) | 0;
          this._c = this._c + c + (this._cl >>> 0 < cl >>> 0 ? 1 : 0) | 0;
          this._d = this._d + d + (this._dl >>> 0 < dl >>> 0 ? 1 : 0) | 0;
          this._e = this._e + e + (this._el >>> 0 < el >>> 0 ? 1 : 0) | 0;
          this._f = this._f + f + (this._fl >>> 0 < fl >>> 0 ? 1 : 0) | 0;
          this._g = this._g + g + (this._gl >>> 0 < gl >>> 0 ? 1 : 0) | 0;
          this._h = this._h + h + (this._hl >>> 0 < hl >>> 0 ? 1 : 0) | 0
        };
        Sha512.prototype._hash = function() {
          var H = new Buffer(64);

          function writeInt64BE(h, l, offset) {
            H.writeInt32BE(h, offset);
            H.writeInt32BE(l, offset + 4)
          }
          writeInt64BE(this._a, this._al, 0);
          writeInt64BE(this._b, this._bl, 8);
          writeInt64BE(this._c, this._cl, 16);
          writeInt64BE(this._d, this._dl, 24);
          writeInt64BE(this._e, this._el, 32);
          writeInt64BE(this._f, this._fl, 40);
          writeInt64BE(this._g, this._gl, 48);
          writeInt64BE(this._h, this._hl, 56);
          return H
        };
        module.exports = Sha512
      }).call(this, require("buffer").Buffer)
    }, {
      "./hash": 144,
      buffer: 7,
      util: 29
    }],
    151: [function(require, module, exports) {
      "use strict";
      var pbkdf2Export = require("pbkdf2-compat/pbkdf2");
      module.exports = function(crypto, exports) {
        exports = exports || {};
        var exported = pbkdf2Export(crypto);
        exports.pbkdf2 = exported.pbkdf2;
        exports.pbkdf2Sync = exported.pbkdf2Sync;
        return exports
      }
    }, {
      "pbkdf2-compat/pbkdf2": 142
    }],
    152: [function(require, module, exports) {
      (function(global, Buffer) {
        "use strict";
        (function() {
          var g = ("undefined" === typeof window ? global : window) || {};
          var _crypto = g.crypto || g.msCrypto || require("crypto");
          module.exports = function(size) {
            if (_crypto.getRandomValues) {
              var bytes = new Buffer(size);
              _crypto.getRandomValues(bytes);
              return bytes
            } else if (_crypto.randomBytes) {
              return _crypto.randomBytes(size)
            } else throw new Error("secure random number generation not supported by this browser\n" + "use chrome, FireFox or Internet Explorer 11")
          }
        })()
      }).call(this, typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {}, require("buffer").Buffer)
    }, {
      buffer: 7,
      crypto: 6
    }],
    153: [function(require, module, exports) {
      var assert = require("assert");
      var BigInteger = require("bigi");
      var Point = require("./point");

      function Curve(p, a, b, Gx, Gy, n, h) {
        this.p = p;
        this.a = a;
        this.b = b;
        this.G = Point.fromAffine(this, Gx, Gy);
        this.n = n;
        this.h = h;
        this.infinity = new Point(this, null, null, BigInteger.ZERO);
        this.pOverFour = p.add(BigInteger.ONE).shiftRight(2)
      }
      Curve.prototype.pointFromX = function(isOdd, x) {
        var alpha = x.pow(3).add(this.a.multiply(x)).add(this.b).mod(this.p);
        var beta = alpha.modPow(this.pOverFour, this.p);
        var y = beta;
        if (beta.isEven() ^ !isOdd) {
          y = this.p.subtract(y)
        }
        return Point.fromAffine(this, x, y)
      };
      Curve.prototype.isInfinity = function(Q) {
        if (Q === this.infinity) return true;
        return Q.z.signum() === 0 && Q.y.signum() !== 0
      };
      Curve.prototype.isOnCurve = function(Q) {
        if (this.isInfinity(Q)) return true;
        var x = Q.affineX;
        var y = Q.affineY;
        var a = this.a;
        var b = this.b;
        var p = this.p;
        if (x.signum() < 0 || x.compareTo(p) >= 0) return false;
        if (y.signum() < 0 || y.compareTo(p) >= 0) return false;
        var lhs = y.square().mod(p);
        var rhs = x.pow(3).add(a.multiply(x)).add(b).mod(p);
        return lhs.equals(rhs)
      };
      Curve.prototype.validate = function(Q) {
        assert(!this.isInfinity(Q), "Point is at infinity");
        assert(this.isOnCurve(Q), "Point is not on the curve");
        var nQ = Q.multiply(this.n);
        assert(this.isInfinity(nQ), "Point is not a scalar multiple of G");
        return true
      };
      module.exports = Curve
    }, {
      "./point": 157,
      assert: 5,
      bigi: 3
    }],
    154: [function(require, module, exports) {
      module.exports = {
        secp128r1: {
          p: "fffffffdffffffffffffffffffffffff",
          a: "fffffffdfffffffffffffffffffffffc",
          b: "e87579c11079f43dd824993c2cee5ed3",
          n: "fffffffe0000000075a30d1b9038a115",
          h: "01",
          Gx: "161ff7528b899b2d0c28607ca52c5b86",
          Gy: "cf5ac8395bafeb13c02da292dded7a83"
        },
        secp160k1: {
          p: "fffffffffffffffffffffffffffffffeffffac73",
          a: "00",
          b: "07",
          n: "0100000000000000000001b8fa16dfab9aca16b6b3",
          h: "01",
          Gx: "3b4c382ce37aa192a4019e763036f4f5dd4d7ebb",
          Gy: "938cf935318fdced6bc28286531733c3f03c4fee"
        },
        secp160r1: {
          p: "ffffffffffffffffffffffffffffffff7fffffff",
          a: "ffffffffffffffffffffffffffffffff7ffffffc",
          b: "1c97befc54bd7a8b65acf89f81d4d4adc565fa45",
          n: "0100000000000000000001f4c8f927aed3ca752257",
          h: "01",
          Gx: "4a96b5688ef573284664698968c38bb913cbfc82",
          Gy: "23a628553168947d59dcc912042351377ac5fb32"
        },
        secp192k1: {
          p: "fffffffffffffffffffffffffffffffffffffffeffffee37",
          a: "00",
          b: "03",
          n: "fffffffffffffffffffffffe26f2fc170f69466a74defd8d",
          h: "01",
          Gx: "db4ff10ec057e9ae26b07d0280b7f4341da5d1b1eae06c7d",
          Gy: "9b2f2f6d9c5628a7844163d015be86344082aa88d95e2f9d"
        },
        secp192r1: {
          p: "fffffffffffffffffffffffffffffffeffffffffffffffff",
          a: "fffffffffffffffffffffffffffffffefffffffffffffffc",
          b: "64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1",
          n: "ffffffffffffffffffffffff99def836146bc9b1b4d22831",
          h: "01",
          Gx: "188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012",
          Gy: "07192b95ffc8da78631011ed6b24cdd573f977a11e794811"
        },
        secp256k1: {
          p: "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
          a: "00",
          b: "07",
          n: "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
          h: "01",
          Gx: "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
          Gy: "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"
        },
        secp256r1: {
          p: "ffffffff00000001000000000000000000000000ffffffffffffffffffffffff",
          a: "ffffffff00000001000000000000000000000000fffffffffffffffffffffffc",
          b: "5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b",
          n: "ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551",
          h: "01",
          Gx: "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
          Gy: "4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"
        }
      }
    }, {}],
    155: [function(require, module, exports) {
      var Point = require("./point");
      var Curve = require("./curve");
      var getCurveByName = require("./names");
      module.exports = {
        Curve: Curve,
        Point: Point,
        getCurveByName: getCurveByName
      }
    }, {
      "./curve": 153,
      "./names": 156,
      "./point": 157
    }],
    156: [function(require, module, exports) {
      var BigInteger = require("bigi");
      var curves = require("./curves");
      var Curve = require("./curve");

      function getCurveByName(name) {
        var curve = curves[name];
        if (!curve) return null;
        var p = new BigInteger(curve.p, 16);
        var a = new BigInteger(curve.a, 16);
        var b = new BigInteger(curve.b, 16);
        var n = new BigInteger(curve.n, 16);
        var h = new BigInteger(curve.h, 16);
        var Gx = new BigInteger(curve.Gx, 16);
        var Gy = new BigInteger(curve.Gy, 16);
        return new Curve(p, a, b, Gx, Gy, n, h)
      }
      module.exports = getCurveByName
    }, {
      "./curve": 153,
      "./curves": 154,
      bigi: 3
    }],
    157: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var BigInteger = require("bigi");
        var THREE = BigInteger.valueOf(3);

        function Point(curve, x, y, z) {
          assert.notStrictEqual(z, undefined, "Missing Z coordinate");
          this.curve = curve;
          this.x = x;
          this.y = y;
          this.z = z;
          this._zInv = null;
          this.compressed = true
        }
        Object.defineProperty(Point.prototype, "zInv", {
          get: function() {
            if (this._zInv === null) {
              this._zInv = this.z.modInverse(this.curve.p)
            }
            return this._zInv
          }
        });
        Object.defineProperty(Point.prototype, "affineX", {
          get: function() {
            return this.x.multiply(this.zInv).mod(this.curve.p)
          }
        });
        Object.defineProperty(Point.prototype, "affineY", {
          get: function() {
            return this.y.multiply(this.zInv).mod(this.curve.p)
          }
        });
        Point.fromAffine = function(curve, x, y) {
          return new Point(curve, x, y, BigInteger.ONE)
        };
        Point.prototype.equals = function(other) {
          if (other === this) return true;
          if (this.curve.isInfinity(this)) return this.curve.isInfinity(other);
          if (this.curve.isInfinity(other)) return this.curve.isInfinity(this);
          var u = other.y.multiply(this.z).subtract(this.y.multiply(other.z)).mod(this.curve.p);
          if (u.signum() !== 0) return false;
          var v = other.x.multiply(this.z).subtract(this.x.multiply(other.z)).mod(this.curve.p);
          return v.signum() === 0
        };
        Point.prototype.negate = function() {
          var y = this.curve.p.subtract(this.y);
          return new Point(this.curve, this.x, y, this.z)
        };
        Point.prototype.add = function(b) {
          if (this.curve.isInfinity(this)) return b;
          if (this.curve.isInfinity(b)) return this;
          var x1 = this.x;
          var y1 = this.y;
          var x2 = b.x;
          var y2 = b.y;
          var u = y2.multiply(this.z).subtract(y1.multiply(b.z)).mod(this.curve.p);
          var v = x2.multiply(this.z).subtract(x1.multiply(b.z)).mod(this.curve.p);
          if (v.signum() === 0) {
            if (u.signum() === 0) {
              return this.twice()
            }
            return this.curve.infinity
          }
          var v2 = v.square();
          var v3 = v2.multiply(v);
          var x1v2 = x1.multiply(v2);
          var zu2 = u.square().multiply(this.z);
          var x3 = zu2.subtract(x1v2.shiftLeft(1)).multiply(b.z).subtract(v3).multiply(v).mod(this.curve.p);
          var y3 = x1v2.multiply(THREE).multiply(u).subtract(y1.multiply(v3)).subtract(zu2.multiply(u)).multiply(b.z).add(u.multiply(v3)).mod(this.curve.p);
          var z3 = v3.multiply(this.z).multiply(b.z).mod(this.curve.p);
          return new Point(this.curve, x3, y3, z3)
        };
        Point.prototype.twice = function() {
          if (this.curve.isInfinity(this)) return this;
          if (this.y.signum() === 0) return this.curve.infinity;
          var x1 = this.x;
          var y1 = this.y;
          var y1z1 = y1.multiply(this.z);
          var y1sqz1 = y1z1.multiply(y1).mod(this.curve.p);
          var a = this.curve.a;
          var w = x1.square().multiply(THREE);
          if (a.signum() !== 0) {
            w = w.add(this.z.square().multiply(a))
          }
          w = w.mod(this.curve.p);
          var x3 = w.square().subtract(x1.shiftLeft(3).multiply(y1sqz1)).shiftLeft(1).multiply(y1z1).mod(this.curve.p);
          var y3 = w.multiply(THREE).multiply(x1).subtract(y1sqz1.shiftLeft(1)).shiftLeft(2).multiply(y1sqz1).subtract(w.pow(3)).mod(this.curve.p);
          var z3 = y1z1.pow(3).shiftLeft(3).mod(this.curve.p);
          return new Point(this.curve, x3, y3, z3)
        };
        Point.prototype.multiply = function(k) {
          if (this.curve.isInfinity(this)) return this;
          if (k.signum() === 0) return this.curve.infinity;
          var e = k;
          var h = e.multiply(THREE);
          var neg = this.negate();
          var R = this;
          for (var i = h.bitLength() - 2; i > 0; --i) {
            R = R.twice();
            var hBit = h.testBit(i);
            var eBit = e.testBit(i);
            if (hBit != eBit) {
              R = R.add(hBit ? this : neg)
            }
          }
          return R
        };
        Point.prototype.multiplyTwo = function(j, x, k) {
          var i;
          if (j.bitLength() > k.bitLength()) i = j.bitLength() - 1;
          else i = k.bitLength() - 1;
          var R = this.curve.infinity;
          var both = this.add(x);
          while (i >= 0) {
            R = R.twice();
            var jBit = j.testBit(i);
            var kBit = k.testBit(i);
            if (jBit) {
              if (kBit) {
                R = R.add(both)
              } else {
                R = R.add(this)
              }
            } else {
              if (kBit) {
                R = R.add(x)
              }
            }--i
          }
          return R
        };
        Point.prototype.getEncoded = function(compressed) {
          if (compressed == undefined) compressed = this.compressed;
          if (this.curve.isInfinity(this)) return new Buffer("00", "hex");
          var x = this.affineX;
          var y = this.affineY;
          var buffer;
          var byteLength = Math.floor((this.curve.p.bitLength() + 7) / 8);
          if (compressed) {
            buffer = new Buffer(1 + byteLength);
            buffer.writeUInt8(y.isEven() ? 2 : 3, 0)
          } else {
            buffer = new Buffer(1 + byteLength + byteLength);
            buffer.writeUInt8(4, 0);
            y.toBuffer(byteLength).copy(buffer, 1 + byteLength)
          }
          x.toBuffer(byteLength).copy(buffer, 1);
          return buffer
        };
        Point.decodeFrom = function(curve, buffer) {
          var type = buffer.readUInt8(0);
          var compressed = type !== 4;
          var x = BigInteger.fromBuffer(buffer.slice(1, 33));
          var byteLength = Math.floor((curve.p.bitLength() + 7) / 8);
          var Q;
          if (compressed) {
            assert.equal(buffer.length, byteLength + 1, "Invalid sequence length");
            assert(type === 2 || type === 3, "Invalid sequence tag");
            var isOdd = type === 3;
            Q = curve.pointFromX(isOdd, x)
          } else {
            assert.equal(buffer.length, 1 + byteLength + byteLength, "Invalid sequence length");
            var y = BigInteger.fromBuffer(buffer.slice(1 + byteLength));
            Q = Point.fromAffine(curve, x, y)
          }
          Q.compressed = compressed;
          return Q
        };
        Point.prototype.toString = function() {
          if (this.curve.isInfinity(this)) return "(INFINITY)";
          return "(" + this.affineX.toString() + "," + this.affineY.toString() + ")"
        };
        module.exports = Point
      }).call(this, require("buffer").Buffer)
    }, {
      assert: 5,
      bigi: 3,
      buffer: 7
    }],
    158: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var base58check = require("bs58check");
        var enforceType = require("./types");
        var networks = require("./networks");
        var scripts = require("./scripts");

        function findScriptTypeByVersion(version) {
          for (var networkName in networks) {
            var network = networks[networkName];
            if (version === network.pubKeyHash) return "pubkeyhash";
            if (version === network.scriptHash) return "scripthash"
          }
        }

        function Address(hash, version) {
          enforceType("Buffer", hash);
          this.hash = hash;
          this.version = version
        }
        Address.fromBase58Check = function(string) {
          var payload = base58check.decode(string);
          var version = payload.readUInt8(0);
          var hash = payload.slice(1);
          return new Address(hash, version)
        };
        Address.fromOutputScript = function(script, network) {
          network = network || networks.bitcoin;
          if (scripts.isPubKeyHashOutput(script)) return new Address(script.chunks[2], network.pubKeyHash);
          if (scripts.isScriptHashOutput(script)) return new Address(script.chunks[1], network.scriptHash);
          assert(false, script.toASM() + " has no matching Address")
        };
        Address.prototype.toBase58Check = function() {
          var payload = new Buffer(21);
          if (this.version > 0xFF) {
            payload = new Buffer(22);
            payload.writeUInt16BE(this.version, 0);
            this.hash.copy(payload, 2);
          } else {
            payload.writeUInt8(this.version, 0);
            this.hash.copy(payload, 1);
          }

          return base58check.encode(payload)
        };
        Address.prototype.toOutputScript = function() {
          var scriptType = findScriptTypeByVersion(this.version);
          if (scriptType === "pubkeyhash") return scripts.pubKeyHashOutput(this.hash);
          if (scriptType === "scripthash") return scripts.scriptHashOutput(this.hash);
          assert(false, this.toString() + " has no matching Script")
        };
        Address.prototype.toString = Address.prototype.toBase58Check;
        module.exports = Address
      }).call(this, require("buffer").Buffer)
    }, {
      "./networks": 170,
      "./scripts": 173,
      "./types": 176,
      assert: 5,
      bs58check: 33,
      buffer: 7
    }],
    159: [function(require, module, exports) {
      var bs58check = require("bs58check");

      function decode() {
        console.warn('bs58check will be removed in 2.0.0. require("bs58check") instead.');
        return bs58check.decode.apply(undefined, arguments)
      }

      function encode() {
        console.warn('bs58check will be removed in 2.0.0. require("bs58check") instead.');
        return bs58check.encode.apply(undefined, arguments)
      }
      module.exports = {
        decode: decode,
        encode: encode
      }
    }, {
      bs58check: 33
    }],
    160: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var bufferutils = require("./bufferutils");
        var crypto = require("./crypto");
        var Transaction = require("./transaction");
        var Script = require("./script");

        function Block() {
          this.version = 1;
          this.prevHash = null;
          this.merkleRoot = null;
          this.timestamp = 0;
          this.bits = 0;
          this.nonce = 0
        }
        Block.fromBuffer = function(buffer) {
          assert(buffer.length >= 80, "Buffer too small (< 80 bytes)");
          var offset = 0;

          function readSlice(n) {
            offset += n;
            return buffer.slice(offset - n, offset)
          }

          function readUInt32() {
            var i = buffer.readUInt32LE(offset);
            offset += 4;
            return i
          }
          var block = new Block;
          block.version = readUInt32();
          block.prevHash = readSlice(32);
          block.merkleRoot = readSlice(32);
          block.timestamp = readUInt32();
          block.bits = readUInt32();
          block.nonce = readUInt32();
          if (buffer.length === 80) return block;

          function readUInt64() {
            var i = bufferutils.readUInt64LE(buffer, offset);
            offset += 8;
            return i
          }

          function readVarInt() {
            var vi = bufferutils.readVarInt(buffer, offset);
            offset += vi.size;
            return vi.number
          }

          function readScript() {
            return Script.fromBuffer(readSlice(readVarInt()))
          }

          function readTransaction() {
            var tx = new Transaction;
            tx.version = readUInt32();
            var vinLen = readVarInt();
            for (var i = 0; i < vinLen; ++i) {
              tx.ins.push({
                hash: readSlice(32),
                index: readUInt32(),
                script: readScript(),
                sequence: readUInt32()
              })
            }
            var voutLen = readVarInt();
            for (i = 0; i < voutLen; ++i) {
              tx.outs.push({
                value: readUInt64(),
                script: readScript()
              })
            }
            tx.locktime = readUInt32();
            return tx
          }
          var nTransactions = readVarInt();
          block.transactions = [];
          for (var i = 0; i < nTransactions; ++i) {
            var tx = readTransaction();
            block.transactions.push(tx)
          }
          return block
        };
        Block.fromHex = function(hex) {
          return Block.fromBuffer(new Buffer(hex, "hex"))
        };
        Block.prototype.getHash = function() {
          return crypto.hash256(this.toBuffer(true))
        };
        Block.prototype.getId = function() {
          return bufferutils.reverse(this.getHash()).toString("hex")
        };
        Block.prototype.getUTCDate = function() {
          var date = new Date(0);
          date.setUTCSeconds(this.timestamp);
          return date
        };
        Block.prototype.toBuffer = function(headersOnly) {
          var buffer = new Buffer(80);
          var offset = 0;

          function writeSlice(slice) {
            slice.copy(buffer, offset);
            offset += slice.length
          }

          function writeUInt32(i) {
            buffer.writeUInt32LE(i, offset);
            offset += 4
          }
          writeUInt32(this.version);
          writeSlice(this.prevHash);
          writeSlice(this.merkleRoot);
          writeUInt32(this.timestamp);
          writeUInt32(this.bits);
          writeUInt32(this.nonce);
          if (headersOnly || !this.transactions) return buffer;
          var txLenBuffer = bufferutils.varIntBuffer(this.transactions.length);
          var txBuffers = this.transactions.map(function(tx) {
            return tx.toBuffer()
          });
          return Buffer.concat([buffer, txLenBuffer].concat(txBuffers))
        };
        Block.prototype.toHex = function(headersOnly) {
          return this.toBuffer(headersOnly).toString("hex")
        };
        module.exports = Block
      }).call(this, require("buffer").Buffer)
    }, {
      "./bufferutils": 161,
      "./crypto": 162,
      "./script": 172,
      "./transaction": 174,
      assert: 5,
      buffer: 7
    }],
    161: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var opcodes = require("./opcodes");

        function verifuint(value, max) {
          assert(typeof value === "number", "cannot write a non-number as a number");
          assert(value >= 0, "specified a negative value for writing an unsigned value");
          assert(value <= max, "value is larger than maximum value for type");
          assert(Math.floor(value) === value, "value has a fractional component")
        }

        function pushDataSize(i) {
          return i < opcodes.OP_PUSHDATA1 ? 1 : i < 255 ? 2 : i < 65535 ? 3 : 5
        }

        function readPushDataInt(buffer, offset) {
          var opcode = buffer.readUInt8(offset);
          var number, size;
          if (opcode < opcodes.OP_PUSHDATA1) {
            number = opcode;
            size = 1
          } else if (opcode === opcodes.OP_PUSHDATA1) {
            number = buffer.readUInt8(offset + 1);
            size = 2
          } else if (opcode === opcodes.OP_PUSHDATA2) {
            number = buffer.readUInt16LE(offset + 1);
            size = 3
          } else {
            assert.equal(opcode, opcodes.OP_PUSHDATA4, "Unexpected opcode");
            number = buffer.readUInt32LE(offset + 1);
            size = 5
          }
          return {
            opcode: opcode,
            number: number,
            size: size
          }
        }

        function readUInt64LE(buffer, offset) {
          var a = buffer.readUInt32LE(offset);
          var b = buffer.readUInt32LE(offset + 4);
          b *= 4294967296;
          verifuint(b + a, 9007199254740991);
          return b + a
        }

        function readVarInt(buffer, offset) {
          var t = buffer.readUInt8(offset);
          var number, size;
          if (t < 253) {
            number = t;
            size = 1
          } else if (t < 254) {
            number = buffer.readUInt16LE(offset + 1);
            size = 3
          } else if (t < 255) {
            number = buffer.readUInt32LE(offset + 1);
            size = 5
          } else {
            number = readUInt64LE(buffer, offset + 1);
            size = 9
          }
          return {
            number: number,
            size: size
          }
        }

        function writePushDataInt(buffer, number, offset) {
          var size = pushDataSize(number);
          if (size === 1) {
            buffer.writeUInt8(number, offset)
          } else if (size === 2) {
            buffer.writeUInt8(opcodes.OP_PUSHDATA1, offset);
            buffer.writeUInt8(number, offset + 1)
          } else if (size === 3) {
            buffer.writeUInt8(opcodes.OP_PUSHDATA2, offset);
            buffer.writeUInt16LE(number, offset + 1)
          } else {
            buffer.writeUInt8(opcodes.OP_PUSHDATA4, offset);
            buffer.writeUInt32LE(number, offset + 1)
          }
          return size
        }

        function writeUInt64LE(buffer, value, offset) {
          verifuint(value, 9007199254740991);
          buffer.writeInt32LE(value & -1, offset);
          buffer.writeUInt32LE(Math.floor(value / 4294967296), offset + 4)
        }

        function varIntSize(i) {
          return i < 253 ? 1 : i < 65536 ? 3 : i < 4294967296 ? 5 : 9
        }

        function writeVarInt(buffer, number, offset) {
          var size = varIntSize(number);
          if (size === 1) {
            buffer.writeUInt8(number, offset)
          } else if (size === 3) {
            buffer.writeUInt8(253, offset);
            buffer.writeUInt16LE(number, offset + 1)
          } else if (size === 5) {
            buffer.writeUInt8(254, offset);
            buffer.writeUInt32LE(number, offset + 1)
          } else {
            buffer.writeUInt8(255, offset);
            writeUInt64LE(buffer, number, offset + 1)
          }
          return size
        }

        function varIntBuffer(i) {
          var size = varIntSize(i);
          var buffer = new Buffer(size);
          writeVarInt(buffer, i, 0);
          return buffer
        }

        function reverse(buffer) {
          var buffer2 = new Buffer(buffer);
          Array.prototype.reverse.call(buffer2);
          return buffer2
        }
        module.exports = {
          pushDataSize: pushDataSize,
          readPushDataInt: readPushDataInt,
          readUInt64LE: readUInt64LE,
          readVarInt: readVarInt,
          reverse: reverse,
          varIntBuffer: varIntBuffer,
          varIntSize: varIntSize,
          writePushDataInt: writePushDataInt,
          writeUInt64LE: writeUInt64LE,
          writeVarInt: writeVarInt
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./opcodes": 171,
      assert: 5,
      buffer: 7
    }],
    162: [function(require, module, exports) {
      var crypto = require("crypto");

      function hash160(buffer) {
        return ripemd160(sha256(buffer))
      }

      function hash256(buffer) {
        return sha256(sha256(buffer))
      }

      function ripemd160(buffer) {
        return crypto.createHash("rmd160").update(buffer).digest()
      }

      function sha1(buffer) {
        return crypto.createHash("sha1").update(buffer).digest()
      }

      function sha256(buffer) {
        return crypto.createHash("sha256").update(buffer).digest()
      }

      function HmacSHA256(buffer, secret) {
        console.warn("Hmac* functions are deprecated for removal in 2.0.0, use node crypto instead");
        return crypto.createHmac("sha256", secret).update(buffer).digest()
      }

      function HmacSHA512(buffer, secret) {
        console.warn("Hmac* functions are deprecated for removal in 2.0.0, use node crypto instead");
        return crypto.createHmac("sha512", secret).update(buffer).digest()
      }
      module.exports = {
        ripemd160: ripemd160,
        sha1: sha1,
        sha256: sha256,
        hash160: hash160,
        hash256: hash256,
        HmacSHA256: HmacSHA256,
        HmacSHA512: HmacSHA512
      }
    }, {
      crypto: 37
    }],
    163: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var crypto = require("crypto");
        var enforceType = require("./types");
        var BigInteger = require("bigi");
        var ECSignature = require("./ecsignature");
        var ZERO = new Buffer([0]);
        var ONE = new Buffer([1]);

        function deterministicGenerateK(curve, hash, d) {
          enforceType("Buffer", hash);
          enforceType(BigInteger, d);
          assert.equal(hash.length, 32, "Hash must be 256 bit");
          var x = d.toBuffer(32);
          var k = new Buffer(32);
          var v = new Buffer(32);
          v.fill(1);
          k.fill(0);
          k = crypto.createHmac("sha256", k).update(v).update(ZERO).update(x).update(hash).digest();
          v = crypto.createHmac("sha256", k).update(v).digest();
          k = crypto.createHmac("sha256", k).update(v).update(ONE).update(x).update(hash).digest();
          v = crypto.createHmac("sha256", k).update(v).digest();
          v = crypto.createHmac("sha256", k).update(v).digest();
          var T = BigInteger.fromBuffer(v);
          while (T.signum() <= 0 || T.compareTo(curve.n) >= 0) {
            k = crypto.createHmac("sha256", k).update(v).update(ZERO).digest();
            v = crypto.createHmac("sha256", k).update(v).digest();
            T = BigInteger.fromBuffer(v)
          }
          return T
        }

        function sign(curve, hash, d) {
          var k = deterministicGenerateK(curve, hash, d);
          var n = curve.n;
          var G = curve.G;
          var Q = G.multiply(k);
          var e = BigInteger.fromBuffer(hash);
          var r = Q.affineX.mod(n);
          assert.notEqual(r.signum(), 0, "Invalid R value");
          var s = k.modInverse(n).multiply(e.add(d.multiply(r))).mod(n);
          assert.notEqual(s.signum(), 0, "Invalid S value");
          var N_OVER_TWO = n.shiftRight(1);
          if (s.compareTo(N_OVER_TWO) > 0) {
            s = n.subtract(s)
          }
          return new ECSignature(r, s)
        }

        function verifyRaw(curve, e, signature, Q) {
          var n = curve.n;
          var G = curve.G;
          var r = signature.r;
          var s = signature.s;
          if (r.signum() <= 0 || r.compareTo(n) >= 0) return false;
          if (s.signum() <= 0 || s.compareTo(n) >= 0) return false;
          var c = s.modInverse(n);
          var u1 = e.multiply(c).mod(n);
          var u2 = r.multiply(c).mod(n);
          var R = G.multiplyTwo(u1, Q, u2);
          var v = R.affineX.mod(n);
          if (curve.isInfinity(R)) return false;
          return v.equals(r)
        }

        function verify(curve, hash, signature, Q) {
          var e = BigInteger.fromBuffer(hash);
          return verifyRaw(curve, e, signature, Q)
        }

        function recoverPubKey(curve, e, signature, i) {
          assert.strictEqual(i & 3, i, "Recovery param is more than two bits");
          var n = curve.n;
          var G = curve.G;
          var r = signature.r;
          var s = signature.s;
          assert(r.signum() > 0 && r.compareTo(n) < 0, "Invalid r value");
          assert(s.signum() > 0 && s.compareTo(n) < 0, "Invalid s value");
          var isYOdd = i & 1;
          var isSecondKey = i >> 1;
          var x = isSecondKey ? r.add(n) : r;
          var R = curve.pointFromX(isYOdd, x);
          var nR = R.multiply(n);
          assert(curve.isInfinity(nR), "nR is not a valid curve point");
          var eNeg = e.negate().mod(n);
          var rInv = r.modInverse(n);
          var Q = R.multiplyTwo(s, G, eNeg).multiply(rInv);
          curve.validate(Q);
          return Q
        }

        function calcPubKeyRecoveryParam(curve, e, signature, Q) {
          for (var i = 0; i < 4; i++) {
            var Qprime = recoverPubKey(curve, e, signature, i);
            if (Qprime.equals(Q)) {
              return i
            }
          }
          throw new Error("Unable to find valid recovery factor")
        }
        module.exports = {
          calcPubKeyRecoveryParam: calcPubKeyRecoveryParam,
          deterministicGenerateK: deterministicGenerateK,
          recoverPubKey: recoverPubKey,
          sign: sign,
          verify: verify,
          verifyRaw: verifyRaw
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./ecsignature": 166,
      "./types": 176,
      assert: 5,
      bigi: 3,
      buffer: 7,
      crypto: 37
    }],
    164: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var base58check = require("bs58check");
        var crypto = require("crypto");
        var ecdsa = require("./ecdsa");
        var enforceType = require("./types");
        var networks = require("./networks");
        var BigInteger = require("bigi");
        var ECPubKey = require("./ecpubkey");
        var ecurve = require("ecurve");
        var secp256k1 = ecurve.getCurveByName("secp256k1");

        function ECKey(d, compressed) {
          assert(d.signum() > 0, "Private key must be greater than 0");
          assert(d.compareTo(ECKey.curve.n) < 0, "Private key must be less than the curve order");
          var Q = ECKey.curve.G.multiply(d);
          this.d = d;
          this.pub = new ECPubKey(Q, compressed)
        }
        ECKey.curve = secp256k1;
        ECKey.fromWIF = function(string) {
          var payload = base58check.decode(string);
          var compressed = false;
          payload = payload.slice(1);
          if (payload.length === 33) {
            assert.strictEqual(payload[32], 1, "Invalid compression flag");
            payload = payload.slice(0, -1);
            compressed = true
          }
          assert.equal(payload.length, 32, "Invalid WIF payload length");
          var d = BigInteger.fromBuffer(payload);
          return new ECKey(d, compressed)
        };
        ECKey.makeRandom = function(compressed, rng) {
          rng = rng || crypto.randomBytes;
          var buffer = rng(32);
          enforceType("Buffer", buffer);
          assert.equal(buffer.length, 32, "Expected 256-bit Buffer from RNG");
          var d = BigInteger.fromBuffer(buffer);
          d = d.mod(ECKey.curve.n);
          return new ECKey(d, compressed)
        };
        ECKey.prototype.toWIF = function(network) {
          network = network || networks.bitcoin;
          var bufferLen = this.pub.compressed ? 34 : 33;
          var buffer = new Buffer(bufferLen);
          buffer.writeUInt8(network.wif, 0);
          this.d.toBuffer(32).copy(buffer, 1);
          if (this.pub.compressed) {
            buffer.writeUInt8(1, 33)
          }
          return base58check.encode(buffer)
        };
        ECKey.prototype.sign = function(hash) {
          return ecdsa.sign(ECKey.curve, hash, this.d)
        };
        module.exports = ECKey
      }).call(this, require("buffer").Buffer)
    }, {
      "./ecdsa": 163,
      "./ecpubkey": 165,
      "./networks": 170,
      "./types": 176,
      assert: 5,
      bigi: 3,
      bs58check: 33,
      buffer: 7,
      crypto: 37,
      ecurve: 155
    }],
    165: [function(require, module, exports) {
      (function(Buffer) {
        var crypto = require("./crypto");
        var ecdsa = require("./ecdsa");
        var enforceType = require("./types");
        var networks = require("./networks");
        var Address = require("./address");
        var ecurve = require("ecurve");
        var secp256k1 = ecurve.getCurveByName("secp256k1");

        function ECPubKey(Q, compressed) {
          if (compressed === undefined) compressed = true;
          enforceType(ecurve.Point, Q);
          enforceType("Boolean", compressed);
          this.compressed = compressed;
          this.Q = Q
        }
        ECPubKey.curve = secp256k1;
        ECPubKey.fromBuffer = function(buffer) {
          var Q = ecurve.Point.decodeFrom(ECPubKey.curve, buffer);
          return new ECPubKey(Q, Q.compressed)
        };
        ECPubKey.fromHex = function(hex) {
          return ECPubKey.fromBuffer(new Buffer(hex, "hex"))
        };
        ECPubKey.prototype.getAddress = function(network) {
          network = network || networks.bitcoin;
          return new Address(crypto.hash160(this.toBuffer()), network.pubKeyHash)
        };
        ECPubKey.prototype.verify = function(hash, signature) {
          return ecdsa.verify(ECPubKey.curve, hash, signature, this.Q)
        };
        ECPubKey.prototype.toBuffer = function() {
          return this.Q.getEncoded(this.compressed)
        };
        ECPubKey.prototype.toHex = function() {
          return this.toBuffer().toString("hex")
        };
        module.exports = ECPubKey
      }).call(this, require("buffer").Buffer)
    }, {
      "./address": 158,
      "./crypto": 162,
      "./ecdsa": 163,
      "./networks": 170,
      "./types": 176,
      buffer: 7,
      ecurve: 155
    }],
    166: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var enforceType = require("./types");
        var BigInteger = require("bigi");

        function ECSignature(r, s) {
          enforceType(BigInteger, r);
          enforceType(BigInteger, s);
          this.r = r;
          this.s = s
        }
        ECSignature.parseCompact = function(buffer) {
          assert.equal(buffer.length, 65, "Invalid signature length");
          var i = buffer.readUInt8(0) - 27;
          assert.equal(i, i & 7, "Invalid signature parameter");
          var compressed = !!(i & 4);
          i = i & 3;
          var r = BigInteger.fromBuffer(buffer.slice(1, 33));
          var s = BigInteger.fromBuffer(buffer.slice(33));
          return {
            compressed: compressed,
            i: i,
            signature: new ECSignature(r, s)
          }
        };
        ECSignature.fromDER = function(buffer) {
          assert.equal(buffer.readUInt8(0), 48, "Not a DER sequence");
          assert.equal(buffer.readUInt8(1), buffer.length - 2, "Invalid sequence length");
          assert.equal(buffer.readUInt8(2), 2, "Expected a DER integer");
          var rLen = buffer.readUInt8(3);
          assert(rLen > 0, "R length is zero");
          var offset = 4 + rLen;
          assert.equal(buffer.readUInt8(offset), 2, "Expected a DER integer (2)");
          var sLen = buffer.readUInt8(offset + 1);
          assert(sLen > 0, "S length is zero");
          var rB = buffer.slice(4, offset);
          var sB = buffer.slice(offset + 2);
          offset += 2 + sLen;
          if (rLen > 1 && rB.readUInt8(0) === 0) {
            assert(rB.readUInt8(1) & 128, "R value excessively padded")
          }
          if (sLen > 1 && sB.readUInt8(0) === 0) {
            assert(sB.readUInt8(1) & 128, "S value excessively padded")
          }
          assert.equal(offset, buffer.length, "Invalid DER encoding");
          var r = BigInteger.fromDERInteger(rB);
          var s = BigInteger.fromDERInteger(sB);
          assert(r.signum() >= 0, "R value is negative");
          assert(s.signum() >= 0, "S value is negative");
          return new ECSignature(r, s)
        };
        ECSignature.parseScriptSignature = function(buffer) {
          var hashType = buffer.readUInt8(buffer.length - 1);
          var hashTypeMod = hashType & ~128;
          assert(hashTypeMod > 0 && hashTypeMod < 4, "Invalid hashType");
          return {
            signature: ECSignature.fromDER(buffer.slice(0, -1)),
            hashType: hashType
          }
        };
        ECSignature.prototype.toCompact = function(i, compressed) {
          if (compressed) i += 4;
          i += 27;
          var buffer = new Buffer(65);
          buffer.writeUInt8(i, 0);
          this.r.toBuffer(32).copy(buffer, 1);
          this.s.toBuffer(32).copy(buffer, 33);
          return buffer
        };
        ECSignature.prototype.toDER = function() {
          var rBa = this.r.toDERInteger();
          var sBa = this.s.toDERInteger();
          var sequence = [];
          sequence.push(2, rBa.length);
          sequence = sequence.concat(rBa);
          sequence.push(2, sBa.length);
          sequence = sequence.concat(sBa);
          sequence.unshift(48, sequence.length);
          return new Buffer(sequence)
        };
        ECSignature.prototype.toScriptSignature = function(hashType) {
          var hashTypeBuffer = new Buffer(1);
          hashTypeBuffer.writeUInt8(hashType, 0);
          return Buffer.concat([this.toDER(), hashTypeBuffer])
        };
        module.exports = ECSignature
      }).call(this, require("buffer").Buffer)
    }, {
      "./types": 176,
      assert: 5,
      bigi: 3,
      buffer: 7
    }],
    167: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var base58check = require("bs58check");
        var bcrypto = require("./crypto");
        var crypto = require("crypto");
        var enforceType = require("./types");
        var networks = require("./networks");
        var BigInteger = require("bigi");
        var ECKey = require("./eckey");
        var ECPubKey = require("./ecpubkey");
        var ecurve = require("ecurve");
        var curve = ecurve.getCurveByName("secp256k1");

        function findBIP32NetworkByVersion(version) {
          for (var name in networks) {
            var network = networks[name];
            if (version === network.bip32.private || version === network.bip32.public) {
              return network
            }
          }
          assert(false, "Could not find network for " + version.toString(16))
        }

        function HDNode(K, chainCode, network) {
          network = network || networks.bitcoin;
          enforceType("Buffer", chainCode);
          assert.equal(chainCode.length, 32, "Expected chainCode length of 32, got " + chainCode.length);
          assert(network.bip32, "Unknown BIP32 constants for network");
          this.chainCode = chainCode;
          this.depth = 0;
          this.index = 0;
          this.parentFingerprint = 0;
          this.network = network;
          if (K instanceof BigInteger) {
            this.privKey = new ECKey(K, true);
            this.pubKey = this.privKey.pub
          } else {
            this.pubKey = new ECPubKey(K, true)
          }
        }
        HDNode.MASTER_SECRET = new Buffer("Bitcoin seed");
        HDNode.HIGHEST_BIT = 2147483648;
        HDNode.LENGTH = 78;
        HDNode.fromSeedBuffer = function(seed, network) {
          enforceType("Buffer", seed);
          assert(seed.length >= 16, "Seed should be at least 128 bits");
          assert(seed.length <= 64, "Seed should be at most 512 bits");
          var I = crypto.createHmac("sha512", HDNode.MASTER_SECRET).update(seed).digest();
          var IL = I.slice(0, 32);
          var IR = I.slice(32);
          var pIL = BigInteger.fromBuffer(IL);
          return new HDNode(pIL, IR, network)
        };
        HDNode.fromSeedHex = function(hex, network) {
          return HDNode.fromSeedBuffer(new Buffer(hex, "hex"), network)
        };
        HDNode.fromBase58 = function(string, network) {
          return HDNode.fromBuffer(base58check.decode(string), network, true)
        };
        HDNode.fromBuffer = function(buffer, network, __ignoreDeprecation) {
          if (!__ignoreDeprecation) {
            console.warn("HDNode.fromBuffer() is deprecated for removal in 2.x.y, use fromBase58 instead")
          }
          assert.strictEqual(buffer.length, HDNode.LENGTH, "Invalid buffer length");
          var version = buffer.readUInt32BE(0);
          if (network) {
            assert(version === network.bip32.private || version === network.bip32.public, "Network doesn't match")
          } else {
            network = findBIP32NetworkByVersion(version)
          }
          var depth = buffer.readUInt8(4);
          var parentFingerprint = buffer.readUInt32BE(5);
          if (depth === 0) {
            assert.strictEqual(parentFingerprint, 0, "Invalid parent fingerprint")
          }
          var index = buffer.readUInt32BE(9);
          assert(depth > 0 || index === 0, "Invalid index");
          var chainCode = buffer.slice(13, 45);
          var data, hd;
          if (version === network.bip32.private) {
            assert.strictEqual(buffer.readUInt8(45), 0, "Invalid private key");
            data = buffer.slice(46, 78);
            var d = BigInteger.fromBuffer(data);
            hd = new HDNode(d, chainCode, network)
          } else {
            data = buffer.slice(45, 78);
            var Q = ecurve.Point.decodeFrom(curve, data);
            assert.equal(Q.compressed, true, "Invalid public key");
            curve.validate(Q);
            hd = new HDNode(Q, chainCode, network)
          }
          hd.depth = depth;
          hd.index = index;
          hd.parentFingerprint = parentFingerprint;
          return hd
        };
        HDNode.fromHex = function(hex, network) {
          return HDNode.fromBuffer(new Buffer(hex, "hex"), network)
        };
        HDNode.prototype.getIdentifier = function() {
          return bcrypto.hash160(this.pubKey.toBuffer())
        };
        HDNode.prototype.getFingerprint = function() {
          return this.getIdentifier().slice(0, 4)
        };
        HDNode.prototype.getAddress = function() {
          return this.pubKey.getAddress(this.network)
        };
        HDNode.prototype.neutered = function() {
          var neutered = new HDNode(this.pubKey.Q, this.chainCode, this.network);
          neutered.depth = this.depth;
          neutered.index = this.index;
          neutered.parentFingerprint = this.parentFingerprint;
          return neutered
        };
        HDNode.prototype.toBase58 = function(isPrivate) {
          return base58check.encode(this.toBuffer(isPrivate, true))
        };
        HDNode.prototype.toBuffer = function(isPrivate, __ignoreDeprecation) {
          if (isPrivate === undefined) {
            isPrivate = !!this.privKey
          } else {
            console.warn("isPrivate flag is deprecated, please use the .neutered() method instead")
          }
          if (!__ignoreDeprecation) {
            console.warn("HDNode.toBuffer() is deprecated for removal in 2.x.y, use toBase58 instead")
          }
          var version = isPrivate ? this.network.bip32.private : this.network.bip32.public;
          var buffer = new Buffer(HDNode.LENGTH);
          buffer.writeUInt32BE(version, 0);
          buffer.writeUInt8(this.depth, 4);
          buffer.writeUInt32BE(this.parentFingerprint, 5);
          buffer.writeUInt32BE(this.index, 9);
          this.chainCode.copy(buffer, 13);
          if (isPrivate) {
            assert(this.privKey, "Missing private key");
            buffer.writeUInt8(0, 45);
            this.privKey.d.toBuffer(32).copy(buffer, 46)
          } else {
            this.pubKey.toBuffer().copy(buffer, 45)
          }
          return buffer
        };
        HDNode.prototype.toHex = function(isPrivate) {
          return this.toBuffer(isPrivate).toString("hex")
        };
        HDNode.prototype.derive = function(index) {
          var isHardened = index >= HDNode.HIGHEST_BIT;
          var indexBuffer = new Buffer(4);
          indexBuffer.writeUInt32BE(index, 0);
          var data;
          if (isHardened) {
            assert(this.privKey, "Could not derive hardened child key");
            data = Buffer.concat([this.privKey.d.toBuffer(33), indexBuffer])
          } else {
            data = Buffer.concat([this.pubKey.toBuffer(), indexBuffer])
          }
          var I = crypto.createHmac("sha512", this.chainCode).update(data).digest();
          var IL = I.slice(0, 32);
          var IR = I.slice(32);
          var pIL = BigInteger.fromBuffer(IL);
          if (pIL.compareTo(curve.n) >= 0) {
            return this.derive(index + 1)
          }
          var hd;
          if (this.privKey) {
            var ki = pIL.add(this.privKey.d).mod(curve.n);
            if (ki.signum() === 0) {
              return this.derive(index + 1)
            }
            hd = new HDNode(ki, IR, this.network)
          } else {
            var Ki = curve.G.multiply(pIL).add(this.pubKey.Q);
            if (curve.isInfinity(Ki)) {
              return this.derive(index + 1)
            }
            hd = new HDNode(Ki, IR, this.network)
          }
          hd.depth = this.depth + 1;
          hd.index = index;
          hd.parentFingerprint = this.getFingerprint().readUInt32BE(0);
          return hd
        };
        HDNode.prototype.deriveHardened = function(index) {
          return this.derive(index + HDNode.HIGHEST_BIT)
        };
        HDNode.prototype.toString = HDNode.prototype.toBase58;
        module.exports = HDNode
      }).call(this, require("buffer").Buffer)
    }, {
      "./crypto": 162,
      "./eckey": 164,
      "./ecpubkey": 165,
      "./networks": 170,
      "./types": 176,
      assert: 5,
      bigi: 3,
      bs58check: 33,
      buffer: 7,
      crypto: 37,
      ecurve: 155
    }],
    168: [function(require, module, exports) {
      module.exports = {
        Address: require("./address"),
        base58check: require("./base58check"),
        Block: require("./block"),
        bufferutils: require("./bufferutils"),
        crypto: require("./crypto"),
        ecdsa: require("./ecdsa"),
        ECKey: require("./eckey"),
        ECPubKey: require("./ecpubkey"),
        ECSignature: require("./ecsignature"),
        Message: require("./message"),
        opcodes: require("./opcodes"),
        HDNode: require("./hdnode"),
        Script: require("./script"),
        scripts: require("./scripts"),
        Transaction: require("./transaction"),
        TransactionBuilder: require("./transaction_builder"),
        networks: require("./networks"),
        Wallet: require("./wallet")
      }
    }, {
      "./address": 158,
      "./base58check": 159,
      "./block": 160,
      "./bufferutils": 161,
      "./crypto": 162,
      "./ecdsa": 163,
      "./eckey": 164,
      "./ecpubkey": 165,
      "./ecsignature": 166,
      "./hdnode": 167,
      "./message": 169,
      "./networks": 170,
      "./opcodes": 171,
      "./script": 172,
      "./scripts": 173,
      "./transaction": 174,
      "./transaction_builder": 175,
      "./wallet": 177
    }],
    169: [function(require, module, exports) {
      (function(Buffer) {
        var bufferutils = require("./bufferutils");
        var crypto = require("./crypto");
        var ecdsa = require("./ecdsa");
        var networks = require("./networks");
        var BigInteger = require("bigi");
        var ECPubKey = require("./ecpubkey");
        var ECSignature = require("./ecsignature");
        var ecurve = require("ecurve");
        var ecparams = ecurve.getCurveByName("secp256k1");

        function magicHash(message, network) {
          var magicPrefix = new Buffer(network.magicPrefix);
          var messageBuffer = new Buffer(message);
          var lengthBuffer = bufferutils.varIntBuffer(messageBuffer.length);
          var buffer = Buffer.concat([magicPrefix, lengthBuffer, messageBuffer]);
          return crypto.hash256(buffer)
        }

        function sign(privKey, message, network) {
          network = network || networks.bitcoin;
          var hash = magicHash(message, network);
          var signature = privKey.sign(hash);
          var e = BigInteger.fromBuffer(hash);
          var i = ecdsa.calcPubKeyRecoveryParam(ecparams, e, signature, privKey.pub.Q);
          return signature.toCompact(i, privKey.pub.compressed)
        }

        function verify(address, signature, message, network) {
          if (!Buffer.isBuffer(signature)) {
            signature = new Buffer(signature, "base64")
          }
          network = network || networks.bitcoin;
          var hash = magicHash(message, network);
          var parsed = ECSignature.parseCompact(signature);
          var e = BigInteger.fromBuffer(hash);
          var Q = ecdsa.recoverPubKey(ecparams, e, parsed.signature, parsed.i);
          var pubKey = new ECPubKey(Q, parsed.compressed);
          return pubKey.getAddress(network).toString() === address.toString()
        }
        module.exports = {
          magicHash: magicHash,
          sign: sign,
          verify: verify
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./bufferutils": 161,
      "./crypto": 162,
      "./ecdsa": 163,
      "./ecpubkey": 165,
      "./ecsignature": 166,
      "./networks": 170,
      bigi: 3,
      buffer: 7,
      ecurve: 155
    }],
    170: [function(require, module, exports) {
      var networks = {
        bitcoin: {
          magicPrefix: "Bitcoin Signed Message:\n",
          bip32: {
            "public": 76067358,
            "private": 76066276
          },
          pubKeyHash: 0,
          scriptHash: 5,
          wif: 128,
          dustThreshold: 546,
          feePerKb: 1e4,
          estimateFee: estimateFee("bitcoin")
        },
        testnet: {
          magicPrefix: "Bitcoin Signed Message:\n",
          bip32: {
            "public": 70617039,
            "private": 70615956
          },
          pubKeyHash: 111,
          scriptHash: 196,
          wif: 239,
          dustThreshold: 546,
          feePerKb: 1e4,
          estimateFee: estimateFee("testnet")
        },
        litecoin: {
          magicPrefix: "Litecoin Signed Message:\n",
          bip32: {
            "public": 27108450,
            "private": 27106558
          },
          pubKeyHash: 48,
          scriptHash: 5,
          wif: 176,
          dustThreshold: 0,
          dustSoftThreshold: 1e5,
          feePerKb: 1e5,
          estimateFee: estimateFee("litecoin")
        },
        gamecredits: {
          magicPrefix: "Gamecredits Signed Message:\n",
          bip32: {
            "public": 27108450,
            "private": 27106558
          },
          pubKeyHash: 38,
          scriptHash: 5,
          wif: 166,
          dustThreshold: 0,
          dustSoftThreshold: 1e5,
          feePerKb: 1e5,
          estimateFee: estimateFee("gamecredits")
        },
        dogecoin: {
          magicPrefix: "Dogecoin Signed Message:\n",
          bip32: {
            "public": 49990397,
            "private": 49988504
          },
          pubKeyHash: 30,
          scriptHash: 22,
          wif: 158,
          dustThreshold: 0,
          dustSoftThreshold: 1e8,
          feePerKb: 1e8,
          estimateFee: estimateFee("dogecoin")
        },
        viacoin: {
          magicPrefix: "Viacoin Signed Message:\n",
          bip32: {
            "public": 76067358,
            "private": 76066276
          },
          pubKeyHash: 71,
          scriptHash: 33,
          wif: 199,
          dustThreshold: 560,
          dustSoftThreshold: 1e5,
          feePerKb: 1e5,
          estimateFee: estimateFee("viacoin")
        },
        viacointestnet: {
          magicPrefix: "Viacoin Signed Message:\n",
          bip32: {
            "public": 70617039,
            "private": 70615956
          },
          pubKeyHash: 127,
          scriptHash: 196,
          wif: 255,
          dustThreshold: 560,
          dustSoftThreshold: 1e5,
          feePerKb: 1e5,
          estimateFee: estimateFee("viacointestnet")
        },
        gamerscoin: {
          magicPrefix: "Gamerscoin Signed Message:\n",
          bip32: {
            "public": 27108450,
            "private": 27106558
          },
          pubKeyHash: 38,
          scriptHash: 5,
          wif: 166,
          dustThreshold: 0,
          dustSoftThreshold: 1e5,
          feePerKb: 1e5,
          estimateFee: estimateFee("gamerscoin")
        },
        jumbucks: {
          magicPrefix: "Jumbucks Signed Message:\n",
          bip32: {
            "public": 58353818,
            "private": 58352736
          },
          pubKeyHash: 43,
          scriptHash: 5,
          wif: 171,
          dustThreshold: 0,
          dustSoftThreshold: 1e4,
          feePerKb: 1e4,
          estimateFee: estimateFee("jumbucks")
        },
        zetacoin: {
          magicPrefix: "Zetacoin Signed Message:\n",
          bip32: {
            "public": 76067358,
            "private": 76066276
          },
          pubKeyHash: 80,
          scriptHash: 9,
          wif: 224,
          dustThreshold: 546,
          feePerKb: 1e4,
          estimateFee: estimateFee("zetacoin")
        }
      };

      function estimateFee(type) {
        return function(tx) {
          var network = networks[type];
          var baseFee = network.feePerKb;
          var byteSize = tx.toBuffer().length;
          var fee = baseFee * Math.ceil(byteSize / 1e3);
          if (network.dustSoftThreshold == undefined) return fee;
          tx.outs.forEach(function(e) {
            if (e.value < network.dustSoftThreshold) {
              fee += baseFee
            }
          });
          return fee
        }
      }
      module.exports = networks
    }, {}],
    171: [function(require, module, exports) {
      module.exports = {
        OP_FALSE: 0,
        OP_0: 0,
        OP_PUSHDATA1: 76,
        OP_PUSHDATA2: 77,
        OP_PUSHDATA4: 78,
        OP_1NEGATE: 79,
        OP_RESERVED: 80,
        OP_1: 81,
        OP_TRUE: 81,
        OP_2: 82,
        OP_3: 83,
        OP_4: 84,
        OP_5: 85,
        OP_6: 86,
        OP_7: 87,
        OP_8: 88,
        OP_9: 89,
        OP_10: 90,
        OP_11: 91,
        OP_12: 92,
        OP_13: 93,
        OP_14: 94,
        OP_15: 95,
        OP_16: 96,
        OP_NOP: 97,
        OP_VER: 98,
        OP_IF: 99,
        OP_NOTIF: 100,
        OP_VERIF: 101,
        OP_VERNOTIF: 102,
        OP_ELSE: 103,
        OP_ENDIF: 104,
        OP_VERIFY: 105,
        OP_RETURN: 106,
        OP_TOALTSTACK: 107,
        OP_FROMALTSTACK: 108,
        OP_2DROP: 109,
        OP_2DUP: 110,
        OP_3DUP: 111,
        OP_2OVER: 112,
        OP_2ROT: 113,
        OP_2SWAP: 114,
        OP_IFDUP: 115,
        OP_DEPTH: 116,
        OP_DROP: 117,
        OP_DUP: 118,
        OP_NIP: 119,
        OP_OVER: 120,
        OP_PICK: 121,
        OP_ROLL: 122,
        OP_ROT: 123,
        OP_SWAP: 124,
        OP_TUCK: 125,
        OP_CAT: 126,
        OP_SUBSTR: 127,
        OP_LEFT: 128,
        OP_RIGHT: 129,
        OP_SIZE: 130,
        OP_INVERT: 131,
        OP_AND: 132,
        OP_OR: 133,
        OP_XOR: 134,
        OP_EQUAL: 135,
        OP_EQUALVERIFY: 136,
        OP_RESERVED1: 137,
        OP_RESERVED2: 138,
        OP_1ADD: 139,
        OP_1SUB: 140,
        OP_2MUL: 141,
        OP_2DIV: 142,
        OP_NEGATE: 143,
        OP_ABS: 144,
        OP_NOT: 145,
        OP_0NOTEQUAL: 146,
        OP_ADD: 147,
        OP_SUB: 148,
        OP_MUL: 149,
        OP_DIV: 150,
        OP_MOD: 151,
        OP_LSHIFT: 152,
        OP_RSHIFT: 153,
        OP_BOOLAND: 154,
        OP_BOOLOR: 155,
        OP_NUMEQUAL: 156,
        OP_NUMEQUALVERIFY: 157,
        OP_NUMNOTEQUAL: 158,
        OP_LESSTHAN: 159,
        OP_GREATERTHAN: 160,
        OP_LESSTHANOREQUAL: 161,
        OP_GREATERTHANOREQUAL: 162,
        OP_MIN: 163,
        OP_MAX: 164,
        OP_WITHIN: 165,
        OP_RIPEMD160: 166,
        OP_SHA1: 167,
        OP_SHA256: 168,
        OP_HASH160: 169,
        OP_HASH256: 170,
        OP_CODESEPARATOR: 171,
        OP_CHECKSIG: 172,
        OP_CHECKSIGVERIFY: 173,
        OP_CHECKMULTISIG: 174,
        OP_CHECKMULTISIGVERIFY: 175,
        OP_NOP1: 176,
        OP_NOP2: 177,
        OP_NOP3: 178,
        OP_NOP4: 179,
        OP_NOP5: 180,
        OP_NOP6: 181,
        OP_NOP7: 182,
        OP_NOP8: 183,
        OP_NOP9: 184,
        OP_NOP10: 185,
        OP_PUBKEYHASH: 253,
        OP_PUBKEY: 254,
        OP_INVALIDOPCODE: 255
      }
    }, {}],
    172: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var bufferutils = require("./bufferutils");
        var crypto = require("./crypto");
        var enforceType = require("./types");
        var opcodes = require("./opcodes");

        function Script(buffer, chunks) {
          enforceType("Buffer", buffer);
          enforceType("Array", chunks);
          this.buffer = buffer;
          this.chunks = chunks
        }
        Script.fromASM = function(asm) {
          var strChunks = asm.split(" ");
          var chunks = strChunks.map(function(strChunk) {
            if (strChunk in opcodes) {
              return opcodes[strChunk]
            } else {
              return new Buffer(strChunk, "hex")
            }
          });
          return Script.fromChunks(chunks)
        };
        Script.fromBuffer = function(buffer) {
          var chunks = [];
          var i = 0;
          while (i < buffer.length) {
            var opcode = buffer.readUInt8(i);
            if (opcode > opcodes.OP_0 && opcode <= opcodes.OP_PUSHDATA4) {
              var d = bufferutils.readPushDataInt(buffer, i);
              i += d.size;
              var data = buffer.slice(i, i + d.number);
              i += d.number;
              chunks.push(data)
            } else {
              chunks.push(opcode);
              i += 1
            }
          }
          return new Script(buffer, chunks)
        };
        Script.fromChunks = function(chunks) {
          enforceType("Array", chunks);
          var bufferSize = chunks.reduce(function(accum, chunk) {
            if (Buffer.isBuffer(chunk)) {
              return accum + bufferutils.pushDataSize(chunk.length) + chunk.length
            }
            return accum + 1
          }, 0);
          var buffer = new Buffer(bufferSize);
          var offset = 0;
          chunks.forEach(function(chunk) {
            if (Buffer.isBuffer(chunk)) {
              offset += bufferutils.writePushDataInt(buffer, chunk.length, offset);
              chunk.copy(buffer, offset);
              offset += chunk.length
            } else {
              buffer.writeUInt8(chunk, offset);
              offset += 1
            }
          });
          assert.equal(offset, buffer.length, "Could not decode chunks");
          return new Script(buffer, chunks)
        };
        Script.fromHex = function(hex) {
          return Script.fromBuffer(new Buffer(hex, "hex"))
        };
        Script.EMPTY = Script.fromChunks([]);
        Script.prototype.getHash = function() {
          return crypto.hash160(this.buffer)
        };
        Script.prototype.without = function(needle) {
          return Script.fromChunks(this.chunks.filter(function(op) {
            return op !== needle
          }))
        };
        var reverseOps = [];
        for (var op in opcodes) {
          var code = opcodes[op];
          reverseOps[code] = op
        }
        Script.prototype.toASM = function() {
          return this.chunks.map(function(chunk) {
            if (Buffer.isBuffer(chunk)) {
              return chunk.toString("hex")
            } else {
              return reverseOps[chunk]
            }
          }).join(" ")
        };
        Script.prototype.toBuffer = function() {
          return this.buffer
        };
        Script.prototype.toHex = function() {
          return this.toBuffer().toString("hex")
        };
        module.exports = Script
      }).call(this, require("buffer").Buffer)
    }, {
      "./bufferutils": 161,
      "./crypto": 162,
      "./opcodes": 171,
      "./types": 176,
      assert: 5,
      buffer: 7
    }],
    173: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var enforceType = require("./types");
        var ops = require("./opcodes");
        var ecurve = require("ecurve");
        var curve = ecurve.getCurveByName("secp256k1");
        var ECSignature = require("./ecsignature");
        var Script = require("./script");

        function isCanonicalPubKey(buffer) {
          if (!Buffer.isBuffer(buffer)) return false;
          try {
            ecurve.Point.decodeFrom(curve, buffer)
          } catch (e) {
            if (!e.message.match(/Invalid sequence (length|tag)/)) throw e;
            return false
          }
          return true
        }

        function isCanonicalSignature(buffer) {
          if (!Buffer.isBuffer(buffer)) return false;
          try {
            ECSignature.parseScriptSignature(buffer)
          } catch (e) {
            if (!e.message.match(/Not a DER sequence|Invalid sequence length|Expected a DER integer|R length is zero|S length is zero|R value excessively padded|S value excessively padded|R value is negative|S value is negative|Invalid hashType/)) throw e;
            return false
          }
          return true
        }

        function isPubKeyHashInput(script) {
          return script.chunks.length === 2 && isCanonicalSignature(script.chunks[0]) && isCanonicalPubKey(script.chunks[1])
        }

        function isPubKeyHashOutput(script) {
          return script.chunks.length === 5 && script.chunks[0] === ops.OP_DUP && script.chunks[1] === ops.OP_HASH160 && Buffer.isBuffer(script.chunks[2]) && script.chunks[2].length === 20 && script.chunks[3] === ops.OP_EQUALVERIFY && script.chunks[4] === ops.OP_CHECKSIG
        }

        function isPubKeyInput(script) {
          return script.chunks.length === 1 && isCanonicalSignature(script.chunks[0])
        }

        function isPubKeyOutput(script) {
          return script.chunks.length === 2 && isCanonicalPubKey(script.chunks[0]) && script.chunks[1] === ops.OP_CHECKSIG
        }

        function isScriptHashInput(script) {
          if (script.chunks.length < 2) return false;
          var lastChunk = script.chunks[script.chunks.length - 1];
          if (!Buffer.isBuffer(lastChunk)) return false;
          var scriptSig = Script.fromChunks(script.chunks.slice(0, -1));
          var scriptPubKey = Script.fromBuffer(lastChunk);
          return classifyInput(scriptSig) === classifyOutput(scriptPubKey)
        }

        function isScriptHashOutput(script) {
          return script.chunks.length === 3 && script.chunks[0] === ops.OP_HASH160 && Buffer.isBuffer(script.chunks[1]) && script.chunks[1].length === 20 && script.chunks[2] === ops.OP_EQUAL
        }

        function isMultisigInput(script) {
          return script.chunks[0] === ops.OP_0 && script.chunks.slice(1).every(isCanonicalSignature)
        }

        function isMultisigOutput(script) {
          if (script.chunks.length < 4) return false;
          if (script.chunks[script.chunks.length - 1] !== ops.OP_CHECKMULTISIG) return false;
          var mOp = script.chunks[0];
          if (mOp === ops.OP_0) return false;
          if (mOp < ops.OP_1) return false;
          if (mOp > ops.OP_16) return false;
          var nOp = script.chunks[script.chunks.length - 2];
          if (nOp === ops.OP_0) return false;
          if (nOp < ops.OP_1) return false;
          if (nOp > ops.OP_16) return false;
          var m = mOp - (ops.OP_1 - 1);
          var n = nOp - (ops.OP_1 - 1);
          if (n < m) return false;
          var pubKeys = script.chunks.slice(1, -2);
          if (n < pubKeys.length) return false;
          return pubKeys.every(isCanonicalPubKey)
        }

        function isNullDataOutput(script) {
          return script.chunks[0] === ops.OP_RETURN
        }

        function classifyOutput(script) {
          enforceType(Script, script);
          if (isPubKeyHashOutput(script)) {
            return "pubkeyhash"
          } else if (isScriptHashOutput(script)) {
            return "scripthash"
          } else if (isMultisigOutput(script)) {
            return "multisig"
          } else if (isPubKeyOutput(script)) {
            return "pubkey"
          } else if (isNullDataOutput(script)) {
            return "nulldata"
          }
          return "nonstandard"
        }

        function classifyInput(script) {
          enforceType(Script, script);
          if (isPubKeyHashInput(script)) {
            return "pubkeyhash"
          } else if (isScriptHashInput(script)) {
            return "scripthash"
          } else if (isMultisigInput(script)) {
            return "multisig"
          } else if (isPubKeyInput(script)) {
            return "pubkey"
          }
          return "nonstandard"
        }

        function pubKeyOutput(pubKey) {
          return Script.fromChunks([pubKey.toBuffer(), ops.OP_CHECKSIG])
        }

        function pubKeyHashOutput(hash) {
          enforceType("Buffer", hash);
          return Script.fromChunks([ops.OP_DUP, ops.OP_HASH160, hash, ops.OP_EQUALVERIFY, ops.OP_CHECKSIG])
        }

        function scriptHashOutput(hash) {
          enforceType("Buffer", hash);
          return Script.fromChunks([ops.OP_HASH160, hash, ops.OP_EQUAL])
        }

        function multisigOutput(m, pubKeys) {
          enforceType("Array", pubKeys);
          assert(pubKeys.length >= m, "Not enough pubKeys provided");
          var pubKeyBuffers = pubKeys.map(function(pubKey) {
            return pubKey.toBuffer()
          });
          var n = pubKeys.length;
          return Script.fromChunks([].concat(ops.OP_1 - 1 + m, pubKeyBuffers, ops.OP_1 - 1 + n, ops.OP_CHECKMULTISIG))
        }

        function pubKeyInput(signature) {
          enforceType("Buffer", signature);
          return Script.fromChunks([signature])
        }

        function pubKeyHashInput(signature, pubKey) {
          enforceType("Buffer", signature);
          return Script.fromChunks([signature, pubKey.toBuffer()])
        }

        function scriptHashInput(scriptSig, scriptPubKey) {
          return Script.fromChunks([].concat(scriptSig.chunks, scriptPubKey.toBuffer()))
        }

        function multisigInput(signatures, scriptPubKey) {
          if (scriptPubKey) {
            assert(isMultisigOutput(scriptPubKey));
            var mOp = scriptPubKey.chunks[0];
            var nOp = scriptPubKey.chunks[scriptPubKey.chunks.length - 2];
            var m = mOp - (ops.OP_1 - 1);
            var n = nOp - (ops.OP_1 - 1);
            assert(signatures.length >= m, "Not enough signatures provided");
            assert(signatures.length <= n, "Too many signatures provided")
          }
          return Script.fromChunks([].concat(ops.OP_0, signatures))
        }

        function nullDataOutput(data) {
          return Script.fromChunks([ops.OP_RETURN, data])
        }
        module.exports = {
          isCanonicalPubKey: isCanonicalPubKey,
          isCanonicalSignature: isCanonicalSignature,
          isPubKeyHashInput: isPubKeyHashInput,
          isPubKeyHashOutput: isPubKeyHashOutput,
          isPubKeyInput: isPubKeyInput,
          isPubKeyOutput: isPubKeyOutput,
          isScriptHashInput: isScriptHashInput,
          isScriptHashOutput: isScriptHashOutput,
          isMultisigInput: isMultisigInput,
          isMultisigOutput: isMultisigOutput,
          isNullDataOutput: isNullDataOutput,
          classifyOutput: classifyOutput,
          classifyInput: classifyInput,
          pubKeyOutput: pubKeyOutput,
          pubKeyHashOutput: pubKeyHashOutput,
          scriptHashOutput: scriptHashOutput,
          multisigOutput: multisigOutput,
          pubKeyInput: pubKeyInput,
          pubKeyHashInput: pubKeyHashInput,
          scriptHashInput: scriptHashInput,
          multisigInput: multisigInput,
          dataOutput: function(data) {
            console.warn("dataOutput is deprecated, use nullDataOutput by 2.0.0");
            return nullDataOutput(data)
          },
          nullDataOutput: nullDataOutput
        }
      }).call(this, require("buffer").Buffer)
    }, {
      "./ecsignature": 166,
      "./opcodes": 171,
      "./script": 172,
      "./types": 176,
      assert: 5,
      buffer: 7,
      ecurve: 155
    }],
    174: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var bufferutils = require("./bufferutils");
        var crypto = require("./crypto");
        var enforceType = require("./types");
        var opcodes = require("./opcodes");
        var scripts = require("./scripts");
        var Address = require("./address");
        var ECSignature = require("./ecsignature");
        var Script = require("./script");

        function Transaction() {
          this.version = 1;
          this.locktime = 0;
          this.ins = [];
          this.outs = []
        }
        Transaction.DEFAULT_SEQUENCE = 4294967295;
        Transaction.SIGHASH_ALL = 1;
        Transaction.SIGHASH_NONE = 2;
        Transaction.SIGHASH_SINGLE = 3;
        Transaction.SIGHASH_ANYONECANPAY = 128;
        Transaction.fromBuffer = function(buffer) {
          var offset = 0;

          function readSlice(n) {
            offset += n;
            return buffer.slice(offset - n, offset)
          }

          function readUInt32() {
            var i = buffer.readUInt32LE(offset);
            offset += 4;
            return i
          }

          function readUInt64() {
            var i = bufferutils.readUInt64LE(buffer, offset);
            offset += 8;
            return i
          }

          function readVarInt() {
            var vi = bufferutils.readVarInt(buffer, offset);
            offset += vi.size;
            return vi.number
          }

          function readScript() {
            return Script.fromBuffer(readSlice(readVarInt()))
          }
          var tx = new Transaction;
          tx.version = readUInt32();
          var vinLen = readVarInt();
          for (var i = 0; i < vinLen; ++i) {
            tx.ins.push({
              hash: readSlice(32),
              index: readUInt32(),
              script: readScript(),
              sequence: readUInt32()
            })
          }
          var voutLen = readVarInt();
          for (i = 0; i < voutLen; ++i) {
            tx.outs.push({
              value: readUInt64(),
              script: readScript()
            })
          }
          tx.locktime = readUInt32();
          assert.equal(offset, buffer.length, "Transaction has unexpected data");
          return tx
        };
        Transaction.fromHex = function(hex) {
          return Transaction.fromBuffer(new Buffer(hex, "hex"))
        };
        Transaction.prototype.addInput = function(hash, index, sequence, script) {
          if (sequence === undefined) sequence = Transaction.DEFAULT_SEQUENCE;
          script = script || Script.EMPTY;
          if (typeof hash === "string") {
            hash = bufferutils.reverse(new Buffer(hash, "hex"))
          } else if (hash instanceof Transaction) {
            hash = hash.getHash()
          }
          enforceType("Buffer", hash);
          enforceType("Number", index);
          enforceType("Number", sequence);
          enforceType(Script, script);
          assert.equal(hash.length, 32, "Expected hash length of 32, got " + hash.length);
          return this.ins.push({
                hash: hash,
                index: index,
                script: script,
                sequence: sequence
              }) - 1
        };
        Transaction.prototype.addOutput = function(scriptPubKey, value) {
          if (typeof scriptPubKey === "string") {
            scriptPubKey = Address.fromBase58Check(scriptPubKey)
          }
          if (scriptPubKey instanceof Address) {
            scriptPubKey = scriptPubKey.toOutputScript()
          }
          enforceType(Script, scriptPubKey);
          enforceType("Number", value);
          return this.outs.push({
                script: scriptPubKey,
                value: value
              }) - 1
        };
        Transaction.prototype.clone = function() {
          var newTx = new Transaction;
          newTx.version = this.version;
          newTx.locktime = this.locktime;
          newTx.ins = this.ins.map(function(txIn) {
            return {
              hash: txIn.hash,
              index: txIn.index,
              script: txIn.script,
              sequence: txIn.sequence
            }
          });
          newTx.outs = this.outs.map(function(txOut) {
            return {
              script: txOut.script,
              value: txOut.value
            }
          });
          return newTx
        };
        Transaction.prototype.hashForSignature = function(inIndex, prevOutScript, hashType) {
          if (arguments[0] instanceof Script) {
            console.warn("hashForSignature(prevOutScript, inIndex, ...) has been deprecated. Use hashForSignature(inIndex, prevOutScript, ...)");
            var tmp = arguments[0];
            inIndex = arguments[1];
            prevOutScript = tmp
          }
          enforceType("Number", inIndex);
          enforceType(Script, prevOutScript);
          enforceType("Number", hashType);
          assert(inIndex >= 0, "Invalid vin index");
          assert(inIndex < this.ins.length, "Invalid vin index");
          var txTmp = this.clone();
          var hashScript = prevOutScript.without(opcodes.OP_CODESEPARATOR);
          txTmp.ins.forEach(function(txIn) {
            txIn.script = Script.EMPTY
          });
          txTmp.ins[inIndex].script = hashScript;
          var hashTypeModifier = hashType & 31;
          if (hashTypeModifier === Transaction.SIGHASH_NONE) {
            assert(false, "SIGHASH_NONE not yet supported")
          } else if (hashTypeModifier === Transaction.SIGHASH_SINGLE) {
            assert(false, "SIGHASH_SINGLE not yet supported")
          }
          if (hashType & Transaction.SIGHASH_ANYONECANPAY) {
            assert(false, "SIGHASH_ANYONECANPAY not yet supported")
          }
          var hashTypeBuffer = new Buffer(4);
          hashTypeBuffer.writeInt32LE(hashType, 0);
          var buffer = Buffer.concat([txTmp.toBuffer(), hashTypeBuffer]);
          return crypto.hash256(buffer)
        };
        Transaction.prototype.getHash = function() {
          return crypto.hash256(this.toBuffer())
        };
        Transaction.prototype.getId = function() {
          return bufferutils.reverse(this.getHash()).toString("hex")
        };
        Transaction.prototype.toBuffer = function() {
          var txInSize = this.ins.reduce(function(a, x) {
            return a + (40 + bufferutils.varIntSize(x.script.buffer.length) + x.script.buffer.length)
          }, 0);
          var txOutSize = this.outs.reduce(function(a, x) {
            return a + (8 + bufferutils.varIntSize(x.script.buffer.length) + x.script.buffer.length)
          }, 0);
          var buffer = new Buffer(8 + bufferutils.varIntSize(this.ins.length) + bufferutils.varIntSize(this.outs.length) + txInSize + txOutSize);
          var offset = 0;

          function writeSlice(slice) {
            slice.copy(buffer, offset);
            offset += slice.length
          }

          function writeUInt32(i) {
            buffer.writeUInt32LE(i, offset);
            offset += 4
          }

          function writeUInt64(i) {
            bufferutils.writeUInt64LE(buffer, i, offset);
            offset += 8
          }

          function writeVarInt(i) {
            var n = bufferutils.writeVarInt(buffer, i, offset);
            offset += n
          }
          writeUInt32(this.version);
          writeVarInt(this.ins.length);
          this.ins.forEach(function(txIn) {
            writeSlice(txIn.hash);
            writeUInt32(txIn.index);
            writeVarInt(txIn.script.buffer.length);
            writeSlice(txIn.script.buffer);
            writeUInt32(txIn.sequence)
          });
          writeVarInt(this.outs.length);
          this.outs.forEach(function(txOut) {
            writeUInt64(txOut.value);
            writeVarInt(txOut.script.buffer.length);
            writeSlice(txOut.script.buffer)
          });
          writeUInt32(this.locktime);
          return buffer
        };
        Transaction.prototype.toHex = function() {
          return this.toBuffer().toString("hex")
        };
        Transaction.prototype.setInputScript = function(index, script) {
          this.ins[index].script = script
        };
        Transaction.prototype.sign = function(index, privKey, hashType) {
          console.warn("Transaction.prototype.sign is deprecated.  Use TransactionBuilder instead.");
          var prevOutScript = privKey.pub.getAddress().toOutputScript();
          var signature = this.signInput(index, prevOutScript, privKey, hashType);
          var scriptSig = scripts.pubKeyHashInput(signature, privKey.pub);
          this.setInputScript(index, scriptSig)
        };
        Transaction.prototype.signInput = function(index, prevOutScript, privKey, hashType) {
          console.warn("Transaction.prototype.signInput is deprecated.  Use TransactionBuilder instead.");
          hashType = hashType || Transaction.SIGHASH_ALL;
          var hash = this.hashForSignature(index, prevOutScript, hashType);
          var signature = privKey.sign(hash);
          return signature.toScriptSignature(hashType)
        };
        Transaction.prototype.validateInput = function(index, prevOutScript, pubKey, buffer) {
          console.warn("Transaction.prototype.validateInput is deprecated.  Use TransactionBuilder instead.");
          var parsed = ECSignature.parseScriptSignature(buffer);
          var hash = this.hashForSignature(index, prevOutScript, parsed.hashType);
          return pubKey.verify(hash, parsed.signature)
        };
        module.exports = Transaction
      }).call(this, require("buffer").Buffer)
    }, {
      "./address": 158,
      "./bufferutils": 161,
      "./crypto": 162,
      "./ecsignature": 166,
      "./opcodes": 171,
      "./script": 172,
      "./scripts": 173,
      "./types": 176,
      assert: 5,
      buffer: 7
    }],
    175: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var scripts = require("./scripts");
        var ECPubKey = require("./ecpubkey");
        var ECSignature = require("./ecsignature");
        var Script = require("./script");
        var Transaction = require("./transaction");

        function TransactionBuilder() {
          this.prevOutMap = {};
          this.prevOutScripts = {};
          this.prevOutTypes = {};
          this.signatures = [];
          this.tx = new Transaction
        }
        TransactionBuilder.fromTransaction = function(transaction) {
          var txb = new TransactionBuilder;
          transaction.ins.forEach(function(txIn) {
            txb.addInput(txIn.hash, txIn.index, txIn.sequence)
          });
          transaction.outs.forEach(function(txOut) {
            txb.addOutput(txOut.script, txOut.value)
          });
          transaction.ins.forEach(function(txIn, i) {
            if (txIn.script.buffer.length === 0) return;
            assert(!Array.prototype.every.call(txIn.hash, function(x) {
              return x === 0
            }), "coinbase inputs not supported");
            var redeemScript;
            var scriptSig = txIn.script;
            var scriptType = scripts.classifyInput(scriptSig);
            if (scriptType === "scripthash") {
              redeemScript = Script.fromBuffer(scriptSig.chunks.slice(-1)[0]);
              scriptSig = Script.fromChunks(scriptSig.chunks.slice(0, -1));
              scriptType = scripts.classifyInput(scriptSig);
              assert.equal(scripts.classifyOutput(redeemScript), scriptType, "Non-matching scriptSig and scriptPubKey in input")
            }
            var hashType, pubKeys, signatures;
            switch (scriptType) {
              case "pubkeyhash":
                var parsed = ECSignature.parseScriptSignature(scriptSig.chunks[0]);
                var pubKey = ECPubKey.fromBuffer(scriptSig.chunks[1]);
                hashType = parsed.hashType;
                pubKeys = [pubKey];
                signatures = [parsed.signature];
                break;
              case "multisig":
                var scriptSigs = scriptSig.chunks.slice(1);
                var parsed = scriptSigs.map(function(scriptSig) {
                  return ECSignature.parseScriptSignature(scriptSig)
                });
                hashType = parsed[0].hashType;
                pubKeys = [];
                signatures = parsed.map(function(p) {
                  return p.signature
                });
                break;
              case "pubkey":
                var parsed = ECSignature.parseScriptSignature(scriptSig.chunks[0]);
                hashType = parsed.hashType;
                pubKeys = [];
                signatures = [parsed.signature];
                break;
              default:
                assert(false, scriptType + " inputs not supported")
            }
            txb.signatures[i] = {
              hashType: hashType,
              pubKeys: pubKeys,
              redeemScript: redeemScript,
              scriptType: scriptType,
              signatures: signatures
            }
          });
          return txb
        };
        TransactionBuilder.prototype.addInput = function(prevTx, index, sequence, prevOutScript) {
          var prevOutHash;
          if (typeof prevTx === "string") {
            prevOutHash = new Buffer(prevTx, "hex");
            Array.prototype.reverse.call(prevOutHash)
          } else if (prevTx instanceof Transaction) {
            prevOutHash = prevTx.getHash();
            prevOutScript = prevTx.outs[index].script
          } else {
            prevOutHash = prevTx
          }
          var prevOutType;
          if (prevOutScript !== undefined) {
            prevOutType = scripts.classifyOutput(prevOutScript);
            assert.notEqual(prevOutType, "nonstandard", "PrevOutScript not supported (nonstandard)")
          }
          assert(this.signatures.every(function(input) {
            return input.hashType & Transaction.SIGHASH_ANYONECANPAY
          }), "No, this would invalidate signatures");
          var prevOut = prevOutHash.toString("hex") + ":" + index;
          assert(!(prevOut in this.prevOutMap), "Transaction is already an input");
          var vout = this.tx.addInput(prevOutHash, index, sequence);
          this.prevOutMap[prevOut] = true;
          this.prevOutScripts[vout] = prevOutScript;
          this.prevOutTypes[vout] = prevOutType;
          return vout
        };
        TransactionBuilder.prototype.addOutput = function(scriptPubKey, value) {
          assert(this.signatures.every(function(signature) {
            return (signature.hashType & 31) === Transaction.SIGHASH_SINGLE
          }), "No, this would invalidate signatures");
          return this.tx.addOutput(scriptPubKey, value)
        };
        TransactionBuilder.prototype.build = function() {
          return this.__build(false)
        };
        TransactionBuilder.prototype.buildIncomplete = function() {
          return this.__build(true)
        };
        TransactionBuilder.prototype.__build = function(allowIncomplete) {
          if (!allowIncomplete) {
            assert(this.tx.ins.length > 0, "Transaction has no inputs");
            assert(this.tx.outs.length > 0, "Transaction has no outputs");
            assert(this.signatures.length > 0, "Transaction has no signatures");
            assert.equal(this.signatures.length, this.tx.ins.length, "Transaction is missing signatures")
          }
          var tx = this.tx.clone();
          this.signatures.forEach(function(input, index) {
            var scriptSig;
            var scriptType = input.scriptType;
            var signatures = input.signatures.map(function(signature) {
              return signature.toScriptSignature(input.hashType)
            });
            switch (scriptType) {
              case "pubkeyhash":
                var signature = signatures[0];
                var pubKey = input.pubKeys[0];
                scriptSig = scripts.pubKeyHashInput(signature, pubKey);
                break;
              case "multisig":
                var redeemScript = allowIncomplete ? undefined : input.redeemScript;
                scriptSig = scripts.multisigInput(signatures, redeemScript);
                break;
              case "pubkey":
                var signature = signatures[0];
                scriptSig = scripts.pubKeyInput(signature);
                break;
              default:
                assert(false, scriptType + " not supported")
            }
            if (input.redeemScript) {
              scriptSig = scripts.scriptHashInput(scriptSig, input.redeemScript)
            }
            tx.setInputScript(index, scriptSig)
          });
          return tx
        };
        TransactionBuilder.prototype.sign = function(index, privKey, redeemScript, hashType) {
          assert(this.tx.ins.length >= index, "No input at index: " + index);
          hashType = hashType || Transaction.SIGHASH_ALL;
          var prevOutScript = this.prevOutScripts[index];
          var prevOutType = this.prevOutTypes[index];
          var scriptType, hash;
          if (redeemScript) {
            prevOutScript = prevOutScript || scripts.scriptHashOutput(redeemScript.getHash());
            prevOutType = prevOutType || "scripthash";
            assert.equal(prevOutType, "scripthash", "PrevOutScript must be P2SH");
            scriptType = scripts.classifyOutput(redeemScript);
            assert.notEqual(scriptType, "scripthash", "RedeemScript can't be P2SH");
            assert.notEqual(scriptType, "nonstandard", "RedeemScript not supported (nonstandard)");
            hash = this.tx.hashForSignature(index, redeemScript, hashType)
          } else {
            prevOutScript = prevOutScript || privKey.pub.getAddress().toOutputScript();
            prevOutType = prevOutType || "pubkeyhash";
            assert.notEqual(prevOutType, "scripthash", "PrevOutScript is P2SH, missing redeemScript");
            scriptType = prevOutType;
            hash = this.tx.hashForSignature(index, prevOutScript, hashType)
          }
          this.prevOutScripts[index] = prevOutScript;
          this.prevOutTypes[index] = prevOutType;
          if (!(index in this.signatures)) {
            this.signatures[index] = {
              hashType: hashType,
              pubKeys: [],
              redeemScript: redeemScript,
              scriptType: scriptType,
              signatures: []
            }
          } else {
            assert.equal(scriptType, "multisig", scriptType + " doesn't support multiple signatures")
          }
          var input = this.signatures[index];
          assert.equal(input.hashType, hashType, "Inconsistent hashType");
          assert.deepEqual(input.redeemScript, redeemScript, "Inconsistent redeemScript");
          var signature = privKey.sign(hash);
          input.pubKeys.push(privKey.pub);
          input.signatures.push(signature)
        };
        module.exports = TransactionBuilder
      }).call(this, require("buffer").Buffer)
    }, {
      "./ecpubkey": 165,
      "./ecsignature": 166,
      "./script": 172,
      "./scripts": 173,
      "./transaction": 174,
      assert: 5,
      buffer: 7
    }],
    176: [function(require, module, exports) {
      (function(Buffer) {
        module.exports = function enforce(type, value) {
          switch (type) {
            case "Array":
            {
              if (Array.isArray(value)) return;
              break
            }
            case "Boolean":
            {
              if (typeof value === "boolean") return;
              break
            }
            case "Buffer":
            {
              if (Buffer.isBuffer(value)) return;
              break
            }
            case "Number":
            {
              if (typeof value === "number") return;
              break
            }
            case "String":
            {
              if (typeof value === "string") return;
              break
            }
            default:
            {
              if (getName(value.constructor) === getName(type)) return
            }
          }
          throw new TypeError("Expected " + (getName(type) || type) + ", got " + value)
        };

        function getName(fn) {
          var match = fn.toString().match(/function (.*?)\(/);
          return match ? match[1] : null
        }
      }).call(this, require("buffer").Buffer)
    }, {
      buffer: 7
    }],
    177: [function(require, module, exports) {
      (function(Buffer) {
        var assert = require("assert");
        var bufferutils = require("./bufferutils");
        var crypto = require("crypto");
        var enforceType = require("./types");
        var networks = require("./networks");
        var Address = require("./address");
        var HDNode = require("./hdnode");
        var TransactionBuilder = require("./transaction_builder");
        var Script = require("./script");

        function Wallet(seed, network) {
          console.warn("Wallet is deprecated and will be removed in 2.0.0, see #296");
          seed = seed || crypto.randomBytes(32);
          network = network || networks.bitcoin;
          var masterKey = HDNode.fromSeedBuffer(seed, network);
          var accountZero = masterKey.deriveHardened(0);
          var externalAccount = accountZero.derive(0);
          var internalAccount = accountZero.derive(1);
          this.addresses = [];
          this.changeAddresses = [];
          this.network = network;
          this.unspents = [];
          this.unspentMap = {};
          var me = this;
          this.newMasterKey = function(seed) {
            console.warn("newMasterKey is deprecated, please make a new Wallet instance instead");
            seed = seed || crypto.randomBytes(32);
            masterKey = HDNode.fromSeedBuffer(seed, network);
            accountZero = masterKey.deriveHardened(0);
            externalAccount = accountZero.derive(0);
            internalAccount = accountZero.derive(1);
            me.addresses = [];
            me.changeAddresses = [];
            me.unspents = [];
            me.unspentMap = {}
          };
          this.getMasterKey = function() {
            return masterKey
          };
          this.getAccountZero = function() {
            return accountZero
          };
          this.getExternalAccount = function() {
            return externalAccount
          };
          this.getInternalAccount = function() {
            return internalAccount
          }
        }
        Wallet.prototype.createTransaction = function(to, value, options) {
          if (typeof options !== "object") {
            if (options !== undefined) {
              console.warn("Non options object parameters are deprecated, use options object instead");
              options = {
                fixedFee: arguments[2],
                changeAddress: arguments[3]
              }
            }
          }
          options = options || {};
          assert(value > this.network.dustThreshold, value + " must be above dust threshold (" + this.network.dustThreshold + " Satoshis)");
          var changeAddress = options.changeAddress;
          var fixedFee = options.fixedFee;
          var minConf = options.minConf === undefined ? 0 : options.minConf;
          var unspents = this.unspents.filter(function(unspent) {
            return unspent.confirmations >= minConf
          }).filter(function(unspent) {
            return !unspent.pending
          }).sort(function(o1, o2) {
            return o2.value - o1.value
          });
          var accum = 0;
          var addresses = [];
          var subTotal = value;
          var txb = new TransactionBuilder;
          txb.addOutput(to, value);
          for (var i = 0; i < unspents.length; ++i) {
            var unspent = unspents[i];
            addresses.push(unspent.address);
            txb.addInput(unspent.txHash, unspent.index);
            var fee = fixedFee === undefined ? estimatePaddedFee(txb.buildIncomplete(), this.network) : fixedFee;
            accum += unspent.value;
            subTotal = value + fee;
            if (accum >= subTotal) {
              var change = accum - subTotal;
              if (change > this.network.dustThreshold) {
                txb.addOutput(changeAddress || this.getChangeAddress(), change)
              }
              break
            }
          }
          assert(accum >= subTotal, "Not enough funds (incl. fee): " + accum + " < " + subTotal);
          return this.signWith(txb, addresses).build()
        };
        Wallet.prototype.processPendingTx = function(tx) {
          this.__processTx(tx, true)
        };
        Wallet.prototype.processConfirmedTx = function(tx) {
          this.__processTx(tx, false)
        };
        Wallet.prototype.__processTx = function(tx, isPending) {
          console.warn("processTransaction is considered harmful, see issue #260 for more information");
          var txId = tx.getId();
          var txHash = tx.getHash();
          tx.outs.forEach(function(txOut, i) {
            var address;
            try {
              address = Address.fromOutputScript(txOut.script, this.network).toString()
            } catch (e) {
              if (!e.message.match(/has no matching Address/)) throw e
            }
            var myAddresses = this.addresses.concat(this.changeAddresses);
            if (myAddresses.indexOf(address) > -1) {
              var lookup = txId + ":" + i;
              if (lookup in this.unspentMap) return;
              var unspent = {
                address: address,
                confirmations: 0,
                index: i,
                txHash: txHash,
                txId: txId,
                value: txOut.value,
                pending: isPending
              };
              this.unspentMap[lookup] = unspent;
              this.unspents.push(unspent)
            }
          }, this);
          tx.ins.forEach(function(txIn, i) {
            var txInId = bufferutils.reverse(txIn.hash).toString("hex");
            var lookup = txInId + ":" + txIn.index;
            if (!(lookup in this.unspentMap)) return;
            var unspent = this.unspentMap[lookup];
            if (isPending) {
              unspent.pending = true;
              unspent.spent = true
            } else {
              delete this.unspentMap[lookup];
              this.unspents = this.unspents.filter(function(unspent2) {
                return unspent !== unspent2
              })
            }
          }, this)
        };
        Wallet.prototype.generateAddress = function() {
          var k = this.addresses.length;
          var address = this.getExternalAccount().derive(k).getAddress();
          this.addresses.push(address.toString());
          return this.getReceiveAddress()
        };
        Wallet.prototype.generateChangeAddress = function() {
          var k = this.changeAddresses.length;
          var address = this.getInternalAccount().derive(k).getAddress();
          this.changeAddresses.push(address.toString());
          return this.getChangeAddress()
        };
        Wallet.prototype.getAddress = function() {
          if (this.addresses.length === 0) {
            this.generateAddress()
          }
          return this.addresses[this.addresses.length - 1]
        };
        Wallet.prototype.getBalance = function(minConf) {
          minConf = minConf || 0;
          return this.unspents.filter(function(unspent) {
            return unspent.confirmations >= minConf
          }).filter(function(unspent) {
            return !unspent.spent
          }).reduce(function(accum, unspent) {
            return accum + unspent.value
          }, 0)
        };
        Wallet.prototype.getChangeAddress = function() {
          if (this.changeAddresses.length === 0) {
            this.generateChangeAddress()
          }
          return this.changeAddresses[this.changeAddresses.length - 1]
        };
        Wallet.prototype.getInternalPrivateKey = function(index) {
          return this.getInternalAccount().derive(index).privKey
        };
        Wallet.prototype.getPrivateKey = function(index) {
          return this.getExternalAccount().derive(index).privKey
        };
        Wallet.prototype.getPrivateKeyForAddress = function(address) {
          var index;
          if ((index = this.addresses.indexOf(address)) > -1) {
            return this.getPrivateKey(index)
          }
          if ((index = this.changeAddresses.indexOf(address)) > -1) {
            return this.getInternalPrivateKey(index)
          }
          assert(false, "Unknown address. Make sure the address is from the keychain and has been generated")
        };
        Wallet.prototype.getUnspentOutputs = function(minConf) {
          minConf = minConf || 0;
          return this.unspents.filter(function(unspent) {
            return unspent.confirmations >= minConf
          }).filter(function(unspent) {
            return !unspent.spent
          }).map(function(unspent) {
            return {
              address: unspent.address,
              confirmations: unspent.confirmations,
              index: unspent.index,
              txId: unspent.txId,
              value: unspent.value,
              hash: unspent.txId,
              pending: unspent.pending
            }
          })
        };
        Wallet.prototype.setUnspentOutputs = function(unspents) {
          this.unspentMap = {};
          this.unspents = unspents.map(function(unspent) {
            var txId = unspent.txId || unspent.hash;
            var index = unspent.index;
            if (unspent.hash !== undefined) {
              console.warn("unspent.hash is deprecated, use unspent.txId instead")
            }
            if (index === undefined) {
              console.warn("unspent.outputIndex is deprecated, use unspent.index instead");
              index = unspent.outputIndex
            }
            enforceType("String", txId);
            enforceType("Number", index);
            enforceType("Number", unspent.value);
            assert.equal(txId.length, 64, "Expected valid txId, got " + txId);
            assert.doesNotThrow(function() {
              Address.fromBase58Check(unspent.address)
            }, "Expected Base58 Address, got " + unspent.address);
            assert(isFinite(index), "Expected finite index, got " + index);
            if (unspent.confirmations !== undefined) {
              enforceType("Number", unspent.confirmations)
            }
            var txHash = bufferutils.reverse(new Buffer(txId, "hex"));
            unspent = {
              address: unspent.address,
              confirmations: unspent.confirmations || 0,
              index: index,
              txHash: txHash,
              txId: txId,
              value: unspent.value,
              pending: unspent.pending || false
            };
            this.unspentMap[txId + ":" + index] = unspent;
            return unspent
          }, this)
        };
        Wallet.prototype.signWith = function(tx, addresses) {
          addresses.forEach(function(address, i) {
            var privKey = this.getPrivateKeyForAddress(address);
            tx.sign(i, privKey)
          }, this);
          return tx
        };

        function estimatePaddedFee(tx, network) {
          var tmpTx = tx.clone();
          tmpTx.addOutput(Script.EMPTY, network.dustSoftThreshold || 0);
          return network.estimateFee(tmpTx)
        }
        Wallet.prototype.getReceiveAddress = Wallet.prototype.getAddress;
        Wallet.prototype.createTx = Wallet.prototype.createTransaction;
        module.exports = Wallet
      }).call(this, require("buffer").Buffer)
    }, {
      "./address": 158,
      "./bufferutils": 161,
      "./hdnode": 167,
      "./networks": 170,
      "./script": 172,
      "./transaction_builder": 175,
      "./types": 176,
      assert: 5,
      buffer: 7,
      crypto: 37
    }]
  }, {}, [168])(168)
});