@ledger =
      imports: [
        'build'
        '../libs/base64'
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
        '../libs/btchip/lib/bitcoinjs-min'
        '../libs/btchip/lib/util'
        '../libs/btchip/lib/inheritance'
        '../libs/btchip/lib/q'
        '../libs/btchip/lib/async'
        '../libs/btchip/lib/jsbn'
        '../libs/btchip/lib/jsbn2'
        '../libs/btchip/lib/BitcoinExternal'
        '../libs/btchip/btchip-js-api/chromeApp/chromeDevice'
        '../libs/btchip/btchip-js-api/GlobalConstants'
        '../libs/btchip/btchip-js-api/Convert'
        '../libs/btchip/btchip-js-api/ByteString'
        '../libs/btchip/btchip-js-api/Card'
        '../libs/btchip/btchip-js-api/CardTerminalFactory'
        '../libs/btchip/btchip-js-api/CardTerminal'
        '../libs/btchip/btchip-js-api/chromeApp/ChromeapiPlugupCard'
        '../libs/btchip/btchip-js-api/chromeApp/ChromeapiPlugupCardTerminalFactory'
        '../libs/btchip/btchip-js-api/ChromeapiPlugupCardTerminal'
        '../libs/btchip/btchip-js-api/BTChip'
        '../libs/btchip/ucrypt/JSUCrypt'
        '../libs/btchip/ucrypt/keys'
        '../libs/btchip/ucrypt/helpers'
        '../libs/btchip/ucrypt/signature'
        '../libs/btchip/ucrypt/ecfp'
        '../libs/btchip/ucrypt/ecdsa'
        '../libs/btchip/ucrypt/hash'
        '../libs/btchip/ucrypt/sha256'
        '../libs/btchip/ucrypt/sha512'
        '../libs/btchip/ucrypt/ripemd160'
        '../libs/btchip/ucrypt/hmac'
        '../libs/bs58'
        '../libs/BigInt'
        '../libs/sha256'
        '../libs/checkBitcoinAddress'
        '../libs/bitcoinUtils'
        '../libs/lru'
        '../libs/moment'
        '../libs/lokijs.min'
        '../libs/bitcoinjs-min'
        '../libs/zbarqrcode'
        '../libs/mutation-summary'
        '../libs/jsencrypt'
        '../libs/ua-parser-0.7.7.min'
        '../libs/zip/zip'
        '../libs/zip/z-worker'
        '../libs/zip/inflate'
        '../libs/zip/deflate'

        # Used be m2fa.DebugClient
        '../libs/btchip/ucrypt/ka'
        '../libs/btchip/ucrypt/pad'
        '../libs/btchip/ucrypt/cipher'
        '../libs/btchip/ucrypt/des'
        '../libs/btchip/ucrypt/ecdh'

        ## Application configuration
        'bitcoin/networks'
        'configuration'

        ## Logger
        'utils/logger'
        'utils/apdu_logger'
        'utils/logger/log'
        'utils/logger/log_writer'
        'utils/logger/log_reader'
        'utils/logger/secure_log_writer'
        'utils/logger/secure_log_reader'

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
        'utils/jquery'
        'utils/spinners'
        'utils/pin_codes'
        'utils/qr_codes'
        'utils/lru'
        'utils/formatters'
        'utils/converters'
        'utils/stream'
        'utils/defer'
        'utils/try'
        'utils/comparison_result'
        'utils/amount'
        'utils/progressbars'
        'utils/keycard'
        'utils/promise_queue'
        'utils/csv_exporter'
        'utils/completion_closure'
        'utils/validers'
        'utils/function_lock'
        'utils/json'
        'utils/promise/debounce'
        'utils/promise/throttle'

        ## Crypto
        'crypto/aes'
        'crypto/sha256'
        'crypto/base58'

        ## Bitcoin
        'bitcoin/bitcoin'
        'bitcoin/bip39_wordlist'
        'bitcoin/bip39'
        'bitcoin/bitid'
        'bitcoin/utils'

        ## Storage
        'storage/store'
        'storage/substore'
        'storage/chrome_store'
        'storage/secure_store'
        'storage/synced_store'
        'storage/object_store'
        'storage/memory_store'
        'storage/storage'

        ## Data synchronization

        ## Errors
        'errors/errors'
        'errors/utils'

        ## Managers
        'managers/schemes_manager'
        'managers/permissions_manager'
        'managers/system_manager'
        'managers/application_manager'

        ## Apps
        'utils/apps/coinkite'

        ## Rest clients
        'api/authentication'
        'api/restclient'
        'api/unspent_outputs_restclient'
        'api/transactions_restclient'
        'api/balance_restclient'
        'api/sync_rest_client'
        'api/m2fa_restclient'
        'api/currencies_restclient'
        'api/groove_restclient'

        ## Tasks
        'tasks/task'
        'tasks/balance_task'
        'tasks/wallet_layout_recovery_task'
        'tasks/transaction_observer_task'
        'tasks/operations_synchronization_task'
        'tasks/operations_consumption_task'
        'tasks/address_derivation_task'
        'tasks/ticker_task'
        'tasks/wallet_open_task'

        ## Wallet
        'wallet/utils'
        'wallet/transaction'
        'wallet/wallet'
        'wallet/cache'
        'wallet/extended_public_key'
        'wallet/sweep_private_key'

        'database/database'
        'common/base_application'
        'database/model_context'
        'database/model'
        'database/migrations'
        'common/view_controller'
        'common/navigation_controller'
        'common/action_bar_view_controller'
        'common/action_bar_navigation_controller'

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
        'models/operation'
        'models/account'
        'models/configuration'

        ## Dialog Management
        'utils/dialogs'
        '../views/common/dialogs/dialog'
        'common/dialog_view_controller'

        ## Common controllers
        # Dialogs
        'controllers/common/dialogs/common_dialogs_confirmation_dialog_view_controller'
        'controllers/common/dialogs/common_dialogs_message_dialog_view_controller'
        'controllers/common/dialogs/common_dialogs_qrcode_dialog_view_controller'
        'controllers/common/dialogs/common_dialogs_ticket_dialog_view_controller'
        'controllers/common/dialogs/common_dialogs_help_dialog_view_controller'

        ## Wallet controllers
        'controllers/wallet/wallet_navigation_controller'

        # Dialogs
        '/controllers/wallet/dialogs/wallet_dialogs_addaccount_dialog_view_controller'
        '/controllers/wallet/dialogs/wallet_dialogs_accountsettings_dialog_view_controller'
        '/controllers/wallet/dialogs/wallet_dialogs_operationdetail_dialog_view_controller'

        # Accounts
        'controllers/wallet/accounts/wallet_accounts_index_view_controller'
        'controllers/wallet/accounts/wallet_accounts_show_view_controller'
        'controllers/wallet/accounts/wallet_accounts_operations_view_controller'
        'controllers/wallet/accounts/wallet_accounts_alloperations_view_controller'

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

        # XPubKey
        'controllers/wallet/xpubkey/wallet_xpubkey_index_dialog_view_controller'
        'controllers/wallet/xpubkey/wallet_xpubkey_processing_dialog_view_controller'

        # P2SH
        'controllers/wallet/p2sh/wallet_p2sh_index_dialog_view_controller'
        'controllers/wallet/p2sh/wallet_p2sh_signing_dialog_view_controller'

        # Settings
        # - Base
        'controllers/wallet/settings/wallet_settings_index_dialog_view_controller'
        'controllers/wallet/settings/base/wallet_settings_section_dialog_view_controller'
        'controllers/wallet/settings/base/wallet_settings_setting_view_controller'

        # - Hardware
        'controllers/wallet/settings/hardware/wallet_settings_hardware_firmware_setting_view_controller'
        'controllers/wallet/settings/hardware/wallet_settings_hardware_smartphones_setting_view_controller'
        'controllers/wallet/settings/wallet_settings_hardware_section_dialog_view_controller'

        # - Apps
        'controllers/wallet/settings/apps/wallet_settings_apps_list_setting_view_controller'
        'controllers/wallet/settings/wallet_settings_apps_section_dialog_view_controller'

        # - Display
        'controllers/wallet/settings/display/wallet_settings_display_units_setting_view_controller'
        'controllers/wallet/settings/display/wallet_settings_display_currency_setting_view_controller'
        'controllers/wallet/settings/display/wallet_settings_display_language_setting_view_controller'
        'controllers/wallet/settings/wallet_settings_display_section_dialog_view_controller'

        # - Bitcoin
        'controllers/wallet/settings/bitcoin/wallet_settings_bitcoin_confirmations_setting_view_controller'
        'controllers/wallet/settings/bitcoin/wallet_settings_bitcoin_fees_setting_view_controller'
        'controllers/wallet/settings/bitcoin/wallet_settings_bitcoin_blockchain_setting_view_controller'
        'controllers/wallet/settings/wallet_settings_bitcoin_section_dialog_view_controller'

        # - Tools
        'controllers/wallet/settings/tools/wallet_settings_tools_logs_setting_view_controller'
        'controllers/wallet/settings/wallet_settings_tools_section_dialog_view_controller'

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
        'controllers/onboarding/management/onboarding_management_seed_confirmation_view_controller'
        'controllers/onboarding/management/onboarding_management_summary_view_controller'
        'controllers/onboarding/management/onboarding_management_provisioning_view_controller'
        'controllers/onboarding/management/onboarding_management_done_view_controller'

        # Pairing
        'controllers/wallet/pairing/wallet_pairing_index_dialog_view_controller'
        'controllers/wallet/pairing/wallet_pairing_progress_dialog_view_controller'
        'controllers/wallet/pairing/wallet_pairing_finalizing_dialog_view_controller'

        ## Widgets
        'widgets/switch'
        'widgets/segmented_control'

        ## i18n
        'i18n/i18n'
        'i18n/i18n_formatters'
        'i18n/i18n_languages'

        ## Preferences
        'preferences/defaults'
        'preferences/preferences'

        ## Print
        'print/piper'

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
        'controllers/wallet/api/wallet_api_accounts_dialog_view_controller'
        'controllers/wallet/api/wallet_api_operations_dialog_view_controller'
        'controllers/wallet/api/wallet_api_addresses_dialog_view_controller'

        ## Coinkite
        'controllers/apps/coinkite/apps_coinkite_navigation_controller'
        'controllers/apps/coinkite/dashboard/apps_coinkite_dashboard_index_view_controller'
        'controllers/apps/coinkite/dashboard/apps_coinkite_dashboard_compatibility_view_controller'
        'controllers/apps/coinkite/settings/apps_coinkite_settings_index_dialog_view_controller'
        'controllers/apps/coinkite/keygen/apps_coinkite_keygen_index_dialog_view_controller'
        'controllers/apps/coinkite/keygen/apps_coinkite_keygen_processing_dialog_view_controller'
        'controllers/apps/coinkite/keygen/apps_coinkite_keygen_show_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_index_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_fetching_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_show_dialog_view_controller'
        'controllers/apps/coinkite/cosign/apps_coinkite_cosign_signing_dialog_view_controller'

        # Specs
        '../spec/utils/dongle/mock_dongle_manager'
        '../spec/utils/dongle/mock_dongle'
        '../spec/utils/storage/store_mock'

        '../spec/fixtures/fixtures_dongle'
        '../spec/fixtures/fixtures_transactions'
        '../spec/fixtures/fixtures_blocks'

        '../spec/spec_helper'
        '../spec/spec_navigation_controller'
        '../spec/spec_view_controller'
        '../spec/spec_index_view_controller'
        '../spec/spec_result_view_controller'

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
          '../spec/api/synced_rest_client_spec'
          '../spec/utils/storage/synced_store_spec'
          '../spec/utils/bitcoin/bip39_spec'
          '../spec/utils/formatters_spec'
          '../spec/utils/converters_spec'

          '../spec/i18n/i18n_spec'

          '../spec/m2fa/client_spec'
          '../spec/m2fa/m2fa_spec'

          '../spec/tasks/address_derivation_task_spec'
          '../spec/tasks/balance_task_spec'
          '../spec/tasks/operations_consumption_task_spec'
          '../spec/tasks/operations_synchronization_task_spec'
          '../spec/tasks/ticker_task_spec'
          '../spec/tasks/transaction_observer_task_spec'
          '../spec/tasks/wallet_layout_recovery_task_spec'

          '../spec/dongle/derivation_spec'

          '../spec/wallet/extended_public_key_spec'

          '../spec/database/sync_properties_spec'
          '../spec/utils/logger/log_spec'
          '../spec/utils/logger/secure_log_spec'
        ]
