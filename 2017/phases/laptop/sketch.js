function setup() {
    handleOSC();

    colorMode(RGB, 100);
    createCanvas(displayWidth, displayHeight);
}

function draw() {
    background(0);
}

function handleOSC() {
    var port = new osc.WebSocketPort({
        url: "ws://localhost:8081"
    });

    port.on("message", function (oscMessage) {
        console.log("message", oscMessage);

        
    });

    port.open();
}