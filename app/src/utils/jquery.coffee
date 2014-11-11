
$.fn.extend
  # Once called the current DOM node cannot lose focus
  keepFocus: ->
    @blur =>
      setTimeout =>
        @focus()
      , 0

  # Once called the current DOM input node only allows numeric characters
  numberInput: ->
    @on 'keydown', (e) ->
      return if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) != -1 or (e.keyCode == 65 && e.ctrlKey == true) or (e.keyCode >= 35 && e.keyCode <= 39))
      if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105))
        e.preventDefault()