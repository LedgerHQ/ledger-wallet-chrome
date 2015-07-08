ledger.preferences ||= {}
ledger.preferences.fees ||= {}

_.extend ledger.preferences.fees,

  Levels:
    Fast:
      id: '20000'
      numberOfBlock: 1
      defaultValue: 20000


    Normal:
      id: '10000'
      numberOfBlock: 3
      defaultValue: 10000

    Slow:
      id: '1000'
      numberOfBlock: 6
      defaultValue: 1000


  getLevelFromId: (id) -> _(ledger.preferences.fees.Levels).find (l) -> l.id is id