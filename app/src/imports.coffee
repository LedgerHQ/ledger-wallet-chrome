@ledger =
      imports: [
        '../libs/jquery-2.1.1.min',
        '../libs/underscore-min',
        '../libs/underscore.string.min',
        '../libs/signals.min',
        '../libs/crossroads.min',

        'routes',

        'utils/log',
        'utils/render',
        'utils/event_emitter',
        'utils/http_client',
        'utils/url',
        'utils/router',

        'managers/devices_manager'

        'base/model',
        'base/view_controller',
        'base/navigation_controller',


        ## Wallet controllers
        'controllers/wallet/wallet_navigation_controller',
        # Dashboard
        'controllers/wallet/dashboard/wallet_dashboard_index_view_controller'

        ## Onboarding controllers
        'controllers/onboarding/onboarding_navigation_controller',
        'controllers/onboarding/onboarding_plug_view_controller',
        'controllers/onboarding/onboarding_unplug_view_controller'
      ]