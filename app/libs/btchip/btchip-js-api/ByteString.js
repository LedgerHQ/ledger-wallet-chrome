/*
************************************************************************
Copyright (c) 2012-2014 UBINITY SAS

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

var ByteString = Class.create({
	/** @lends ByteString.prototype */
	
	/**
	 * @class GPScript ByteString implementation
	 * @param {String} value initial value
	 * @param {HEX|ASCII} encoding encoding to use
	 * @property {Number} length length of the ByteString
	 * @constructs
	 */
	initialize: function(value, encoding) {
		this.encoding = encoding;
		switch(encoding) {
			case HEX:
				this.value = Convert.hexToBin(value);
				break;
			
			case ASCII:
				this.value = value;
				break;
				
			default:
				throw "Invalid arguments"; 
		}
		this.length = this.value.length;
	},

	/**
	 * Retrieve the byte value at the given index
	 * @param {Number} index index
	 * @returns {Number} byte value
	 */
	byteAt : function(index) {
		if (arguments.length < 1) {
			throw "Argument missing";
		}		
		if (typeof index != "number") {
			throw "Invalid index";
		}		
		if ((index < 0) || (index >= this.value.length)) {
			throw "Invalid index offset";
		}
		return Convert.readHexDigit(Convert.stringToHex(this.value.substring(index, index + 1)));
	},
	
	/**
	 * Retrieve a subset of the ByteString
	 * @param {Number} offset offset to start at
	 * @param {Number} [count] size of the target ByteString (default : use the remaining length)
	 * @returns {ByteString} subset of the original ByteString 
	 */
	bytes : function(offset, count) {
		var result;
		if (arguments.length < 1) {
			throw "Argument missing";
		}
		if (typeof offset != "number") {
			throw "Invalid offset";
		}
		//if ((offset < 0) || (offset >= this.value.length)) {
		if (offset < 0) {
			throw "Invalid offset";
		}
		if (typeof count == "number") {
			if (count < 0) {
				throw "Invalid count";
			}
			result = new ByteString(this.value.substring(offset, offset + count), ASCII);
		}
		else 
		if (typeof count == "undefined") {
			result = new ByteString(this.value.substring(offset), ASCII);
		}
		else {
			throw "Invalid count";
		}
		result.encoding = this.encoding;
		return result;
	},

	/**
	 * Appends two ByteString
	 * @param {ByteString} target ByteString to append
	 * @returns {ByteString} result of the concatenation
	 */
	concat : function(target) {
		if (arguments.length < 1) {
			throw "Not enough arguments";
		}		
		if (!(target instanceof ByteString)) {
			throw "Invalid argument";
		}
		var result = this.value + target.value;
		var x = new ByteString(result, ASCII);
		x.encoding = this.encoding;
		return x;		
	},
	
	/**
	 * Check if two ByteString are equal
	 * @param {ByteString} target ByteString to check against
	 * @returns {Boolean} true if the two ByteString are equal
	 */
	equals : function(target) {
		if (arguments.length < 1) {
			throw "Not enough arguments";
		}		
		if (!(target instanceof ByteString)) {
			throw "Invalid argument";
		}
		return (this.value == target.value);
	},
	
	
	/**
	 * Convert the ByteString to a String using the given encoding
	 * @param {HEX|ASCII|UTF8|BASE64|CN} encoding encoding to use
	 * @return {String} converted content
	 */
	toString: function(encoding) {
		var targetEncoding = this.encoding;
		if (arguments.length >= 1) {
			if (typeof encoding != "number") {
				throw "Invalid encoding";
			}
			switch(encoding) {
				case HEX:
				case ASCII:
					targetEncoding = encoding;
					break;
				
				default:
					throw "Unsupported arguments";
			}
			targetEncoding = encoding;
		}
		switch(targetEncoding) {
			case HEX:
				return Convert.stringToHex(this.value);
			case ASCII:
				return this.value;
			default:
				throw "Unsupported";
		}		
	},
	
	toStringIE: function(encoding) {
		var targetEncoding = this.encoding;
		if (arguments.length >= 1) {
			if (typeof encoding != "number") {
				throw "Invalid encoding";
			}
			switch(encoding) {
				case HEX:
				case ASCII:
					targetEncoding = encoding;
					break;
				
				default:
					throw "Unsupported";
			}
			targetEncoding = encoding;
		}
		switch(targetEncoding) {
			case HEX:
				return Convert.stringToHex(this.value);
			case ASCII:
				return this.value;
			default:
				throw "Unsupported";
		}				
	},
	
});

/**
 * CRC XOR algorithm
 */
ByteString.XOR = 1;
