@ledger.env = "prod"
@ledger.isProd = ledger.env == "prod"
@ledger.isDev = ledger.env == "dev"

@ledger.config ?= {}
_.extend @ledger.config,
  m2fa:
    baseUrl: 'https://api02.ledgerwallet.com/'
  restClient:
    baseUrl: 'wss://ws02.ledgerwallet.com/2fa/channels'
  syncRestClient:
    pullIntervalDelay: 10000
    pullThrottleDelay: 1000
    pushDebounceDelay: 1000

@configureApplication = (app) ->
