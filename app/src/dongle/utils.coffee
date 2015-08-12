
_.extend ledger.dongle,
  # @return Return true if dongle is plugged and unblocked.
  isPluggedAndUnlocked: () ->
    ledger.app.dongle? && ledger.app.dongle.state == ledger.dongle.States.UNLOCKED

  # @return Return current unblocked dongle or throw error if dongle is not plugged or not unblocked.
  unlocked: () ->
    ledger.errors.throw(ledger.errors.DongleLocked) unless @isPluggedAndUnlocked()
    return ledger.app.dongle
