var devices = {
  osc: {
    sin: null
  },
  env: null,
  meter: null,
  fft: null
}

var state = {
  clientId: config.default_id,
  wavePos: 0
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
    frameRate(config.frameRate);

    handleOSC();
    setupAudio();
    setupVisuals();

    fullscreen(true);

    colorMode(HSB, 100, 100, 100, 1);
    createCanvas(windowWidth, windowHeight);
}

function deviceMoved() {
  var rot = rotationX;
  if (rotationX > 90) {
    rot = 90;
  } else if (rotationX < -90) {
    rot = -90;
  }
  state.wavePos = rot/90.0;
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
    for (var i = 0; i < waveform.length; i++){
        var x = map(i, 0, waveform.length, 0, width);
        var y = map(waveform[i], -1 * config.visual.stroke.scale, config.visual.stroke.scale, height, 0);
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

    port.on("message", function (oscMessage) {
        console.log("message", oscMessage);
        if (oscMessage.address === "/player/init") {
          clientId = oscMessage.args[0];
        }
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

function setupAudio() {
    devices.osc.sin = new p5.SinOsc();
    devices.meter = new p5.Amplitude(0.10);

    devices.env = new p5.Env();
    devices.env.setADSR(
        config.audio.env.attackTime,
        config.audio.env.decayTime,
        config.audio.env.susPercent,
        config.audio.env.releaseTime);

    devices.env.setRange(1, 0);

    devices.osc.sin.amp(devices.env);
    devices.osc.sin.start();
}

function tuneSynths(note) {
    config.visual.bg.H = note % 100;
    devices.osc.sin.freq(midiToFreq(note));
}

function noteOn(note) {
    console.log("Playing " + note);
    tuneSynths(note + config.audio.noteOffset);
    devices.env.triggerAttack();
}

function noteOff() {
    devices.env.triggerRelease();
}
