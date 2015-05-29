class @AccountTag extends ledger.database.Model
  do @init

  @has many: 'accounts', forOne: 'account_tag'
  @index 'uid', sync: yes, unique: yes, auto: yes
  @sync 'name'
  @sync 'color'