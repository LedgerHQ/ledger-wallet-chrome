@ledger.utils ?= {}

Levels = {}
for level, i in ["NONE", "RAW", "FATAL", "ERROR", "WARN", "GOOD", "INFO", "VERB", "DEBUG", "TRACE", "ALL"]
  Levels[level] = i++

###
  Utility class for dealing with logs
###
class @ledger.utils.Logger
  @Levels: Levels

  @_loggers: {}
  @store: new ledger.storage.ChromeStore("logs")

#################################
# Class methods
#################################
  
  # @return [Q.Promise]
  @logs: (cb) ->
    d = ledger.defer(cb)
    @store.keys (keys) =>
      @store.get keys, (items) => d.resolve(_.values(items))
    d.promise

  # @return [legder.utils.Logger]
  @getLoggerByTag: (tag) ->
    @_loggers[tag] ?= new @(tag)

#################################
# Instance methods
#################################

  # Logger's constructor
  # @param [Boolean] level of the Logger
  constructor: (tag, @level=Levels.ALL) ->
    @_tag = tag
    @level = Levels.ALL if @level is true
    @level = Levels.None if @level is false
    @store = @constructor.store
    @constructor._loggers[tag] = this

  #################################
  # Accessors
  #################################

  # Sets the log level
  # @param [Boolean] active or not the logger.
  setLevel: (level) -> @level = level

  #
  levelName: (level=@level) -> _.invert(Levels)[level]

  # Sets the active state
  # @param [Boolean] active or not the logger.
  setActive: (active) -> @level = if active then Levels.INFO else Levels.NONE

  # Gets the current active state.
  # @return [Boolean] The current enabled flag.
  isActive: -> @level > Levels.NONE

  isFatal: -> @level >= Levels.FATAL
  isError: -> @level >= Levels.ERROR
  isErr: @prototype.isError
  isWarn: -> @level >= Levels.WARN
  isWarning: @prototype.isWarn
  isGood: -> @level >= Levels.GOOD
  isGood: @prototype.isSuccess
  isInfo: -> @level >= Levels.INFO
  isVerb: -> @level >= Levels.VERB
  isVerbose: @prototype.isVerb
  isDebug: -> @level >= Levels.DEBUG
  isTrace: -> @level >= Levels.TRACE

  #################################
  # Logging methods
  #################################

  fatal: (args...) -> @_log(Levels.FATAL, args...)
  error: (args...) -> @_log(Levels.ERROR, args...)
  err: @prototype.error
  warn: (args...) -> @_log(Levels.WARN, args...)
  warning: @prototype.warn
  good: (args...) -> @_log(Levels.GOOD, args...)
  success: @prototype.good
  info: (args...) -> @_log(Levels.INFO, args...)
  verb: (args...) -> @_log(Levels.VERB, args...)
  verbose: @prototype.verb
  debug: (args...) -> @_log(Levels.DEBUG, args...)
  raw: (args...) -> @_log(Levels.RAW, args...)
  trace: (args...) -> @_log(Levels.TRACE, args...)

  #################################
  # Stored Logs
  #################################

  # Clear logs from entries older than 24h
  clear: ->
    @store.keys (keys) =>
      now = new Date().getTime()
      @store.remove(key) for key in keys when (now - key > 86400000) # 86400000ms => 24h

  # Retreive saved logs
  # @param [Function] cb A callback invoked once we get the logs as an array
  # @return [Q.Promise]
  logs: (cb) ->
    @constructor.logs().then (logs) =>
      logs = logs.filter (l) => l.tag is @tag
      cb?(logs)
      logs

  # Save a log in chrome local storage
  # @private
  # @param [String] msg Message to log.
  # @param [String] msgType Log level.
  _storeLog: (msg, msgType) ->
      now = new Date()
      log = {}
      log[now.getTime()] = date: now.toUTCString(), type: msgType, msg: msg, tag: @_tag
      @clear()
      @store.set(log)

  #################################
  # Protected. Formatting methods
  #################################

  ###
  Generic log function. Add header with usefull informations + log to console + store in DB.

  @exemple Simple call 
    @_log(Levels.VERB, "Entering in function with args", arg1, arg2)

  @param [Number] level defined in Levels.
  @return undefined
  ###
  _log: (level, args...) ->
    return unless level <= @level
    @_storeLog(@_stringify(args...), @levelName(level))
    if window.ledger.isDev
      args = (if level != Levels.RAW then [@_header(level)] else []).concat(args)
      @_consolify(level, args...)

  ###
  Add usefull informations like level and timestamp.
  @param [Number] level
  @return String
  ###
  _header: (level, date) ->
    sprintf('[%s][%5s]', @_timestamp(date), @levelName(level))

  ###
  @param [Date] date
  @return String
  ###
  _timestamp: (date=new Date()) ->
    sprintf("%s.%03d", date.toLocaleTimeString(), date.getMilliseconds())

  ###
  Convert correctly arguments into string.
  @return String
  ###
  _stringify: (args...) ->
    formatter = if typeof args[0] is 'string' then ""+args.shift().replace(/%/,'%%') else ""
    params = for arg in args
      formatter += " %s"
      if (! arg?) || typeof arg == 'string' || typeof arg == 'number' || typeof arg == 'boolean'
        arg
      else if typeof arg == 'object' && (arg instanceof RegExp || arg instanceof Date)
        arg
      else if typeof arg == 'object' && arg instanceof HTMLElement
        "HTMLElement." + arg.tagName
      else # Arrays and Hashs
        try
          JSON.stringify(arg)
        catch err
          "<< stringify error: #{err} >>"
    sprintf(formatter, params...)

  ###
  Add color depending of level.
  @return undefined
  ###
  _consolify: (level, args...) ->
    args = [].concat(args)

    # Add color
    if typeof args[0] is 'string'
      args[0] = "%c" + args[0].replace(/%/,'%%')
    else
      args.splice 0, 0, "%c"
    args.splice 1, 0, switch level
      when Levels.FATAL, Levels.ERROR then 'color: #f00'
      when Levels.WARN then 'color: #f60'
      when Levels.INFO then 'color: #00f'
      when Levels.GOOD then 'color: #090'
      when Levels.DEBUG then 'color: #444'
      when Levels.TRACE then 'color: #888'
      else 'color: #000'

    # Add arguments catchers to colorify strings
    for arg in args[2..-1]
      args[0] += if typeof arg is 'string' then " %s"
      else if typeof arg is 'number' || typeof arg is 'boolean' then " %o"
      else if typeof arg is 'object' && arg instanceof RegExp then " %o"
      else if typeof arg is 'object' && arg instanceof Date then " %s"
      else if typeof arg is 'object' && arg instanceof window.HTMLElement then " %o"
      else " %O"

    method = switch level
      when Levels.FATAL, Levels.ERROR then "error"
      when Levels.WARN then "warn"
      when Levels.INFO then "info"
      when Levels.DEBUG then "debug"
      else "log"

    console[method](args...)

ledger.utils.logger = new ledger.utils.Logger("DeprecatedLogger", true)

`
var sprintf = (function() {
  var e = {};
  function r(e){return Object.prototype.toString.call(e).slice(8,-1).toLowerCase()}function i(e,t){for(var n=[];t>0;n[--t]=e);return n.join("")}var t=function(){return t.format.call(null,t.parse(arguments[0]),arguments)};t.format=function(e,n){var s=1,o=e.length,u="",a,f=[],l,c,h,p,d,v;for(l=0;l<o;l++){u=r(e[l]);if(u==="string")f.push(e[l]);else if(u==="array"){h=e[l];if(h[2]){a=n[s];for(c=0;c<h[2].length;c++){if(!a.hasOwnProperty(h[2][c]))throw t('[sprintf] property "%s" does not exist',h[2][c]);a=a[h[2][c]]}}else h[1]?a=n[h[1]]:a=n[s++];if(/[^s]/.test(h[8])&&r(a)!="number")throw t("[sprintf] expecting number but found %s",r(a));switch(h[8]){case"b":a=a.toString(2);break;case"c":a=String.fromCharCode(a);break;case"d":a=parseInt(a,10);break;case"e":a=h[7]?a.toExponential(h[7]):a.toExponential();break;case"f":a=h[7]?parseFloat(a).toFixed(h[7]):parseFloat(a);break;case"o":a=a.toString(8);break;case"s":a=(a=String(a))&&h[7]?a.substring(0,h[7]):a;break;case"u":a>>>=0;break;case"x":a=a.toString(16);break;case"X":a=a.toString(16).toUpperCase()}a=/[def]/.test(h[8])&&h[3]&&a>=0?"+"+a:a,d=h[4]?h[4]=="0"?"0":h[4].charAt(1):" ",v=h[6]-String(a).length,p=h[6]?i(d,v):"",f.push(h[5]?a+p:p+a)}}return f.join("")},t.parse=function(e){var t=e,n=[],r=[],i=0;while(t){if((n=/^[^\x25]+/.exec(t))!==null)r.push(n[0]);else if((n=/^\x25{2}/.exec(t))!==null)r.push("%");else{if((n=/^\x25(?:([1-9]\d*)\$|\(([^\)]+)\))?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(t))===null)throw"[sprintf] huh?";if(n[2]){i|=1;var s=[],o=n[2],u=[];if((u=/^([a-z_][a-z_\d]*)/i.exec(o))===null)throw"[sprintf] huh?";s.push(u[1]);while((o=o.substring(u[0].length))!=="")if((u=/^\.([a-z_][a-z_\d]*)/i.exec(o))!==null)s.push(u[1]);else{if((u=/^\[(\d+)\]/.exec(o))===null)throw"[sprintf] huh?";s.push(u[1])}n[2]=s}else i|=2;if(i===3)throw"[sprintf] mixing positional and named placeholders is not (yet) supported";r.push(n)}t=t.substring(n[0].length)}return r};var n=function(e,n,r){return r=n.slice(0),r.splice(0,0,e),t.apply(null,r)};e.sprintf=t,e.vsprintf=n;
  return e.sprintf;
})();
`
@ledger.utils.sprintf = sprintf
