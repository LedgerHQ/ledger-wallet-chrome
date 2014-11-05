function LWWallet (lW) {
    LWTools.console("LWWallet.construct", 3);
    this.lW = lW;
    this.address = null;
    this.addressChange = null;
    this.balance = 0;
    this.unconfirmedBalance = 0;
    this.transactions = null;
    this.transactionsLoading = false;                   /* Permet de savoir si une requète est en cours pour récupérer la liste des transactions */
    this.transactionPreparing = null;
    this.blockchain = 'http://wallet.chronocoin.fr';    /* Bitcoin API */
    this.settings = {
        coin: 'Bitcoin',
        ticker: 'BTC',
        refreshDelay: 10000,
    }
    this.refreshTimeout = null;

}

LWWallet.prototype = {

    constructor: LWWallet,

    event: function (eventName, data) {
        var lWWallet = this;

        lWWallet.lW.deviceManager.emit(eventName, data);

        //window.dispatchEvent(new CustomEvent(eventName, data));
    },

    setAddress : function (address) {
        LWTools.console("LWWallet.setAddress", 3);
        var lWWallet = this;
        lWWallet.address = address;
    },

    setAddressChange : function (address) {
        LWTools.console("LWWallet.setAddressChange", 3);
        var lWWallet = this;
        lWWallet.addressChange = address;
    },

    refresh : function (now){
        LWTools.console("LWWallet.refresh", 3);
        var lWWallet = this;

        now = (typeof now === "undefined") ? false : now;

        if(now){
            clearTimeout(lWWallet.refreshTimeout);
            lWWallet.loadWallet();
        }else{
            lWWallet.refreshTimeout = setTimeout(function(){
                lWWallet.loadWallet();
            },lWWallet.settings.refreshDelay);
        }
    },

    loadWallet : function () {
        LWTools.console("LWWallet.loadWallet", 3);
        var lWWallet = this;

        if(lWWallet.transactionsLoading == false){

            var firstRecovery = false;
            if(lWWallet.transactions == null){
                firstRecovery = true;
            }

            lWWallet.transactionsLoading = true;

            var url = lWWallet.blockchain+'/chain/addresses/'+lWWallet.address+','+lWWallet.addressChange;
            var urlTransactions = lWWallet.blockchain+'/chain/addresses/' + lWWallet.address + ','+lWWallet.addressChange+'/transactions';

            LWTools.ajax("GET", url).then(function(a) {

                lWWallet.balance = (parseInt(a[0].balance) + parseInt(a[1].balance)) / 100000000;
                var balance = parseInt(a[0].balance) + parseInt(a[1].balance);
                var unconfirmedBalance = parseInt(a[0].unconfirmed_balance) + parseInt(a[1].unconfirmed_balance);
                lWWallet.unconfirmedBalance = unconfirmedBalance / 100000000;
                lWWallet.balance = (balance + unconfirmedBalance) / 100000000;

                /* Event : LWWallet.BalanceRecovered */
                lWWallet.event('LWWallet.BalanceRecovered', {lWWallet: lWWallet});

                LWTools.ajax("GET", urlTransactions, {limit: 50 }).then(function(t) {
                    lWWallet.addTransactions(t);
                    lWWallet.sortTransactions('chain_received_at');
                    lWWallet.transactionsLoading = false;

                    /* Event : LWWallet.TransactionsRecovered */
                    lWWallet.event('LWWallet.TransactionsRecovered', {lWWallet: lWWallet});

                    if(firstRecovery == true){

                        lWWallet.transactionsLoading = true;
                        LWTools.ajax("GET", urlTransactions, {limit: 500 }).then(function(t2) {

                            lWWallet.addTransactions(t2);
                            lWWallet.sortTransactions('chain_received_at');
                            lWWallet.transactionsLoading = false;
                            lWWallet.refresh();

                        });
                    }else{
                        lWWallet.refresh();
                    }
                }, function (error) {
                    lWWallet.transactionsLoading = false;
                    lWWallet.refresh();
                });
            }, function (error) {
                lWWallet.transactionsLoading = false;
                lWWallet.refresh();
            });
        }else{
            lWWallet.transactionsLoading = false;
            lWWallet.refresh();
        }
    },

    addTransactions: function(transactions){
        LWTools.console("LWWallet.addTransactions", 3);
        var lWWallet = this;

        if(lWWallet.transactions != null){
            transactions.forEach(function(t, i){

                index = lWWallet.transactions.map(function (element) {return element.hash;}).indexOf(t.hash);

                if(index < 0){
                    lWWallet.transactions.push(t);
                }else{
                    /* Mise à jour des confirmations */
                    lWWallet.transactions[index].confirmations = t.confirmations;
                }
            });
        }else{
            lWWallet.transactions = transactions;
        }
    },

    sortTransactions: function(column){
        LWTools.console("LWWallet.sortTransactions", 3);
        var lWWallet = this;

        column = (typeof column === "undefined") ? "time" : column;

        lWWallet.transactions.sort((function(index){
            return function(a, b){
                return (a[index] === b[index] ? 0 : (a[index] < b[index] ? -1 : 1));
            };
        })('hash'));

        lWWallet.transactions.sort((function(index){
            return function(a, b){
                return (a[index] === b[index] ? 0 : (a[index] < b[index] ? -1 : 1));
            };
        })(column));

        lWWallet.transactions.reverse();
    },
}