var sinOsc;
var fft;
var env;
var meter;
var clientId;

var oscPlug = {
    "/player/synth/noteOn": function (args) {
        console.log(args[1]);
        noteOn(args[1]);
    },
    "/player/synth/noteOff": function (args) {
        noteOff();
    }
}

function getId() {
	clientId = prompt("ID", "0");
}

function setup() {
    frameRate(config.frameRate);

	getId();
    handleOSC();
    setupAudio();
    setupVisuals();

    colorMode(HSB, 100, 100, 100, 1);
    createCanvas(windowWidth, windowHeight);
}

function draw() {
    var level = meter.getLevel();
    background(0);

    var bgColor = color(
        config.visual.bg.H,
        config.visual.bg.S,
        config.visual.bg.B,
        pow(level, config.visual.bg.alphaFactor));

    noStroke();
    fill(bgColor);
    rect(0, 0, width, height);

    var waveform = fft.waveform();  // analyze the waveform
    beginShape();
    strokeWeight(config.visual.stroke.width);
    stroke(0, 0, 0, config.visual.stroke.alpha);
    fill(0, 0, 0, 0);
    for (var i = 0; i < waveform.length; i++){
        var x = map(i, 0, waveform.length, 0, width);
        var y = map(waveform[i], -1 * config.visual.stroke.scale, config.visual.stroke.scale, height, 0);
        vertex(x, y);
    }
    endShape();
}

function handleOSC() {
    var port = new osc.WebSocketPort({
        url: "ws://" + config.ws.ip + ":" + config.ws.port
    });
	
    port.on("message", function (oscMessage) {
        console.log("message", oscMessage);
        var id = oscMessage.args[0];
		if (id == clientId) {
			oscPlug[oscMessage.address](oscMessage.args);
		}
    });

    port.open();
}

function setupVisuals() {
    fft = new p5.FFT();
}

function setupAudio() {
    sinOsc = new p5.SinOsc();
    meter = new p5.Amplitude(0.10);

    env = new p5.Env();
    env.setADSR(
        config.audio.env.attackTime,
        config.audio.env.decayTime,
        config.audio.env.susPercent,
        config.audio.env.releaseTime);

    env.setRange(1, 0);

    sinOsc.amp(env);
    sinOsc.start();
}

function tuneSynths(note) {
    config.visual.bg.H = note % 100;
    sinOsc.freq(midiToFreq(note));
}

function noteOn(note) {
    console.log("Playing " + note);
    tuneSynths(note + config.audio.noteOffset);
    env.triggerAttack();
}

function noteOff() {
    env.triggerRelease();
}
