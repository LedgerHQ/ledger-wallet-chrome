@ledger =
    imports: [
      '../libs/jquery-2.1.1.min',
      '../libs/underscore-min',
      '../libs/underscore.string.min',

      'utils/log',
      'utils/render',
      'utils/event_emitter',
      'utils/http_client',

      'base/model',
      'base/view_controller',
      'base/navigation_controller',

      'controllers/onboarding_navigation_controller',
      'controllers/wallet_navigation_controller'
    ]