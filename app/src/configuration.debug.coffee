@ledger.env = "dev"
@ledger.isProd = ledger.env == "prod"
@ledger.isDev = ledger.env == "dev"

@ledger.config ?= {}

@ledger.config.restClient ?= {}
@ledger.config.restClient.baseUrl = 'https://api02.ledgerwallet.com/'

@configureApplication = (app) ->
  chrome.commands.onCommand.addListener (command) =>
    switch command
      when 'reload-page' then do app.reloadUi
      when 'reload-application' then do app.reload
