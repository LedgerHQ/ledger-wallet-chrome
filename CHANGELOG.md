# Changelog
1.4.2
===
- Add 'bitcoin:' payment links registration
- Show local currency counter value when sending or receiving a transaction

1.4.1
===
- Silent API xpub exportation for path including 0xb11e magic number (Copay integration)

1.4.0
===
- New multi-accounts feature
- Performance improvements
- Bug fixes

1.3.16
===
- Fix transaction parsing

1.3.15
===
- Force firmware update for devices running Ledger OS 1.0.0

1.3.14
===
- Allow all Chrome application to use the API

1.3.12/1.3.13
===
- Use dynamic transaction fees instead of fixed fees
- Fix a UI bug in the transaction dialog

1.3.10/1.3.11
====
- Fix a bug during transaction validation

1.3.9
=====
- Fix a bug during firmware update

1.3.8
=====
- Fix a bug in transaction validation

1.3.7
=====
- Add seed confirmation page in onboarding flow
- Add security checks after dongle signature
- Add dongle consistency check after provisioning

1.3.6
====
- Fix preferences synchronization
- Bug fixes

1.3.5
====
- Fix a bug when sending more than 20BTC
- Minor application performances improvement
- Fix a minor bug due to Chrome 43

1.3.3/1.3.4
====
- Improve application performances
- Bug fixes

1.3.2
====
- Fix a bug during transaction preparation

1.3.0/1.3.1
====
- Add a new user interface to easily contact support
- Add a progress bar during transaction
- Fix error 407 during update
- Add getNewAddresses API method
- New dongle management
- Add security card lock
- Bugs fixes

1.2.0
=====
- Add new preferences dialog
- Add high level JS API - https://github.com/LedgerHQ/ledger-wallet-api
- Bugs fixes

1.1.3
=====
- Embed new firmware 1.0.1
- Add Coinkite app (beta)
- Add BitID support
- Add API support (beta)
- Bug fixes

1.1.2
=====
- Improve QR code scanner
- Improve app update detection
- Add settings section
- Add shortcut to go to firmware update mode

1.1.1
=====
- Fix attestation freeze
- UI improvements
- Add update flow security card check

1.1.0
=====
- Add mobile second factor authentication for validating transactions
- Add pairing process to bind a Ledger Wallet with a smartphone
- Add firmware update process
- UI improvements
- Bug fixes

1.0.7
=====
- Improve transactions synchronization
- Fix a bug in transaction preparation
- Fix a bug in transaction interpretation

1.0.5/1.0.6
=====
- Add manual synchronization button
- Add public key derivation
- Improve HD wallet layout synchronization
- Display confirmations count in operations detail dialogs
- Add Gulp release rule
- Reject HW.1 devices

1.0.4
=====
- Add QR code scanner in send dialog
- Migrate to Loki-js for database management
- Fix locale missing translations
- Improve application transactions detection speed
- Small UI improvements
- Remove unspent verification before sending bitcoins
- Improve transactions preparation algorythm

1.0.2/1.0.3
=====
- Add spanish translation
- Fix spanish encoding

1.0.1
=====
- Fix major bugs in transactions and balance management
- Add print feature in receive dialog
- Add operation detail dialog
- Update onboarding flow

1.0.0
=====
- First release of Ledger Wallet Chrome app
