ledger.fup ?= {}
ledger.fup.versions ?= {}

_.extend ledger.fup.versions,

  Nano:
    CurrentVersion:
      Bootloader: [0, (1 << 16) + (3 << 8) + (16) ]
      Os: [ 0x20, (1 << 16) + (0 << 8) + (0) ]
      Reloader: [0, (1 << 16) + (33 << 8) + (0) ]
      Beta: yes

