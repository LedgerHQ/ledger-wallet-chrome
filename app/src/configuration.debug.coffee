@configureApplication = (app) ->
  chrome.commands.onCommand.addListener (command) =>
    switch command
      when 'reload-page' then do app.reloadUi
      when 'reload-application' then do app.reload