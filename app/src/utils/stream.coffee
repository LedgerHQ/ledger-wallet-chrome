
class @Stream extends EventEmitter

  @Type:
    STRING: 0,
    OBJECT: 1

  constructor: (type = Stream.Type.OBJECT) ->
    @_open = false
    @_type = type
    if type is Stream.Type.OBJECT
      @_buffer = []
    else
      @_buffer = ''

  open: () ->
    @_open = yes
    @emit 'open'

  close: () ->
    @_open = no
    @emit 'close'

  write: (data) ->
    if @_type is Stream.Type.OBJECT
      @_buffer.push data
    else
      @_buffer += data
    @_output?.write @read()
    @emit 'data'

  read: (n = -1) ->
    n = @_buffer.length if n < 0
    l = n
    out = (c for c in @_buffer when l-- > 0)
    if @_type is Stream.Type.OBJECT
      @_buffer.splice 0, n
      out
    else
      @_buffer = _.str.splice(@_buffer, 0, n)
      out.join ''

  pipe: (stream) ->
    @_output = stream
    stream

  isOpen: () -> @_open

  isClosed: () -> not @isOpen()

  hasData: () -> @_buffer.length > 0
