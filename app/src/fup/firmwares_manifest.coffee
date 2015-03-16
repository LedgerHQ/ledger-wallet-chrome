ledger.fup ?= {}
ledger.fup.versions ?= {}

_.extend ledger.fup.versions,

  Nano:
    CurrentVersion:
      Bootloader: [0, (1 << 16) + (3 << 8) + (16) ]
      Os: [ 0x20, (1 << 16) + (0 << 8) + (0) ]
      Reloader: [0, (1 << 16) + (33 << 8) + (0) ]
      Beta: yes


ledger.fup.updates ?= {}

_.extend ledger.fup.updates,

  OS_INIT: [
    [ [0, (1 << 16) + (4 << 8) + (10)],   INIT_01410],
    [ [0, (1 << 16) + (4 << 8) + (11)],   INIT_01411],
    [ [0, (1 << 16) + (4 << 8) + (12)],   INIT_01412],
    [ [0, (1 << 16) + (4 << 8) + (13)],   INIT_01413],
    [ [0, (1 << 16) + (4 << 8) + (14)],   INIT_01414],
    [ [0x20, (1 << 16) + (0 << 8) + (0)], INIT_LW_1100]
  ];
