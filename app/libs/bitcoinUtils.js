(function () {

  /**
   * Create a byte array representing a number with the given length
   */
  ledger.bitcoin.numToBytes = function (num, bytes) {
    if (bytes === undefined) bytes = 8
    if (bytes === 0) return []
    return [num % 256].concat(ledger.bitcoin.numToBytes(Math.floor(num / 256), bytes - 1))
  }

  /**
   * Convert a byte array to the number that it represents
   */
  ledger.bitcoin.bytesToNum = function (bytes) {
    if (bytes.length === 0) return 0
    return bytes[0] + 256 * ledger.bitcoin.bytesToNum(bytes.slice(1))
  }

  /**
   * Turn an integer into a "var_int".
   *
   * "var_int" is a variable length integer used by Bitcoin's binary format.
   *
   * Returns a byte array.
   */
  function numToVarInt(num) {
    if (num < 253) return [num]
    if (num < 65536) return [253].concat(numToBytes(num, 2))
    if (num < 4294967296) return [254].concat(numToBytes(num, 4))
    return [255].concat(numToBytes(num, 8))
  }

  /**
   * Turn an VarInt into an integer
   *
   * "var_int" is a variable length integer used by Bitcoin's binary format.
   *
   * Returns { bytes: bytesUsed, number: theNumber }
   */
  function varIntToNum(bytes) {
    var prefix = bytes[0]

    var viBytes =
        prefix < 253   ? bytes.slice(0, 1)
      : prefix === 253 ? bytes.slice(1, 3)
      : prefix === 254 ? bytes.slice(1, 5)
      : bytes.slice(1, 9)

    return {
      bytes: prefix < 253 ? viBytes : bytes.slice(0, viBytes.length + 1),
      number: bytesToNum(viBytes)
    }
  }

  function bytesToWords(bytes) {
    var words = []
    for (var i = 0, b = 0; i < bytes.length; i++, b += 8) {
      words[b >>> 5] |= bytes[i] << (24 - b % 32)
    }
    return words
  }

  function wordsToBytes(words) {
    var bytes = []
    for (var b = 0; b < words.length * 32; b += 8) {
      bytes.push((words[b >>> 5] >>> (24 - b % 32)) & 0xFF)
    }
    return bytes
  }

  function bytesToWordArray(bytes) {
    return new WordArray.init(bytesToWords(bytes), bytes.length)
  }

  function wordArrayToBytes(wordArray) {
    return wordsToBytes(wordArray.words)
  }

  function reverseEndian (hex) {
    return bytesToHex(hexToBytes(hex).reverse())
  }

})()