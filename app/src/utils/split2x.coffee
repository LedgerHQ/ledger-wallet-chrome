_txoledger.split2x ?= {}

class ledger.split2x

  @getCoinbasesUtxo2x: () ->
    _txo = {}
    _limitDepth = 10
    _address = "1Hq79PZF2KwfUaXBkUSTJ6cXRTVQCQHhWF"
    _blockHash = "0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
    _syncToken = null
    _restClient = new ledger.api.TransactionsRestClient( -> 'segwit2x')

    _recoverLastState: () ->
      d = ledger.defer()
      ledger.storage.global.splitUtxo.get 'txo', (result) =>
        if result?
          _txo = result
        ledger.storage.global.splitUtxo.get 'blockHash', (result) =>
          if result?
            _blockHash = result
        d.resolve(yes)
      d.promise

    _finalize: ->
      utxo  = []
      for hash, txo in @_txo
        for index, output in txo
          if !output.spent?
            utxo.push(output)
      utxo

    _prune: (txo, depth) ->
      if !depth?
        depth = 0
      if @_txo[txo.spent]?
        for index, txo2 in @_txo[txo.spent]
          if depth > @_limitDepth
            delete @_txo[txo.spent][index]
          @_prune(txo2, depth+1)

    _filterUtxo: (new_txs) ->
      for tx in new_txs
        for output in tx.outputs
          if output.address == @_address
            _txo[tx.hash][output.output_index] = output
            _txo[tx.hash][output.output_index].confirmed = tx.block?
        for input in tx.inputs
          if input.address == _address
            if tx.block?
              delete _txo[input.output_hash][input.output_index]
            else
              _txo[input.output_hash][input.output_index].spent = tx.hash

      for hash, txo in _txo
        for index, output in txo
          if output.confirmed && output.spent
            _prune(output)

    _findHighestBlock: (txs) ->
      bestBlock = null
      for tx in txs
        if !bestBlock? or (tx.block?.height > bestBlock.height)
          bestBlock = tx.block
      bestBlock

    _requestSynchronizationToken: () ->
      d = ledger.defer()
      _restClient.getSyncToken (token, error) ->
        if (error?)
          d.reject(error)
        else
          d.resolve(token)
      d.promise

    _deleteSynchronizationToken: (token) ->
      d = ledger.defer()
      _restClient.deleteSyncToken token, ->
        d.resolve()
      d.promise

    _getAllTxs: (response) ->
      _filterUtxo(response.txs)
      if response?.truncated
        _blockHash = _findHighestBlock(response) || _blockHash
        ledger.api.TransactionsRestClient.getPaginatedTransactions(_address, _blockHash, _syncToken, _getAllTxs)
      else
        _finalize()

    d = ledger.defer()
    #_ready = _recoverLastState()
    #_ready.then ->
    _requestSynchronizationToken()
    .then(token) =>
      _syncToken = token
      _getAllTxs({txs:[], truncated: true})
    .fail (er) =>
      d.reject()
      $error "Synchronization failed", er
    .fin =>
      _deleteSynchronizationToken(_syncToken) if _syncToken?
      _syncToken = null
      ledger.storage.global.splitUtxo.set {"blockHash": _blockHash, "txo": _txo} =>
        d.resolve(_finalize)
    d.promise


  @checkUtxoOn2x: () ->
    _txo = {}
    _blockHash = "0x000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
    _syncToken = null
    _restClient = new ledger.api.TransactionsRestClient( -> 'segwit2x')
    _store = ledger.storage.local.substore('checkUtxoOn2x')
    _walletStore = ledger.storage.local.substore('split2xWallet')
    _blocks = {}
    _blocks[0] = {hash: _blockHash, height: 0}
    BatchSize: 50
    NumberOfRetry: 1
    d = ledger.defer()
    hdWallet = new ledger.wallet.Wallet()
    cache = new ledger.wallet.Wallet.Cache('ops_cache', hdWallet)
    cache.initialize ->
      hdWallet.cache = cache
      xcache = new ledger.wallet.Wallet.Cache('ops_cache', hdWallet)
      xcache.initialize ->
        hdWallet.xpubCache = xcache
        hdWallet.initialize _walletStore, () =>
          _findUnconfirmedTransaction: ->
            d = ledger.defer()
            _store.get 'txs', (result) =>
              unconfirmedTxs = []
              for tx in result['unconfirmedTxs']
                unconfirmedTxs.push(tx)
              d.resolve(unconfirmedTxs)
            d.promise

        _loadSynchronizationData: ->
          d = ledger.defer()
          _store.get 'blocks', (result) =>
            if result?
              _blocks = result
            _store.get 'txo', (result) =>
              if result?
                _txo = result
              l "Synchronization saved state split", data
              _store.get 'checkUtxoOn2x', (data) =>
                l "Synchronization saved state split", data
                unless data['checkUtxoOn2x']?
                  d.resolve({})
                else
                  d.resolve(data['checkUtxoOn2x'])
          d.promise.then (data) =>
            data

        _migrateSavedState: (state = {}) ->
          oldBatchSize = state["batch_size"] or 20
          if (oldBatchSize != BatchSize)
            idx = 0
            while state["account_#{idx}"]?
              oldBatches = state["account_#{idx}"]["batches"]
              batches = []
              total  = oldBatches.length * oldBatchSize
              state["account_#{idx}"] = batches: batches
              idx += 1
          state["batch_size"] = BatchSize
          state

        _requestSynchronizationToken: () ->
          d = ledger.defer()
          _restClient.getSyncToken (token, error) ->
            if (error?)
              d.reject(error)
            else
              d.resolve(token)
          d.promise

        _numberOfAccountInState: (savedState) ->
          accountIndex = 0
          while savedState["account_#{accountIndex}"]?
            accountIndex += 1
          accountIndex

        _recoverAddresses: (root, from, to, blockHash, syncToken) ->
          paths = _.map [from...to], (i) -> "#{root}/#{0}/#{i}"
          paths = paths.concat(_.map [from...to], (i) -> "#{root}/#{1}/#{i}")
          d = ledger.defer()
          l "Recovering ", paths
          callback = (response, error) =>
            return d.reject(error) if error?
            d.resolve(response)
          ledger.wallet.pathsToAddresses paths, (addresses) =>
            _restClient.getPaginatedTransactions(_.values(addresses), blockHash, syncToken, callback)
          d.promise

        _requestDerivations: ->
            d = ledger.defer()
            ledger.wallet.pathsToAddresses hdWallet.getAllObservedAddressesPaths(), (addresses) ->
              d.resolve(_.invert(addresses))
            d.promise

        _recoverBatch: (batch, accountIndex, syncToken) ->
          wallet = hdWallet
          account = wallet.getOrCreateAccount(accountIndex)
          blockHash = batch['blockHash']
          from = batch.index * BatchSize
          to = from + BatchSize
          hasNext = no
          _recoverAddresses(account.getRootDerivationPath(), from, to, blockHash, syncToken).then (result) =>
            d = ledger.defer()
            hasNext = result["truncated"]
            block = _findHighestBlock(result.txs)
            transactions = _(result['txs']).map((tx) -> tx.hash)
            _requestDerivations().then (cache) =>
              for tx in result['txs']
                for ouput in outputs
                  path = cache[output.address]
                  if path?
                    hdWallet.getOrCreateAccountFromDerivationPath(path)
                    hdWallet.getAccountFromDerivationPath(path).notifyPathsAsUsed([path])
                    if !_txo[tx.hash]?
                      _txo[tx.hash] = {}
                    _txo[tx.hash][ouput.output_index] = output
                    if tx.block
                      _txo[tx.hash][ouput.output_index].confirmed = yes
                      if !_blocks[tx.block.height]?
                        _blocks[tx.block.height] = {block: tx.block, txo: [], txi: {}}
                      _blocks[tx.block.height].txo.push(tx.hash)
                      for index, hash in _blocks['unconfirmedTxs'].txo when hash == tx.hash
                        delete _blocks['unconfirmedTxs'].txo[index]
                    else
                      if !_blocks['unconfirmedTxs']?
                        _blocks['unconfirmedTxs'] = {txo: []}
                      _blocks['unconfirmedTxs'].txo.push(tx.hash)
                for input in inputs
                  path = cache[input.address]
                  if path?
                    hdWallet.getOrCreateAccountFromDerivationPath(path)
                    hdWallet.getAccountFromDerivationPath(path).notifyPathsAsUsed([path])
                    if !_blocks[tx.block.height]?
                      _blocks[tx.block.height] = {block: tx.block, txo: [], txi: {}}
                    if !_blocks[tx.block.height].txi[input.ouput_hash]?
                      _blocks[tx.block.height].txi[input.ouput_hash] = []
                    _blocks[tx.block.height].txi[input.ouput_hash].push(input.output_index)
                    _txo[input.ouput_hash][input.output_index].spent = {block: tx.block, tx: tx.hash}

            d.resolve({hasNext, block, transactions})
            d.promise
          .fail (er) ->
            er.block = batch
            throw er

        _recoverAccount: (account, savedState, syncToken) ->
          $info "Recover account #{account.index}"
          savedAccountState = savedState["account_#{account.index}"] or {}
          savedState["account_#{account.index}"] = savedAccountState
          batches = savedAccountState["batches"] or []
          savedAccountState["batches"] = batches
          fetchTxs = []

          recover = (fromIndex, toIndex) =>
            promises = []
            for index in [fromIndex..toIndex]
              do (index) =>
                batch = batches[index]
                unless batch?
                  batch =
                    index: index
                    blockHash: null
                  batches.push batch
                $info "Recover batch #{batch.index} for account #{account.index}"
                recoverUntilEnd = () =>
                  _recoverBatch(batch, account.index, syncToken).then ({hasNext, block, transactions}) =>
                    fetchTxs = fetchTxs.concat(transactions)
                    if block? and (!batch['blockHeight']? or block.height > batch['blockHeight'])
                      batch['blockHash'] = block.hash
                      batch['blockHeight'] = block.height
                    d = ledger.defer()
                    l "Batch #{batch.index} for account #{account.index} has next", hasNext
                    if hasNext
                      ledger.tasks.TransactionConsumerTask.instance.pushCallback =>
                        d.resolve(recoverUntilEnd())
                    else
                      d.resolve()
                    d.promise
                promises.push recoverUntilEnd()
            Q.all(promises)

        _recoverAccounts: (unconfirmedTransactions, savedState, syncToken) ->
          accountsCount = _numberOfAccountInState(savedState)

          recover = (fromIndex, toIndex = 0) =>
            promises = []
            accountIndex = fromIndex
            while savedState["account_#{accountIndex}"]? or accountIndex <= toIndex
              account = hdWallet.getOrCreateAccount(accountIndex)
              do (account) =>
                d = ledger.defer()
                _restClient.getConsumer().registerExtendedPublicKeyForPath account.getRootDerivationPath(), =>
                  d.resolve(_recoverAccount(account, savedState, syncToken))
                promises.push d.promise
              accountIndex += 1
            Q.all(promises)
          recoverUntilEmpty = (fromIndex = 0, toIndex = 0) =>
            recover(fromIndex, toIndex).then (results) =>
              containsEmpty = no
              for [isEmpty, txs] in results
                containsEmpty ||= isEmpty
                unconfirmedTransactions = _(unconfirmedTransactions).filter (tx) ->
                  !_(txs).some((hash) -> tx.hash is hash)
              unless containsEmpty
                accountsCount = _numberOfAccountInState(savedState)
                recoverUntilEmpty(accountsCount, accountsCount)
              else
                unconfirmedTransactions
            .fail (er) =>
              throw er

          recoverUntilEmpty()

        _handleReorgs: (savedState, failedBlock) ->
          # Iterate through the state and delete any block higher or equal to failedBlock.height
          # Remove from the database all orphan transaction and blocks
          # Save the new state
          $info("Handle reorg for block #{failedBlock.blockHash} at #{failedBlock.blockHeight}")

          getPreviousBlock = (height) ->
            _blocks[height-1] ? _blocks[height-1] : getPreviousBlock(height-1)

          previousBlock = getPreviousBlock(failedBlock.blockHeight)
          $info("Revert to block #{previousBlock.block.hash} at #{previousBlock.block.height}")
          idx = 0
          while savedState["account_#{idx}"]?
            for batch in savedState["account_#{idx}"]["batches"]
              if batch.blockHeight > previousBlock.height
                batch.blockHeight = previousBlock.height
                batch.blockHash = previousBlock.hash
            idx += 1
          for height, block in _blocks
            if height >= failedBlock.blockHeight or height == 'unconfirmedTxs'
              for tx in _blocks[height].txo
                delete _txo[tx]
              for hash, tx in _blocks[height].txi
                for txo in tx
                  _txo[hash][txo].spent = undefined
              delete _blocks[height]

          _saveSynchronizationData(savedState)

        _saveSynchronizationData: (data) ->
          d = ledger.defer()
          l "Saving state", data
          save = {}
          save['checkUtxoOn2x'] = data
          _store.set save =>
            save = {}
            save['blocks'] = _blocks
            _store.set save =>
              save = {}
              save['txo'] = _txo
              _store.set save =>
                d.resolve()
          d.promise

        _performRecovery: (unconfirmedTransactions, retryCount = 0) ->
          savedState = {}
          persistState = no
          lastBlock = undefined
          _loadSynchronizationData().then (data) =>
            savedState = _migrateSavedState(data)
            persistState = yes
            blockClient = new ledger.api.BlockRestClient(-> 'segwit2x')
            .getLastBlock()
          .then (block) =>
            lastBlock = block
            _requestSynchronizationToken()
          .then (token) =>
            _syncToken = token
            _recoverAccounts(unconfirmedTransactions, savedState, token)
          .fail (er) =>
            # Handle reorgs
            e "Failure during synchro split", er
            if er?.getStatusCode?() is 404
              _handleReorgs(savedState, er.block).then () =>
                _performRecovery(unconfirmedTransactions)
            else if retryCount < NumberOfRetry
              d = ledger.defer()
              _.delay((=> d.resolve(_performRecovery(unconfirmedTransactions, retryCount + 1))), 1000)
              d.promise
            else
              # Mark failure and save
              savedState['lastSyncStatus'] = 'failure'
              d = ledger.defer()
              if persistState
                _saveSynchronizationData(savedState).then -> d.reject(er)
              else
                d.reject(er)
              d.promise
          .then (unconfirmed) =>
            unconfirmedTransactions = unconfirmed
            savedState['lastSyncStatus'] = 'success'
            savedState['lastSyncTime'] = new Date().getTime()
            _saveSynchronizationData(savedState) if persistState
          .then =>
            unconfirmedTransactions

        _discardTransactions: (transactions) ->
          for transaction in transactions when !transaction.block?
            delete transactions[transaction.hash]


        startDate = new Date()
        _findUnconfirmedTransaction()
        .then (unconfirmedTxs) =>
          $info "Start synchronization split", startDate.toString()
          $info "Looking for mempool tx", _(unconfirmedTxs).map((tx) -> tx.hash)
          _performRecovery(unconfirmedTxs)
          .then (transactionsNotFound) =>
            $info "Recovery completed split 2x"
            $info "Unable to find these transactions", _(transactionsNotFound).map((tx) -> tx.hash)
            _discardTransactions(transactionsNotFound)
          .fail (er) =>
            $error "Synchronization failed split", er
          .fin =>
            # Delete sync token and stop
            @_deleteSynchronizationToken(_syncToken) if _syncToken?
            @_syncToken = null
            duration = moment.duration(new Date().getTime() - startDate.getTime())
            $info "Stop synchronization. Synchronization took #{duration.get("minutes")}:#{duration.get("seconds")}:#{duration.get("milliseconds")}"
            utxoOn2x = []
            for tx in _txo when !tx.spent
              utxoOn2x.push(tx)
            $info "Found these utxo on 2x #{utxoOn2x}"
            d.resolve(utxoOn2x)
    d.promise.then () =>
