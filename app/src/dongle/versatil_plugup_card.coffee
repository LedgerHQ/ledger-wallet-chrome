

window.ledger ?= {}
ledger.dongle ?= {}
###
************************************************************************
Copyright (c) 2013-2014 UBINITY SAS

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*************************************************************************
###

ledger.dongle.VersatilePlugUpCard = Class.extend(Card,
  initialize: (terminal, device, ledgerTransport, timeout) ->
    if typeof timeout == 'undefined'
      timeout = 0
    @winusb = device['transport'] == 'winusb'
    @device = new chromeDevice(device)
    @terminal = terminal
    @timeout = timeout
    @ledger = ledgerTransport
    @exchangeStack = []
    return
  connect_async: ->
    currentObject = this
    @device.open_async().then (result) ->
      currentObject.connection = true
      currentObject
  getTerminal: ->
    @terminal
  getAtr: ->
    new ByteString('', HEX)
  beginExclusive: ->
  endExclusive: ->
  openLogicalChannel: (channel) ->
    throw 'Not supported'
    return
  exchange_async: (apdu, retru)

  exchange_async_fido: (apdu, returnLength) ->

  exchange_async_ledger: (apdu, returnLength) ->

    wrapCommandAPDU = (channel, command, packetSize) ->
      sequenceIdx = 0
      offset = 0
      header = Convert.toHexByte(channel >> 8 & 0xff)
      header += Convert.toHexByte(channel & 0xff)
      header += Convert.toHexByte(0x05)
      header += Convert.toHexByte(sequenceIdx >> 8 & 0xff)
      header += Convert.toHexByte(sequenceIdx & 0xff)
      sequenceIdx++
      header += Convert.toHexByte(command.length >> 8 & 0xff)
      header += Convert.toHexByte(command.length & 0xff)
      blockSize = if command.length > packetSize - 7 then packetSize - 7 else command.length
      result = new ByteString(header, HEX)
      result = result.concat(command.bytes(offset, blockSize))
      offset += blockSize
      while offset != command.length
        header = Convert.toHexByte(channel >> 8 & 0xff)
        header += Convert.toHexByte(channel & 0xff)
        header += Convert.toHexByte(0x05)
        header += Convert.toHexByte(sequenceIdx >> 8 & 0xff)
        header += Convert.toHexByte(sequenceIdx & 0xff)
        sequenceIdx++
        blockSize = if command.length - offset > packetSize - 5 then packetSize - 5 else command.length - offset
        result = result.concat(new ByteString(header, HEX))
        result = result.concat(command.bytes(offset, blockSize))
        offset += blockSize
      padding = ''
      paddingSize = packetSize - (result.length)
      i = 0
      while i < paddingSize
        padding += '00'
        i++
      result.concat new ByteString(padding, HEX)

    currentObject = this
    if !(apdu instanceof ByteString)
      throw 'Invalid parameter'
    if !@connection
      throw 'Connection is not open'
    if currentObject.ledger
      apdu = wrapCommandAPDU(0x0101, apdu, 64)
    deferred = Q.defer()
    exchangeTimeout = undefined
    deferred.promise.apdu = apdu
    deferred.promise.returnLength = returnLength
    if @timeout != 0
      exchangeTimeout = setTimeout((->
        deferred.reject 'timeout'
        return
      ), @timeout)
    # enter the exchange wait list
    currentObject.exchangeStack.push deferred
    if currentObject.exchangeStack.length == 1

      processNextExchange = ->
        `var deferred`
        # don't pop it now, to avoid multiple at once
        deferred = currentObject.exchangeStack[0]
        # notify graphical listener
        if typeof currentObject.listener != 'undefined'
          currentObject.listener.begin()

        performExchange = ->
          if currentObject.winusb
            currentObject.device.send_async(deferred.promise.apdu.toString(HEX)).then (result) ->
              currentObject.device.recv_async 512
          else
            deferredHidSend = Q.defer()
            offsetSent = 0
            firstReceived = true
            toReceive = 0

            unwrapResponseAPDU = (channel, data, packetSize) ->
              offset = 0
              sequenceIdx = 0
              if typeof data == 'undefined' or data.length < 7 + 5
                return
              if data.byteAt(offset++) != (channel >> 8 & 0xff)
                throw 'Invalid channel'
              if data.byteAt(offset++) != (channel & 0xff)
                throw 'Invalid channel'
              if data.byteAt(offset++) != 0x05
                throw 'Invalid tag'
              if data.byteAt(offset++) != (sequenceIdx >> 8 & 0xff)
                throw 'Invalid sequence'
              if data.byteAt(offset++) != (sequenceIdx & 0xff)
                throw 'Invalid sequence'
              responseLength = (data.byteAt(offset) << 8) + data.byteAt(offset + 1)
              offset += 2
              if data.length < 7 + responseLength
                return
              blockSize = if responseLength > packetSize - 7 then packetSize - 7 else responseLength
              result = data.bytes(offset, blockSize)
              offset += blockSize
              while result.length != responseLength
                sequenceIdx++
                if offset == data.length
                  return
                if data.byteAt(offset++) != (channel >> 8 & 0xff)
                  throw 'Invalid channel'
                if data.byteAt(offset++) != (channel & 0xff)
                  throw 'Invalid channel'
                if data.byteAt(offset++) != 0x05
                  throw 'Invalid tag'
                if data.byteAt(offset++) != (sequenceIdx >> 8 & 0xff)
                  throw 'Invalid sequence'
                if data.byteAt(offset++) != (sequenceIdx & 0xff)
                  throw 'Invalid sequence'
                blockSize = if responseLength - (result.length) > packetSize - 5 then packetSize - 5 else responseLength - (result.length)
                result = result.concat(data.bytes(offset, blockSize))
                offset += blockSize
              result

            received = new ByteString('', HEX)

            sendPart = ->
              if offsetSent == deferred.promise.apdu.length
                return receivePart()
              blockSize = if deferred.promise.apdu.length - offsetSent > 64 then 64 else deferred.promise.apdu.length - offsetSent
              block = deferred.promise.apdu.bytes(offsetSent, blockSize)
              padding = ''
              paddingSize = 64 - (block.length)
              i = 0
              while i < paddingSize
                padding += '00'
                i++
              if padding.length != 0
                block = block.concat(new ByteString(padding, HEX))
              currentObject.device.send_async(block.toString(HEX)).then((result) ->
                offsetSent += blockSize
                sendPart()
              ).fail (error) ->
                deferredHidSend.reject error
                return

            receivePart = ->
              if !currentObject.ledger
                currentObject.device.recv_async(64).then((result) ->
                  received = received.concat(new ByteString(result.data, HEX))
                  if firstReceived
                    firstReceived = false
                    if received.length == 2 or received.byteAt(0) != 0x61
                      deferredHidSend.resolve
                        resultCode: 0
                        data: received.toString(HEX)
                    else
                      toReceive = received.byteAt(1)
                      if toReceive == 0
                        toReceive == 256
                      toReceive += 2
                  if toReceive < 64
                    deferredHidSend.resolve
                      resultCode: 0
                      data: received.toString(HEX)
                  else
                    toReceive -= 64
                    return receivePart()
                  return
                ).fail (error) ->
                  deferredHidSend.reject error
                  return
              else
                currentObject.device.recv_async(64).then((result) ->
                  received = received.concat(new ByteString(result.data, HEX))
                  response = unwrapResponseAPDU(0x0101, received, 64)
                  if typeof response == 'undefined'
                    return receivePart()
                  else
                    deferredHidSend.resolve
                      resultCode: 0
                      data: response.toString(HEX)
                  return
                ).fail (error) ->
                  deferredHidSend.reject error
                  return

            sendPart()
            deferredHidSend.promise

        performExchange().then((result) ->
          resultBin = new ByteString(result.data, HEX)
          if !currentObject.ledger
            if resultBin.length == 2 or resultBin.byteAt(0) != 0x61
              deferred.promise.SW1 = resultBin.byteAt(0)
              deferred.promise.SW2 = resultBin.byteAt(1)
              deferred.promise.response = new ByteString('', HEX)
            else
              size = resultBin.byteAt(1)
              # fake T0
              if size == 0
                size = 256
              deferred.promise.response = resultBin.bytes(2, size)
              deferred.promise.SW1 = resultBin.byteAt(2 + size)
              deferred.promise.SW2 = resultBin.byteAt(2 + size + 1)
          else
            deferred.promise.SW1 = resultBin.byteAt(resultBin.length - 2)
            deferred.promise.SW2 = resultBin.byteAt(resultBin.length - 1)
            deferred.promise.response = resultBin.bytes(0, resultBin.length - 2)
          deferred.promise.SW = (deferred.promise.SW1 << 8) + deferred.promise.SW2
          currentObject.SW1 = deferred.promise.SW1
          currentObject.SW2 = deferred.promise.SW2
          currentObject.SW = deferred.promise.SW
          if typeof currentObject.logger != 'undefined'
            currentObject.logger.log currentObject.terminal.getName(), 0, deferred.promise.apdu, deferred.promise.response, deferred.promise.SW
          # build the response
          if @timeout != 0
            clearTimeout exchangeTimeout
          deferred.resolve deferred.promise.response
          return
        ).fail((err) ->
          if @timeout != 0
            clearTimeout exchangeTimeout
          deferred.reject err
          return
        ).finally ->
          # notify graphical listener
          if typeof currentObject.listener != 'undefined'
            currentObject.listener.end()
          # consume current promise
          currentObject.exchangeStack.shift()
          # schedule next exchange
          if currentObject.exchangeStack.length > 0
            processNextExchange()
          return
        return

      #processNextExchange
      # schedule next exchange
      processNextExchange()
    # the exchangeStack will process the promise when possible
    deferred.promise
  reset: (mode) ->
  disconnect_async: (mode) ->
    currentObject = this
    if !@connection
      return
    @device.close_async().then (result) ->
      currentObject.connection = false
      return
  getSW: ->
    @SW
  getSW1: ->
    @SW1
  getSW2: ->
    @SW2
  setCommandDelay: (delay) ->
# unsupported - use options
    return
  setReportDelay: (delay) ->
# unsupported - use options
    return
  getCommandDelay: ->
# unsupported - use options
    0
  getReportDelay: ->
# unsupported - use options
    0
)


