class @Account extends Model
  do @init

  @hasOne operation: 'Operation'
  @hasMany operations: 'Operations'

