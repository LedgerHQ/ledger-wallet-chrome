/**
 * Created by pollas_p on 24/08/15.
 */

var exec = require('child_process').exec;
var install = require('tarball-extract');
var fs = require('fs');

var clean = function () {
    if (isNaN(parseInt(clean._iteration))) {
        clean._iteration = 1;
        return
    }
    clean._iteration += 1;
    if (clean._iteration == 2) {
        fs.unlinkSync('hid.tar.gz');
        fs.unlinkSync('usb.tar.gz');
        fs.rmdirSync('node_modules/usb-temp');
        fs.rmdirSync('node_modules/node-hid-temp');
    }
}

exec('npm view usb dist.tarball', function (err, moduleUrl) {
    if (err) {
        console.error(err);
        return;
    }

    install.extractTarballDownload(moduleUrl, 'usb.tar.gz', './node_modules/usb-temp', {}, function(err, result) {
        fs.rename('./node_modules/usb-temp/package', './node_modules/usb', function () {
            next = function (err) {
                console.log(err);
                exec('cd node_modules/usb && npm install && node-pre-gyp clean configure build --target=0.12.3 --runtime="node-webkit"', clean);
            };

            if (!/^win/.test(process.platform)) {
                // Don't run patch on windows
                exec("patch node_modules/usb/libusb/libusb/os/darwin_usb.c < ./darwin_usb.c.patch", next);
            }
            else {
                next();
            }
        });
    });

});

exec('npm view node-hid dist.tarball', function (err, moduleUrl) {
    if (err) {
        console.error(err);
        return;
    }

    install.extractTarballDownload(moduleUrl, 'hid.tar.gz', './node_modules/node-hid-temp', {}, function (err, result) {
        fs.rename('./node_modules/node-hid-temp/package', './node_modules/node-hid', function () {
            exec('cd node_modules/node-hid && npm install && nw-gyp  clean configure build --target="0.12.3"', clean);
        });
    });
});




