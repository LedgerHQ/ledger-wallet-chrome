# Ledger Wallet - Chrome App

This is the source code of the Ledger Wallet Chrome application. You can build the application package yourself if you want to do the Ledger Wallet initialization on an airgap computer.

To prepare your build environment, follow these steps:
* Install [nodejs](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)
* Install application dependencies
    * `npm install -g gulp`
    * `npm install`

To build the application, go to the repo root directory then enter `gulp package`. This will create a crx file into the
dist directory.

To install the application on Chrome, go to chrome extensions page ([chrome://extensions](chrome://extensions)), then drag and drop the crx file into the page.
 
    
