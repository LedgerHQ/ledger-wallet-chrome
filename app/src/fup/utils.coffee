
ledger.fup ?= {}
ledger.fup.utils ?= {}

_.extend ledger.fup.utils,

  compareVersions: (v1, v2) ->
    new ledger.utils.ComparisonResult v1, v2, (v1, v2) ->
      if v1[0] == v2[0] and v1[1] == v2[1]
        0
      else if v1[0] < v2[0] or (v1[0] == v2[0] and v1[1] < v2[1])
        -1
      else if v1[0] > v2[0] or (v1[0] == v2[0] and v1[1] > v2[1])
        1

  versionToString: (v) ->
    return null unless v?
    version = v[1]
    info = if v[0] is 0 then "HW1" else "Ledger OS"
    "#{info} #{(version >> 16) & 0xff}.#{(version >> 8) & 0xff}.#{version & 0xff}"
