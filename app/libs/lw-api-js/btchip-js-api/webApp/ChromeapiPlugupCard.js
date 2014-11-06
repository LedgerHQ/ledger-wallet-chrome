/*
************************************************************************
Copyright (c) 2013-2014 UBINITY SAS

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

var ChromeapiPlugupCard = Class.extend(Card, {
	/** @lends ChromeapiPlugupCard.prototype */
	
	/**
	 *  @class In browser implementation of the {@link Card} interface using the Chrome API
	 *  @param {PPACardTerminal} terminal Terminal linked to this card
	 *  @param {Object} device device reference returned by the factory
	 *  @param {Number} [timeout] optional exchange timeout
	 *  @constructs
	 *  @augments Card
	 */
	initialize:function(terminal, device, timeout) {		
		if (typeof timeout == "undefined") {
			timeout = 0;
		}
		this.winusb = (device['transport'] == 'winusb');
		this.device = new bridgedDevice(device);
		this.terminal = terminal;
		this.timeout = timeout;
		this.exchangeStack = [];
	},
	
	connect_async:function() {
		var currentObject = this;
		return this.device.open_async().then(function(result) {
			currentObject.connection = true;
			return currentObject;
		});
	},
	
	getTerminal : function() {
		return this.terminal;
	},
	
	getAtr : function() {
		return new ByteString("", HEX);
	},
	
	beginExclusive : function() {
	},
	
	endExclusive : function() {
	},
	
	openLogicalChannel: function(channel) {
		throw "Not supported";
	},

	exchange_async : function(apdu, returnLength) {
		var currentObject = this;
		if (!(apdu instanceof ByteString)) {
			throw "Invalid parameter";
		}
		if (!this.connection) {
			throw "Connection is not open";
		}

		var deferred = Q.defer();
		var exchangeTimeout;
		deferred.promise.apdu = apdu;
		deferred.promise.returnLength = returnLength;

		if (this.timeout != 0) {
			exchangeTimeout = setTimeout(function() {
				debug("timeout");
				deferred.reject("timeout");
			}, this.timeout);
		}
                
		// enter the exchange wait list
		currentObject.exchangeStack.push(deferred);
                
		if (currentObject.exchangeStack.length == 1) {
			var processNextExchange = function() {
                    
				// don't pop it now, to avoid multiple at once
				var deferred = currentObject.exchangeStack[0];
                    
				// notify graphical listener
				if (typeof currentObject.listener != "undefined") {
					currentObject.listener.begin();
				}
                
				var performExchange = function() {
					if (currentObject.winusb) {
						return currentObject.device.send_async(deferred.promise.apdu.toString(HEX)).then(
							function(result) {                      
								return currentObject.device.recv_async(512);
							});
					}
					else {
						var deferredHidSend = Q.defer();
						var offsetSent = 0;
						var firstReceived = true;
						var toReceive = 0;

						var received = new ByteString("", HEX);
						var sendPart = function() {
							if (offsetSent == deferred.promise.apdu.length) {
								return receivePart();
							}
							var blockSize = (deferred.promise.apdu.length - offsetSent > 64 ? 64 : deferred.promise.apdu.length - offsetSent);
							var block = deferred.promise.apdu.bytes(offsetSent, blockSize);
							var padding = "";
							for (var i=0; i<64 - block.length; i++) {
								padding += "00";
							}
							if (padding.length != 0) {
								block = block.concat(new ByteString(padding, HEX));
							}
							return currentObject.device.send_async(block.toString(HEX)).then(
								function(result) {
									offsetSent += blockSize;
									return sendPart();
								}
							).fail(function(error) {
								deferredHidSend.reject(error);
							});
						}
						var receivePart = function() {
							return currentObject.device.recv_async(64).then(function(result) {
								received = received.concat(new ByteString(result.data, HEX));
								if (firstReceived) {
									firstReceived = false;
									if ((received.length == 2) || (received.byteAt(0) != 0x61)) {
										deferredHidSend.resolve({resultCode:0, data:received.toString(HEX)});									
									}
									else {									
										toReceive = received.byteAt(1);
										if (toReceive == 0) {
											toReceive == 256;
										}
										toReceive += 2;
									}								
								}
								if (toReceive < 64) {
									deferredHidSend.resolve({resultCode:0, data:received.toString(HEX)});									
								}
								else {
									toReceive -= 64;
									return receivePart();
								}
							}).fail(function(error) {
								deferredHidSend.reject(error);
							});
						}
						sendPart();
						return deferredHidSend.promise;
					}
				}
				performExchange().then(function(result) {
					var resultBin = new ByteString(result.data, HEX);
					if (resultBin.length == 2 || resultBin.byteAt(0) != 0x61) {
						deferred.promise.SW1 = resultBin.byteAt(0);
						deferred.promise.SW2 = resultBin.byteAt(1);
						deferred.promise.response = new ByteString("", HEX);
					}
					else {
						var size = resultBin.byteAt(1);
						// fake T0 
						if (size == 0) { size = 256; }
						deferred.promise.response = resultBin.bytes(2, size);
						deferred.promise.SW1 = resultBin.byteAt(2 + size);
						deferred.promise.SW2 = resultBin.byteAt(2 + size + 1);
					}
					deferred.promise.SW = ((deferred.promise.SW1 << 8) + (deferred.promise.SW2));
					currentObject.SW1 = deferred.promise.SW1;
					currentObject.SW2 = deferred.promise.SW2;
					currentObject.SW = deferred.promise.SW;
					if (typeof currentObject.logger != "undefined") {
						currentObject.logger.log(currentObject.terminal.getName(), 0, deferred.promise.apdu, deferred.promise.response, deferred.promise.SW);
					}
					// build the response
					if (this.timeout != 0) {
						clearTimeout(exchangeTimeout);
					}
					deferred.resolve(deferred.promise.response);
				})
				.fail(function(err) { 
					if (this.timeout != 0) {
						clearTimeout(exchangeTimeout);
					}					
					deferred.reject(err);
				})
				.finally(function () { 
					// notify graphical listener
					if (typeof currentObject.listener != "undefined") {
						currentObject.listener.end();
					}

					// consume current promise
					currentObject.exchangeStack.shift();
                      
					// schedule next exchange
					if (currentObject.exchangeStack.length > 0) {
						processNextExchange();
					}
				});                    
            }; //processNextExchange
                  
			// schedule next exchange
			processNextExchange();
		}
                
		// the exchangeStack will process the promise when possible
		return deferred.promise;
	},

	reset:function(mode) {
	},	
	
	disconnect_async:function(mode) {
		var currentObject = this;		
		if (!this.connection) {
			return;
		}
		return this.device.close_async().then(function(result) {
			currentObject.connection = false;
		});
	},	
	
	getSW : function() {
		return this.SW;
	},
	
	getSW1 : function() {
		return this.SW1;
	},

	getSW2 : function() {
		return this.SW2;
	},
	
	setCommandDelay : function(delay) {
		// unsupported - use options
	},
	
	setReportDelay : function(delay) {
		// unsupported - use options
	},
	
	getCommandDelay : function() {
		// unsupported - use options
		return 0;
	},
	
	getReportDelay : function() {
		// unsupported - use options
		return 0;
	}
		
	
});
