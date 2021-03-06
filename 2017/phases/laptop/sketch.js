var clientId;
var devices = {
  osc: {
    sin: null,
    saw: null,
  },
  env: {
      sin: null,
      saw: null
  },
  meter: null,
  fft: null
}

var state = {
  rotation: 0
}

var oscPlug = {
    "/player/synth/noteOn": function (args) {
        noteOn(args[1]);
    },
    "/player/synth/noteOff": function (args) {
        noteOff();
    }
}

function getId() {
	if (config.promptId) {
	    clientId = prompt("ID", "0");
	} else {
	    clientId = "0";
	}
}

function setup() {
    frameRate(config.frameRate);
    getId();
    handleOSC();
    setupAudio();
    setupVisuals();

    //fullscreen(true);

    colorMode(HSB, 100, 100, 100, 1);
    createCanvas(windowWidth, windowHeight);
}

function deviceMoved() {
  if (config.visual.moveWave) {
    var rot = rotationX;
    if (rotationX > 40) {
      rot = 40;
    } else if (rotationX < -10) {
      rot = -10;
    }
    state.rotation = (rot + 10)/50.0;
    devices.env.sin.setRange(state.rotation, 0);
    devices.env.saw.setRange(1-state.rotation, 0);
  }
}

function drawBG() {
    var level = devices.meter.getLevel();
    var bgColor = color(
        config.visual.bg.H,
        config.visual.bg.S,
        config.visual.bg.B,
        pow(level, config.visual.bg.alphaFactor));

    noStroke();
    fill(bgColor);
    rect(0, 0, width, height);
}

function drawWave() {
    var waveform = devices.fft.waveform();  // analyze the waveform
    beginShape();
    strokeWeight(config.visual.stroke.width);
    stroke(0, 0, 0, config.visual.stroke.alpha);
    fill(0, 0, 0, 0);
    var waveTop = height;
    var waveBot = 0;
    if (config.visual.moveWave) {
      var bottom_offset = state.rotation * (height - config.visual.waveHeight)
      waveTop = bottom_offset + config.visual.waveHeight;
      waveBot = bottom_offset;
    }
    for (var i = 0; i < waveform.length; i++){
        var x = map(i, 0, waveform.length, 0, width);
        var y = map(waveform[i], -1, 1, waveTop, waveBot);
        vertex(x, y);
    }
    endShape();
}

function draw() {
    background(0);
    drawBG();
    drawWave();
}

function handleOSC() {
    var port = new osc.WebSocketPort({
        url: "ws://" + config.ws.ip + ":" + config.ws.port
    });
    port.on("connection", function () {
	console.log("connected");
    });

    port.on("message", function (oscMessage) {
        var id = oscMessage.args[0];
		if (id == clientId) {
			oscPlug[oscMessage.address](oscMessage.args);
		}
    });

    port.open();
}

function setupVisuals() {
    devices.fft = new p5.FFT();
}

function getEnv() {}
    var env = new p5.Env();
    env.setADSR(
        config.audio.env.attackTime,
        config.audio.env.decayTime,
        config.audio.env.susPercent,
        config.audio.env.releaseTime);

    env.setRange(1, 0);
    return env;
}

function setupAudio() {
    devices.meter = new p5.Amplitude(0.10);

    devices.osc.sin = new p5.SinOsc();
    devices.env.sin = getEnv();
    devices.osc.sin.amp(devices.env);
    devices.osc.sin.start();

    devices.osc.saw = new p5.SawOsc();
    devices.env.saw = getEnv();
    devices.osc.saw.amp(devices.env.saw);
    devices.osc.saw.start();
}

function tuneSynths(note) {
    config.visual.bg.H = note % 100;
    devices.osc.forEach(function(osc) {
        osc.freq(midiToFreq(note))
    });
}

function noteOn(note) {
    tuneSynths(note + config.audio.noteOffset);
    devices.env.forEach(function(env) {
        env.triggerAttack();
    });
}

function noteOff() {
    devices.env.forEach(function(env) {
        env.triggerRelease();
    });
}
