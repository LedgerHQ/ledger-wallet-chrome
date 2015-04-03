@ledger.env = "prod"
@ledger.isProd = ledger.env == "prod"
@ledger.isDev = ledger.env == "dev"

@ledger.config ?= {}
_.extend @ledger.config,
  m2fa:
    baseUrl: 'wss://ws.ledgerwallet.com/2fa/channels'
  restClient:
    baseUrl: 'https://api.ledgerwallet.com/'
  syncRestClient:
    pullIntervalDelay: 10000
    pullThrottleDelay: 1000
    pushDebounceDelay: 1000
  enableLogging: no

@configureApplication = (app) ->
