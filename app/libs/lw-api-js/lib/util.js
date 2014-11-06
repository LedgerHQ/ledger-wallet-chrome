var BigInteger = Bitcoin.BigInteger;

function isEmpty(ob)
{
    for (var i in ob)
    {
        if (ob.hasOwnProperty(i))
        {
            return false;
        }
    }
    return true;
}

function endian(string)
{
    var out = []
    for (var i = string.length; i > 0; i -= 2)
    {
        out.push(string.substring(i - 2, i));
    }
    return out.join("");
}

function btcstr2bignum(btc)
{
    var i = btc.indexOf('.');
    var value = new BigInteger(btc.replace(/\./, ''));
    var diff = 9 - (btc.length - i);
    if (i == -1)
    {
        var mul = "100000000";
    }
    else if (diff < 0)
    {
        return value.divide(new BigInteger(Math.pow(10, -1 * diff).toString()));
    }
    else
    {
        var mul = Math.pow(10, diff).toString();
    }
    return value.multiply(new BigInteger(mul));
}

function parseScript(script)
{
    var newScript = new Bitcoin.Script();
    var s = script.split(" ");
    for (var i in s)
    {
        if (Bitcoin.Opcode.map.hasOwnProperty(s[i]))
        {
            newScript.writeOp(Bitcoin.Opcode.map[s[i]]);
        }
        else
        {
            newScript.writeBytes(Bitcoin.convert.hexToBytes(s[i]));
        }
    }
    return newScript;
}

function tx_fetch(url, onSuccess, onError, postdata)
{

    $.ajax(
    {
        url: url,
        data: postdata,

        type: "POST",
        success: function (res)
        {
            onSuccess(JSON.stringify(res));

        },
        error: function (xhr, opt, err)
        {
            console.log("error!");
        }
    });
}

function hasTouch()
{
    return (typeof Touch == 'object');
};
