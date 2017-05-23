var sinOsc;
var fft;
var env;
var meter;

var config = {
    envParams: {
        attackTime: 0.005,
        decayTime: 0.0,
        susPercent: 1,
        releaseTime: 0.2
    },
    visualParams: {
        H: 0,
        S: 70,
        B: 100,
        alphaFactor: 0.5,
        waveSmoothing: 0.2,
        stroke: {
            width: 20,
            alpha: 0.2
        }
    }
}

var oscPlug = {
    "/player/synth/noteOn": function (args) {
        console.log(args[1]);
        noteOn(args[1]);
    },
    "/player/synth/noteOff": function (args) {
        noteOff();
    }
}

function setup() {
    frameRate(32);

    handleOSC();
    setupAudio();
    setupVisuals();

    colorMode(HSB, 100, 100, 100, 1);
    createCanvas(displayWidth, displayHeight);
}

function draw() {
    var level = meter.getLevel();
    background(0);

    var bgColor = color(config.visualParams.H, config.visualParams.S, config.visualParams.B, pow(level, config.visualParams.alphaFactor));

    noStroke();
    fill(bgColor);
    rect(0, 0, width, height);

    var waveform = fft.waveform();  // analyze the waveform
    beginShape();
    strokeWeight(config.visualParams.stroke.width);
    stroke(0, 0, 0, config.visualParams.stroke.alpha);
    fill(0, 0, 0, 0);
    for (var i = 0; i < waveform.length; i++){
        var x = map(i, 0, waveform.length, 0, width);
        var y = map(waveform[i], -10, 10, height, 0);
        vertex(x, y);
    }
    endShape();
}

function handleOSC() {
    var port = new osc.WebSocketPort({
        url: "ws://localhost:8081"
    });

    port.on("message", function (oscMessage) {
        console.log("message", oscMessage);
        var id = oscMessage.args[0];
        console.log("message id " + id);
        oscPlug[oscMessage.address](oscMessage.args);
    });

    port.open();
}

function setupVisuals() {
    fft = new p5.FFT(config.visualParams.waveSmoothing);
}

function setupAudio() {
    sinOsc = new p5.SinOsc();
    meter = new p5.Amplitude(0.10);

    env = new p5.Env();
    env.setADSR(config.envParams.attackTime, config.envParams.decayTime, config.envParams.susPercent, config.envParams.releaseTime);
    env.setRange(1, 0);

    sinOsc.amp(env);
    sinOsc.start();
}

function tuneSynths(note) {
    config.visualParams.H = note % 100;
    sinOsc.freq(midiToFreq(note));
}

function noteOn(note) {
    console.log("Playing " + note);
    tuneSynths(note);
    env.triggerAttack();
}

function noteOff() {
    env.triggerRelease();
}