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
 * JSUCrypt main space
 * @namespace JSUCrypt
 */
var JSUCrypt = JSUCrypt || (function (undefined) {

    /** 
     * @lends JSUCrypt
     */
    var u = {};

    /**
     * JSUCrypt version
     */
    u.version = "0.2.0";

    /**
     * JSUCrypt exception class used by  JSUCrypt library.
     * JSUCrypt functions does not throw explicitky other kind of exception.
     *
     * @param {string} wat Exception details
     * @class
     */
    u.JSUCryptException = function(wat) {
        this.why = wat;       
    };
    
    /** 
     * To string 
     */
    u.JSUCryptException.prototype.toString = function() {
        return "JSUCryptException: "+ this.why.toString();
    };



    /** 
     * Add 'append' to array object....
     * @ignore 
     */
    Array.prototype.append =   Array.prototype.append || function(array) {
        this.push.apply(this, array);
        return this;
    };


    // --- set it ---
    return u;
}());
