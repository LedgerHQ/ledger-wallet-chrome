return unless @ledger.nwjs?

_.extend (@ledger.nwjs.helpers ||= {}),

  fixCss: (selectorText) ->
    for stylesheet in document.styleSheets when stylesheet?
      for rule in stylesheet.rules when rule.selectorText?.match(selectorText)
        rule.style.backgroundImage = rule.style.backgroundImage.replace(/chrome-extension:.+extension_id__\/assets/g, '..')


`
    var gui = global.window.nwDispatcher.requireNwGui();
    if (process.platform === "darwin") {
        var mb = new gui.Menu({type: 'menubar'});
        mb.createMacBuiltin('RoboPaint', {
            hideEdit: false,
        });
        gui.Window.get().menu = mb;
    }
`