//--------------------------------------------------
//  Bi-Directional OSC messaging Websocket <-> UDP
//--------------------------------------------------


var osc = require("osc"),
    WebSocket = require("ws"),
    dns = require("dns"),
    config = require("./slork_bridge_config");

var getIPAddresses = function () {
    var os = require("os"),
    interfaces = os.networkInterfaces(),
    ipAddresses = [];

    for (var deviceName in interfaces){
        var addresses = interfaces[deviceName];

        for (var i = 0; i < addresses.length; i++) {
            var addressInfo = addresses[i];

            if (addressInfo.family === "IPv4" && !addressInfo.internal) {
                ipAddresses.push(addressInfo.address);
            }
        }
    }

    return ipAddresses;
};

var setupWithHost = function(addr) {
    var udp = new osc.UDPPort({
      localAddress: addr,
      localPort: config.udp.port,
      remoteAddress: addr,
      remotePort: config.udp.port
    });

    udp.on("ready", function () {
        var ipAddresses = getIPAddresses();
        console.log("Listening for OSC over UDP.");
        console.log(" Host: ", udp.options.localAddress, "Port: ", udp.options.localPort);
        // ipAddresses.forEach(function (address) {
        //     console.log(" Host:", address + ", Port:", udp.options.localPort);
        // });
        console.log("Broadcasting OSC over UDP to", udp.options.remoteAddress + ", Port:", udp.options.remotePort);
    });

    udp.open();

    udp.on("message", function (msg) {
        console.log(msg);
    })

    var wss = new WebSocket.Server({
        port: config.ws.port
    });

    wss.on("connection", function (socket) {
        console.log("A Web Socket connection has been established!");
        var socketPort = new osc.WebSocketPort({
            socket: socket
        });

        var relay = new osc.Relay(udp, socketPort, {
            raw: true
        });
    });
}

dns.lookup(config.udp.addr, (err, addr, fam) => {
  if (err) {
      console.log(err);
  } else {
      console.log(addr);
      setupWithHost(addr);
  }
});

