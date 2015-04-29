`(function(jQuery) {

jQuery.EventEmitter = {
  _JQInit: function() {
    this._JQ = jQuery(this);
  },
  emit: function(evt, data) {
    !this._JQ && this._JQInit();
    this._JQ.trigger(evt, data);
  },
  once: function(evt, handler) {
    !this._JQ && this._JQInit();
    this._JQ.one(evt, handler);
  },
  on: function(evt, handler) {
    !this._JQ && this._JQInit();
    this._JQ.bind(evt, handler);
  },
  off: function(evt, handler) {
    !this._JQ && this._JQInit();
    this._JQ.unbind(evt, handler);
  }
};

}(jQuery));`

_EventEmitter = ->
jQuery.extend _EventEmitter.prototype, jQuery.EventEmitter

class @EventEmitter

  _eventEmitter = null

  _getEventEmitter: ->
    @_eventEmitter = new _EventEmitter() unless @_eventEmitter?
    @_eventEmitter

  emit: (event, data) ->
    @_getEventEmitter().emit event, data

  once: (event, handler) ->
    @off event, handler
    @_getEventEmitter().once event, handler

  on: (event, handler) ->
    @off event, handler
    @_getEventEmitter().on event, handler

  off: (event, handler) ->
    @_getEventEmitter().off event, handler