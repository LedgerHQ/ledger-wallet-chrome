describe "Log Writer/Reader", ->

  lw = null
  lr = null

  @_errorHandler = (e) ->
    fail "FileSystem Error. name: #{e.name} // message: #{e.message}"
    l new Error().stack

  beforeEach (done) ->
    ledger.utils.Log.deleteAll TEMPORARY, ->
      lr = new ledger.utils.LogReader(2, TEMPORARY)
      lw = new ledger.utils.LogWriter(2, TEMPORARY)
      do done


  it "should write in correct order", (done) ->
    for str in [0...50]
      line = "date lorem ipsum blabla msg outing to bla - test #{str}"
      lw.write line
    lw.getFlushPromise().then ->
      lr.read (logs) ->
        for log, i in logs
          expect(log).toBe("date lorem ipsum blabla msg outing to bla - test #{i}")
        expect(logs.length).toBe(50)
        done()


  it "should read several sorted log files", (done) ->
    files = []
    for fileCounter in [0...10]
      files.push
          messages: ("file #{fileCounter}_random data #{msgCounter}" for msgCounter in [0...10])
          filename: "non_secure_#{moment().subtract(fileCounter, 'day').format('YYYY_MM_DD')}.log"

    # Write
    writeLoop = (writer, index, arr, callback) ->
      entry = arr[index]
      return callback?() unless entry?
      writer.onwriteend = -> writeLoop(writer, index + 1, arr, callback)
      writer.write(new Blob(['\n' + entry], {type:'text/plain'}))

    filesIteration = (fs, index, arr, callback) ->
      file = arr[index]
      return callback?() unless file?
      fs.root.getFile file.filename, {create: true}, (fileEntry) ->
        fileEntry.createWriter (fileWriter) ->
          fileWriter.onerror = (e) ->
            l "Write failed"
            callback?(null, new Error)
          writeLoop fileWriter, 0, file.messages, ->
            filesIteration fs, index + 1, arr, callback

    # Read
    ledger.utils.Log.getFs(TEMPORARY).then (fs) ->
      filesIteration fs, 0, files, ->
        lr.read (resLogs) ->
          # Checking
          expect(resLogs.length).toBe(30)
          i = 0
          for file in [0...3]
            for data in [0...10]
              expect(resLogs[i++]).toBe("file #{file}_random data #{data}")
          done()
    .done()

