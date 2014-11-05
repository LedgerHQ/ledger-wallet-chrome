@ledger =
      imports: [
        '../libs/jquery-2.1.1.min',
        '../libs/underscore-min',
        '../libs/underscore.string.min',
        '../libs/signals.min',
        '../libs/crossroads.min',
        '../libs/spin.min',

        'routes',

        'utils/log',
        'utils/string',
        'utils/render',
        'utils/event_emitter',
        'utils/http_client',
        'utils/url',
        'utils/router',
        'utils/i18n',
        'utils/spinners',
        'utils/pin_codes',

        'utils/storage/store',
        'utils/storage/persistent_store',
        'utils/storage/synchronized_store',
        'utils/storage/storage',

        'managers/devices_manager'

        'base/model',
        'base/view_controller',
        'base/navigation_controller',


        ## Wallet controllers
        'controllers/wallet/wallet_navigation_controller',
        # Dashboard
        'controllers/wallet/dashboard/wallet_dashboard_index_view_controller',

        ## Onboarding controllers
        'controllers/onboarding/onboarding_navigation_controller',
        # Device
        'controllers/onboarding/device/onboarding_device_plug_view_controller',
        'controllers/onboarding/device/onboarding_device_unplug_view_controller',
        'controllers/onboarding/device/onboarding_device_pin_view_controller',
        # Management
        'controllers/onboarding/management/onboarding_management_done_view_controller',
        'controllers/onboarding/management/onboarding_management_welcome_view_controller',
        'controllers/onboarding/management/onboarding_management_locked_view_controller',
        'controllers/onboarding/management/onboarding_management_pin_view_controller'
      ]