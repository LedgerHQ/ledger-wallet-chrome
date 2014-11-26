# Ledger Wallet - Chrome App

This is the source code of the Ledger Wallet Chrome application. You can build the application package yourself if you want to do the Ledger Wallet initialization on an airgap computer.

To prepare your build environment, follow these steps:
* Install [nodejs](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)
* Install gulp
    * `sudo npm install -g gulp`
    * `npm install`

To build the application, go to the repo root and type in `gulp`

To install the application on Chrome, go to chrome://extensions, activate developer mode, click load unpacked package and select the "build" directory from your repo.
 
    
