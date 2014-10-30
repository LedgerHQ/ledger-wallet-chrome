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

if (typeof bridgedDevice == "undefined") {

var bridgedDevice = function(enumeratedDevice) {
	this.device = enumeratedDevice;
}

bridgedDevice.prototype.open_async = function() {
  var id = bridgedDevice.addCallback();
  var currentDevice = this;
  window.postMessage({ 
        destination: "PUP_EXT",
        command: "OPEN",
        id: id,
        parameters: {
            device: this.device
        }
   }, "*");   
  return bridgedDevice.callbacks[id].promise.then(function(result) {
    currentDevice.id = result.deviceId;
  });
}

bridgedDevice.prototype.send_async = function(data) {
  var id = bridgedDevice.addCallback();
  window.postMessage({ 
        destination: "PUP_EXT",
        command: "SEND",
        id: id,
        parameters: {
            deviceId: this.id,
            data: data
        }
   }, "*");   
  return bridgedDevice.callbacks[id].promise;
}

bridgedDevice.prototype.recv_async = function(size) {
  var id = bridgedDevice.addCallback();
  window.postMessage({ 
        destination: "PUP_EXT",
        command: "RECV",
        id: id,
        parameters: {
            deviceId: this.id,
            size: size
        }
   }, "*");   
  return bridgedDevice.callbacks[id].promise;
}

bridgedDevice.prototype.close_async = function() {
  var id = bridgedDevice.addCallback();
  window.postMessage({ 
        destination: "PUP_EXT",
        command: "CLOSE",
        id: id,
        parameters: {
            deviceId: this.id
        }
   }, "*");   
  return bridgedDevice.callbacks[id].promise;
}


bridgedDevice.addCallback = function() {
  var deferred = Q.defer();
  var currentId = bridgedDevice.id++;
  bridgedDevice.callbacks[currentId] = deferred;
  return currentId;
}

bridgedDevice.enumerateDongles_async = function(pid, usagePage) {
  if (typeof pid == "undefined") {
    pid = 0x1b7c;
  }
  var id = bridgedDevice.addCallback();
  window.postMessage({ 
        destination: "PUP_EXT",
        command: "ENUMERATE",
        id: id,
        parameters: {
            vid: 0x2581,
            pid: pid,
            usagePage: usagePage
        }
   }, "*");
   return bridgedDevice.callbacks[id].promise;  
}

bridgedDevice.callbacks = {};
bridgedDevice.id = 0;

window.addEventListener("message", function(event) {
  if (event.data.destination == "PUP_APP") {
    var promise = bridgedDevice.callbacks[event.data.id];
    delete bridgedDevice.callbacks[event.data.id];
    if (typeof event.data.response.exception != "undefined") {
      promise.reject(event.data.response.exception);
    }
    else {
      promise.resolve(event.data.response);
    }
  }
}, false);


}
