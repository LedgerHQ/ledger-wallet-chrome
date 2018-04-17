# Ledger Wallet - Chrome App

Installing the build environment
-------------------------------

This is the source code of the Ledger Wallet Chrome application. You can build the application package yourself if you want to do the Ledger Wallet initialization on an airgap computer.

To prepare your build environment, follow these steps:
* Install [nodejs](https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager)
* Install application dependencies
    * `npm install -g gulp`
    * `npm install`

Once the environment is setup, you should see the help page of the build system by typing `gulp --help`

Building a packaged application crx
-----------------------------------

To build the application, go to the repo root directory then enter `gulp clean build package --release`. This will create a crx file into the dist directory.

To install the application on Chrome, go to chrome extensions page ([chrome://extensions](chrome://extensions)), then drag and drop the crx file into the page.

Building a zip containing the application
-----------------------------------------

You can build the application and automatically packaging it in a zip file by running `gulp clean build zip --release`. This will create a zip file into the dist directory

Building the application for another coin
-----------------------------------------

You can build the chrome application for other coins. Run `gulp clean build package zip -n *coin_name* --release`. Right now you can build for the following coins:
 - bitcoin
 - testnet
 - litecoin
 - litecoin_test
 - dogecoin
 - dogecoin_test
 - zencash
 - gamecredits

Note: that the API is only available for bitcoin and testnet right now.

