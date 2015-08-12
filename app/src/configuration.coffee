
@ledger.env = if ledger.build.Mode is 'debug' then 'dev' else 'prod'
@ledger.isProd = ledger.env == "prod"
@ledger.isDev = ledger.env == "dev"

@ledger.config ?= {}
_.extend @ledger.config,
  m2fa:
    baseUrl: 'ws://apitest.ledgerwallet.com/2fa/channels'
  restClient:
    baseUrl: 'http://apitest.ledgerwallet.com/'
  syncRestClient:
    pullIntervalDelay: 60000
    pullThrottleDelay: 1000
    pushDebounceDelay: 1000
  defaultLoggerDaysMax: 2
  btchipDebug: false
  defaultLoggingLevel:
    Connected:
      Enabled: 'ALL'
      Disabled: 'NONE'
    Disconnected:
      Enabled: 'ALL'
      Disabled: 'ALL'
  network: ledger.bitcoin.Networks[ledger.build.Network]
  defaultAddressDiscoveryGap: 20
  defaultAccountDiscoveryGap: 1

Q.longStackSupport = true

@configureApplication = (app) ->
  _.extend ledger.config,
    defaultLoggingLevel:
      Connected:
        Enabled: ledger.utils.Logger.Levels[ledger.config.defaultLoggingLevel.Connected.Enabled]
        Disabled: ledger.utils.Logger.Levels[ledger.config.defaultLoggingLevel.Connected.Disabled]
      Disconnected:
        Enabled: ledger.utils.Logger.Levels[ledger.config.defaultLoggingLevel.Disconnected.Enabled]
        Disabled: ledger.utils.Logger.Levels[ledger.config.defaultLoggingLevel.Disconnected.Disabled]
