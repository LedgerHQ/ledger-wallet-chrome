@ledger.env = "prod"
@ledger.isProd = ledger.env == "prod"
@ledger.isDev = ledger.env == "dev"

@ledger.config ?= {}

@ledger.config.restClient ?= {}
@ledger.config.restClient.baseUrl = 'https://api02.ledgerwallet.com/'

@configureApplication = (app) ->
