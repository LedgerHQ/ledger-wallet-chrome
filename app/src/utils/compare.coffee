
ledger.utils ?= {}

###
  Utility class for dealing with comparison result.
###
class ledger.utils.ComparisonResult

  ###
    @param [Any] lhs The left hand side object of the comparison.
    @param [Any] rhs The right hand side object of the comparison.
    @param [Function] comparisonHandler The function that performs the comparison. It takes lhs and rhs in parameter and returns
      an integer. The result must be equal to 0 if lhs and rhs are equals, if lhs is greater than rhs it must be positive and non null.
      Finally the result must be negative and non null if lhs is less than rhs.
  ###
  constructor: (lhs, rhs, comparisonHandler) ->
    @_handler = comparisonHandler
    @_lhs = lhs
    @_rhs = rhs

  ###
    Performs the comparison by using the comparisonHandler.
    @see ledger.utils.ComparisonResult#constructor
  ###
  compare: () -> @_handler(@_lhs, @_rhs)

  ###
    Checks if lhs and rhs are equal
    @return [Boolean] True if lhs and rhs are equal, false otherwise
  ###
  eq: () -> @compare() == 0

  ###
    Checks if lhs is less than rhs.
    @return [Boolean] True if lhs is less than rhs, false otherwise
  ###
  lt: () -> @compare() < 0

  ###
    Checks if lhs and rhs are equal or if lhs is less than rhs
    @return [Boolean] True if lhs and rhs are equal or if lhs is less than rhs, false otherwise
  ###
  lte: () -> @compare() <= 0

  ###
    Checks if lhs is greater than rhs
    @return [Boolean] True if lhs is greater than rhs, false otherwise
  ###
  gt: () -> @compare() > 0

  ###
    Checks if lhs and rhs are equal or if lhs is greater than rhs
    @return [Boolean] True if lhs and rhs are equal or if lhs is greater than rhs, false otherwise
  ###
  gte: () -> @compare() >= 0
