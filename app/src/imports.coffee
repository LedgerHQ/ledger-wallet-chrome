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

        'base/model',
        'base/view_controller',
        'base/navigation_controller',

        'controllers/wallet_navigation_controller',
        'controllers/onboarding_navigation_controller',

        # dashboard controllers
        'controllers/dashboard_index_view_controller'
      ]