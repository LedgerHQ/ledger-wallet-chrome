@ledger =
      imports: [
        '../libs/jquery-2.1.1.min',
        '../libs/jquery.color',
        '../libs/underscore-min',
        '../libs/underscore.string.min',
        '../libs/signals.min',
        '../libs/crossroads.min',
        '../libs/spin.min',
        '../libs/sjcl',
        '../libs/jquery.selectric.min',
        '../public/tooltipster/js/jquery.tooltipster.min',

        'routes',

        'utils/log',
        'utils/string',
        'utils/render',
        'utils/event_emitter',
        'utils/http_client',
        'utils/url',
        'utils/easing',
        'utils/router',
        'utils/i18n',
        'utils/spinners',
        'utils/pin_codes',

        'utils/crypto/aes',
        'utils/crypto/sha256',

        'utils/storage/store',
        'utils/storage/chrome_store',
        'utils/storage/secure_store',
        'utils/storage/synced_store',
        'utils/storage/object_store',
        'utils/storage/storage',

        'managers/devices_manager'

        'base/model',
        'base/view_controller',
        'base/navigation_controller',

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

        ## Onboarding controllers
        'controllers/onboarding/onboarding_navigation_controller',
        # Device
        'controllers/onboarding/device/onboarding_device_plug_view_controller',
        'controllers/onboarding/device/onboarding_device_unplug_view_controller',
        'controllers/onboarding/device/onboarding_device_pin_view_controller',
        # Management
        'controllers/onboarding/management/onboarding_management_done_view_controller',
        'controllers/onboarding/management/onboarding_management_welcome_view_controller'
      ]