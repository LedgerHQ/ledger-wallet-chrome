_.extend @ledger.config,
  defaultLoggingLevel:
    Connected:
      Enabled: 'ALL'
      Disabled: 'ALL'
    Disconnected:
      Enabled: 'ALL'
      Disabled: 'ALL'

Q.longStackSupport = true
