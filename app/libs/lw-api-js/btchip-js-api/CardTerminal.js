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

var CardTerminal = Class.create({
	/** @lends CardTerminal.prototype */

	/**
	 * @class Interface defining the interaction with a card terminal 
	 * @constructs
	 */
	initialize : function() {
		throw "abstract class";
	},
	
	/**
	 * Check if a card is present in the reader
	 * @returns {boolean} true if a card was found
	 */
	isCardPresent:function() {
	},
	
	/**
	 * Obtain a card object mapped to the card inserted in the reader
	 * @returns {Card} card object
	 */
	getCard:function() {
	},
	
	/**
	 * Retrieve the name of the terminal
	 * @returns {String} terminal name
	 */
	getName:function() {
	}
	
});
