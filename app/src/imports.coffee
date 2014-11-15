@ledger =
      imports: [
        '../libs/jquery-2.1.1.min',
        '../libs/jquery.color',
        '../libs/underscore-min',
        '../libs/underscore.string.min',
        '../libs/underscore.inflection',
        '../libs/signals.min',
        '../libs/crossroads.min',
        '../libs/spin.min',
        '../libs/sjcl',
        '../libs/jquery.selectric.min',
        '../libs/qrcode.min',
        '../public/tooltipster/js/jquery.tooltipster.min',
        '../libs/lw-api-js/lib/bitcoinjs-min',
        '../libs/lw-api-js/lib/util',
        '../libs/lw-api-js/lib/inheritance',
        '../libs/lw-api-js/lib/q',
        '../libs/lw-api-js/lib/async',
        '../libs/lw-api-js/lib/jsbn',
        '../libs/lw-api-js/lib/jsbn2',
        '../libs/lw-api-js/lib/BitcoinExternal',
        '../libs/lw-api-js/btchip-js-api/chromeApp/chromeDevice',
        '../libs/lw-api-js/btchip-js-api/GlobalConstants',
        '../libs/lw-api-js/btchip-js-api/Convert',
        '../libs/lw-api-js/btchip-js-api/ByteString',
        '../libs/lw-api-js/btchip-js-api/Card',
        '../libs/lw-api-js/btchip-js-api/CardTerminalFactory',
        '../libs/lw-api-js/btchip-js-api/CardTerminal',
        '../libs/lw-api-js/btchip-js-api/chromeApp/ChromeapiPlugupCard',
        '../libs/lw-api-js/btchip-js-api/chromeApp/ChromeapiPlugupCardTerminalFactory',
        '../libs/lw-api-js/btchip-js-api/ChromeapiPlugupCardTerminal',
        '../libs/lw-api-js/btchip-js-api/BTChip',
        '../libs/lw-api-js/ucrypt/JSUCrypt',
        '../libs/lw-api-js/ucrypt/keys',
        '../libs/lw-api-js/ucrypt/helpers',
        '../libs/lw-api-js/ucrypt/signature',
        '../libs/lw-api-js/ucrypt/ecfp',
        '../libs/lw-api-js/ucrypt/ecdsa',
        '../libs/lw-api-js/ucrypt/hash',
        '../libs/lw-api-js/ucrypt/sha256',
        '../libs/lw-api-js/ucrypt/sha512',
        '../libs/lw-api-js/ucrypt/hmac',
        '../libs/lw-api-js/LWTools',
        '../libs/lw-api-js/LW',
        '../libs/lw-api-js/LWWallet',
        '../libs/lw-api-js/LWTransaction',
        '../libs/bs58',
        '../libs/BigInt',
        '../libs/sha256',
        '../libs/checkBitcoinAddress',

        'routes',

        'utils/log',
        'utils/string',
        'utils/number',
        'utils/object',
        'utils/async',
        'utils/render',
        'utils/event_emitter',
        'utils/http_client',
        'utils/url',
        'utils/easing',
        'utils/router',
        'utils/i18n',
        'utils/jquery',
        'utils/spinners',
        'utils/pin_codes',

        'utils/crypto/aes',
        'utils/crypto/sha256',
        'utils/crypto/base58',

        'utils/bitcoin',

        'utils/storage/store',
        'utils/storage/chrome_store',
        'utils/storage/secure_store',
        'utils/storage/synced_store',
        'utils/storage/object_store',
        'utils/storage/storage',

        'base/errors'

        'managers/devices_manager'

        ## Rest clients
        'restclients/restclient'
        'restclients/unspent_outputs_restclient'
        'restclients/transactions_restclient'

        ## Wallet
        'managers/wallets_manager'
        'wallet/hardware_wallet'
        'wallet/utils'
        'wallet/transaction'
        'wallet/value'

        'base/model',
        'base/collection',
        'base/view_controller',
        'base/navigation_controller',

        ## Collections (must absolutely be imported here before models)

        ## Models
        'models/account',
        'models/operation',

        ## Dialog Management
        'utils/dialogs',
        '../views/base/dialog',
        'base/dialog_view_controller'

        ## Wallet controllers
        'controllers/wallet/wallet_navigation_controller',
        # Dashboard
        'controllers/wallet/dashboard/wallet_dashboard_index_view_controller',
        # Operations
        'controllers/wallet/operations/wallet_operations_detail_dialog_view_controller',
        'controllers/wallet/operations/wallet_operations_index_view_controller',
        # Accounts
        'controllers/wallet/accounts/wallet_accounts_account_view_controller',
        'controllers/wallet/accounts/wallet_accounts_account_receive_dialog_view_controller',
        'controllers/wallet/accounts/wallet_accounts_account_send_dialog_view_controller',

        ## Onboarding controllers
        'controllers/onboarding/onboarding_view_controller'
        'controllers/onboarding/onboarding_navigation_controller',
        # Device
        'controllers/onboarding/device/onboarding_device_plug_view_controller',
        'controllers/onboarding/device/onboarding_device_unplug_view_controller',
        'controllers/onboarding/device/onboarding_device_pin_view_controller',
        # Management
        'controllers/onboarding/management/onboarding_management_done_view_controller',
        'controllers/onboarding/management/onboarding_management_welcome_view_controller',
        'controllers/onboarding/management/onboarding_management_frozen_view_controller',
        'controllers/onboarding/management/onboarding_management_pin_view_controller',
        'controllers/onboarding/management/onboarding_management_pin_confirmation_view_controller'
      ]