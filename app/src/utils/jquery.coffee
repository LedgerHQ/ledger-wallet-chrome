
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

  # Once called the current DOM input node only allow ammount formatted content
  amountInput: ->
    @on 'keydown', (e) ->

      # Check if it already contains a decimal point
      if (@value.indexOf('.') != -1 or @value.length == 0) and e.keyCode == 110
        e.preventDefault
        return no
      l e
      return if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) != -1 or (e.keyCode == 65 && (e.ctrlKey is on or e.metaKey is on)) or (e.keyCode >= 35 && e.keyCode <= 39) or (e.keyCode == 86 && (e.ctrlKey is on or e.metaKey is on)) or (e.keyCode == 67 && (e.ctrlKey is on or e.metaKey is on)))
      if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105))
        e.preventDefault()

    @on 'input', () ->
      l @value.indexOf('.'), @value.length
      decimalPointIndex = @value.indexOf('.')
      if decimalPointIndex != -1 and @value.length - decimalPointIndex > 8
        @value = @value.substring(0, @value.indexOf('.') + 8)
      if (/[^\.0-9]/).test(@value)
        @value = @value.replace(/[^\.0-9]/g, '')
      if @value.indexOf('.') != @value.lastIndexOf('.')
        parts = @value.split('.')
        parts.splice(parts.length - 1, 0, '.')
        @value = parts.join('')
      if @value.indexOf('.') == 0
        @value = ''