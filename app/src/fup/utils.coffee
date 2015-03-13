
ledger.fup ?= {}
ledger.fup.utils ?= {}

_.extend ledger.fup.utils,

  compareVersions: (v1, v2) ->
    new ledger.utils.ComparisonResult v1, v2, (v1, v2) ->
      if v1[0] == v2[0] and v1[1] == v2[1]
        0
      else if v1[0] == 0 and v2[0] != 0
        -1
      else if v1[1] > v2[1]
        1
