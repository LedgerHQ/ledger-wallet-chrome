@ledger =
      imports: [
        '../libs/jquery-2.1.1.min'
        '../libs/jquery.color'
        '../libs/underscore-min'
        '../libs/underscore.string.min'
        '../libs/underscore.inflection'
        '../libs/signals.min'
        '../libs/crossroads.min'
        '../libs/spin.min'
        '../libs/sjcl/sjcl'
        '../libs/sjcl/sha512'
        '../libs/jquery.selectric.min'
        '../libs/qrcode.min'
        '../libs/jquery.suggest'
        '../libs/cryptojs.min'
        '../public/tooltipster/js/jquery.tooltipster.min'
        '../libs/lw-api-js/lib/bitcoinjs-min'
        '../libs/lw-api-js/lib/util'
        '../libs/lw-api-js/lib/inheritance'
        '../libs/lw-api-js/lib/q'
        '../libs/lw-api-js/lib/async'
        '../libs/lw-api-js/lib/jsbn'
        '../libs/lw-api-js/lib/jsbn2'
        '../libs/lw-api-js/lib/BitcoinExternal'
        '../libs/lw-api-js/btchip-js-api/chromeApp/chromeDevice'
        '../libs/lw-api-js/btchip-js-api/GlobalConstants'
        '../libs/lw-api-js/btchip-js-api/Convert'
        '../libs/lw-api-js/btchip-js-api/ByteString'
        '../libs/lw-api-js/btchip-js-api/Card'
        '../libs/lw-api-js/btchip-js-api/CardTerminalFactory'
        '../libs/lw-api-js/btchip-js-api/CardTerminal'
        '../libs/lw-api-js/btchip-js-api/chromeApp/ChromeapiPlugupCard'
        '../libs/lw-api-js/btchip-js-api/chromeApp/ChromeapiPlugupCardTerminalFactory'
        '../libs/lw-api-js/btchip-js-api/ChromeapiPlugupCardTerminal'
        '../libs/lw-api-js/btchip-js-api/BTChip'
        '../libs/lw-api-js/ucrypt/JSUCrypt'
        '../libs/lw-api-js/ucrypt/keys'
        '../libs/lw-api-js/ucrypt/helpers'
        '../libs/lw-api-js/ucrypt/signature'
        '../libs/lw-api-js/ucrypt/ecfp'
        '../libs/lw-api-js/ucrypt/ecdsa'
        '../libs/lw-api-js/ucrypt/hash'
        '../libs/lw-api-js/ucrypt/sha256'
        '../libs/lw-api-js/ucrypt/sha512'
        '../libs/lw-api-js/ucrypt/ripemd160'
        '../libs/lw-api-js/ucrypt/hmac'
        '../libs/lw-api-js/LWTools'
        '../libs/lw-api-js/LW'
        '../libs/lw-api-js/LWWallet'
        '../libs/lw-api-js/LWTransaction'
        '../libs/bs58'
        '../libs/BigInt'
        '../libs/sha256'
        '../libs/checkBitcoinAddress'
        '../libs/bitcoinUtils'
        '../libs/lru'
        '../libs/moment.min'
        '../libs/lokijs.min'
        '../libs/bitcoinjs-min'
        '../libs/zbarqrcode'

        # Used be m2fa.DebugClient
        '../libs/lw-api-js/ucrypt/ka'
        '../libs/lw-api-js/ucrypt/pad'
        '../libs/lw-api-js/ucrypt/cipher'
        '../libs/lw-api-js/ucrypt/des'
        '../libs/lw-api-js/ucrypt/ecdh'

        ## Application configuration
        'configuration'

        ## Logger
        'utils/logger'

        ## Routes
        'routes'

        ## Utils
        'utils/string'
        'utils/number'
        'utils/array'
        'utils/object'
        'utils/async'
        'utils/render'
        'utils/event_emitter'
        'utils/http_client'
        'utils/url'
        'utils/easing'
        'utils/router'
        'utils/i18n'
        'utils/jquery'
        'utils/spinners'
        'utils/pin_codes'
        'utils/qr_codes'
        'utils/lru'
        'utils/formatters'
        'utils/stream'
        'utils/defer'
        'utils/try'
        'utils/comparison_result'
        'utils/amount'
        'utils/progressbars'
        'utils/keycard'
        'utils/promise_queue'

        ## Crypto
        'utils/crypto/aes'
        'utils/crypto/sha256'
        'utils/crypto/base58'

        ## Bitcoin
        'utils/bitcoin/bitcoin'
        'utils/bitcoin/bip39_wordlist'
        'utils/bitcoin/bip39'
        'utils/bitcoin/bitid'

        ## Storage
        'utils/storage/store'
        'utils/storage/chrome_store'
        'utils/storage/secure_store'
        'utils/storage/synced_store'
        'utils/storage/object_store'
        'utils/storage/storage'

        ## Data synchronization

        ## Errors
        'base/errors'

        ## Managers
        'managers/schemes_manager'
        'managers/permissions_manager'
        'managers/system_manager'

        ## Apps
        'utils/apps/coinkite'

        ## Rest clients
        'restclients/authentication'
        'restclients/restclient'
        'restclients/unspent_outputs_restclient'
        'restclients/transactions_restclient'
        'restclients/balance_restclient'
        'restclients/sync_rest_client'
        'restclients/m2fa_restclient'

        ## Tasks
        'tasks/task'
        'tasks/balance_task'
        'tasks/wallet_layout_recovery_task'
        'tasks/transaction_observer_task'
        'tasks/operations_synchronization_task'
        'tasks/operations_consumption_task'
        'tasks/address_derivation_task'

        ## Wallet
        'wallet/utils'
        'wallet/transaction'
        'wallet/value'
        'wallet/hdwallet'
        'wallet/cache'
        'wallet/extended_public_key'
        'wallet/sweep_private_key'
        'wallet/wallet_setup_consistency_checker'

        'utils/database/database'
        'base/base_application'
        'base/model_context'
        'base/model'
        'base/migrations'
        'base/view_controller'
        'base/navigation_controller'

        ## Dongle
        'dongle/dongle'
        'dongle/utils'
        'dongle/manager'

        ## Mobile 2FA
        'm2fa/m2fa'
        'm2fa/client'
        'm2fa/debug_client'
        'm2fa/pairing_request'
        'm2fa/transaction_validation_request'
        'm2fa/paired_secure_screen'

        ## Firmware Update
        'fup/firmware_update_request'
        'fup/firmware_updater'
        'fup/firmwares_manifest'
        'fup/utils'

        ## Models
        'models/wallet'
        'models/account'
        'models/operation'
        'models/configuration'

        ## Dialog Management
        'utils/dialogs'
        '../views/common/dialogs/dialog'
        'base/dialog_view_controller'

        ## Common controllers
        # Dialogs
        'controllers/common/dialogs/common_dialogs_confirmation_dialog_view_controller'
        'controllers/common/dialogs/common_dialogs_message_dialog_view_controller'
        'controllers/common/dialogs/common_dialogs_qrcode_dialog_view_controller'

        ## Wallet controllers
        'controllers/wallet/wallet_navigation_controller'

        # Dashboard
        'controllers/wallet/dashboard/wallet_dashboard_index_view_controller'

        # Operations
        'controllers/wallet/operations/wallet_operations_detail_dialog_view_controller'
        'controllers/wallet/operations/wallet_operations_index_view_controller'

        # Accounts
        'controllers/wallet/accounts/wallet_accounts_show_view_controller'

        # Send
        'controllers/wallet/send/wallet_send_index_dialog_view_controller'
        'controllers/wallet/send/wallet_send_mobile_dialog_view_controller'
        'controllers/wallet/send/wallet_send_card_dialog_view_controller'
        'controllers/wallet/send/wallet_send_processing_dialog_view_controller'
        'controllers/wallet/send/wallet_send_preparing_dialog_view_controller'
        'controllers/wallet/send/wallet_send_validating_dialog_view_controller'
        'controllers/wallet/send/wallet_send_method_dialog_view_controller'

        # Receive
        'controllers/wallet/receive/wallet_receive_index_dialog_view_controller'

        # BitID
        'controllers/wallet/bitid/wallet_bitid_index_dialog_view_controller'
        'controllers/wallet/bitid/wallet_bitid_authenticating_dialog_view_controller'
        'controllers/wallet/bitid/wallet_bitid_form_dialog_view_controller'

        # Settings
        'controllers/wallet/settings/wallet_settings_hardware_dialog_view_controller'

        ## Onboarding controllers
        'controllers/onboarding/onboarding_view_controller'
        'controllers/onboarding/onboarding_navigation_controller'

        # Device
        'controllers/onboarding/device/onboarding_device_plug_view_controller'
        'controllers/onboarding/device/onboarding_device_unplug_view_controller'
        'controllers/onboarding/device/onboarding_device_pin_view_controller'
        'controllers/onboarding/device/onboarding_device_opening_view_controller'
        'controllers/onboarding/device/onboarding_device_error_view_controller'
        'controllers/onboarding/device/onboarding_device_connecting_view_controller'
        'controllers/onboarding/device/onboarding_device_update_view_controller'
        'controllers/onboarding/device/onboarding_device_unsupported_view_controller'
        'controllers/onboarding/device/onboarding_device_failed_view_controller'

        # Management
        'controllers/onboarding/management/onboarding_management_security_view_controller'
        'controllers/onboarding/management/onboarding_management_welcome_view_controller'
        'controllers/onboarding/management/onboarding_management_pin_view_controller'
        'controllers/onboarding/management/onboarding_management_pin_confirmation_view_controller'
        'controllers/onboarding/management/onboarding_management_seed_view_controller'
        'controllers/onboarding/management/onboarding_management_summary_view_controller'
        'controllers/onboarding/management/onboarding_management_provisioning_view_controller'
        'controllers/onboarding/management/onboarding_management_done_view_controller'

        # Pairing
        'controllers/wallet/pairing/wallet_pairing_index_dialog_view_controller'
        'controllers/wallet/pairing/wallet_pairing_progress_dialog_view_controller'
        'controllers/wallet/pairing/wallet_pairing_finalizing_dialog_view_controller'

        ## Update controllers
        'controllers/update/update_navigation_controller'
        'controllers/update/update_view_controller'
        'controllers/update/update_index_view_controller'
        'controllers/update/update_plug_view_controller'
        'controllers/update/update_seed_view_controller'
        'controllers/update/update_erasing_view_controller'
        'controllers/update/update_unplug_view_controller'
        'controllers/update/update_updating_view_controller'
        'controllers/update/update_loading_view_controller'
        'controllers/update/update_done_view_controller'
        'controllers/update/update_linux_view_controller'
        'controllers/update/update_cardcheck_view_controller'
        'controllers/update/update_error_view_controller'

        ## API
        'api'

        ## Coinkite
        'controllers/apps/coinkite/apps_coinkite_navigation_controller'
        'controllers/apps/coinkite/dashboard/apps_coinkite_dashboard_index_view_controller'
        'controllers/apps/coinkite/dashboard/apps_coinkite_dashboard_compatibility_view_controller'
        'controllers/apps/coinkite/settings/apps_coinkite_settings_index_dialog_view_controller'
        'controllers/apps/coinkite/keygen/apps_coinkite_keygen_processing_dialog_view_controller'
        'controllers/apps/coinkite/keygen/apps_coinkite_keygen_show_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_index_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_fetching_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_show_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_signing_dialog_view_controller'

        # Specs
        '../spec/spec_helper'
      ]

      specs:
        jasmine: [
          '../spec/jasmine/jasmine'
          '../spec/jasmine/jasmine-html'
          '../spec/jasmine/boot'
        ]
        files: [
          '../spec/utils/storage/store_spec'
          '../spec/utils/storage/chrome_store_spec'
          '../spec/utils/storage/secure_store_spec'
          '../spec/restclients/synced_rest_client_spec'
          '../spec/utils/storage/synced_store_spec'
          '../spec/utils/bitcoin/bip39_spec'

          '../spec/m2fa/client_spec'
          '../spec/m2fa/m2fa_spec'
        ]
