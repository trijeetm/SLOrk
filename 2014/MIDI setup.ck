// Psychedelic Arpeggiator
// -----------------------
// Takes root chord (polyphony 3) from a MIDI controller
// Joystick to modulate sound
// x-axis for density, y-axis for duration
// z-rot for cutoff

Gain g => Gain master => ADSR adsr => LPF lpf => dac;

0.5 => g.gain;

1 => master.gain;

adsr.set(100::ms, 10::ms, 0.5, 200::ms);

lpf.set(11000, 101);

// Patches
// -------

FMVoices fmv => g;
Rhodey r => g;
BeeThree b3 => g;
Mandolin m => g;
BlowBotl bb => g;
Moog moog => g;
Wurley w => g;

0.8 => fmv.gain;
0.9 => r.gain;
0.8 => b3.gain;
0.4 => m.gain;
0.2 => bb.gain;
0.7 => moog.gain;
0.4 => w.gain;

// Setting up MIDI keyboard
// ------------------------

// number of the device to open (see: chuck --probe)
3 => int device;
// get command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// the midi event
MidiIn min;
// the message for retrieving data
MidiMsg msg;

// open the device
if (!min.open(device)) 
    me.exit();

// print out device that was opened
<<< "MIDI device:", min.num(), " -> ", min.name() >>>;

// Setting up joystick
// -------------------

// make HidIn and HidMsg
Hid hi;
HidMsg msgJoy;

// which joystick
0 => int joystick;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => joystick;

// open joystick 0, exit on fail
if( !hi.openJoystick( joystick ) ) me.exit();

<<< "joystick '" + hi.name() + "' ready", "" >>>;

// Instrument
// ----------

// Inits
0 => int first;
0 => int third;
0 => int fifth;

150 => int baseNoteLength;
baseNoteLength => float noteLength;

0.5 => float baseVolume;

0.5 => float volume;

0 => int minor;

0 => int hold;

5 => int baseDensity;
0 => int density;

11000 => int baseCutoff;
101 => int baseRes;

min => now;

// infinite time-loop
while (true) {
    // wait on the event 'min'
    // min => now;
    
    // <<< msg.data1, msg.data2, msg.data3 >>>;

    if ((min.recv(msg)) && (msg.data1 == 144)) {
        msg.data2 => first;
        first + 4 - minor => third;
        first + 7 => fifth;
        (((msg.data3 / 127.00) - 0.5)) * 0.5 + baseVolume => float gain;
        // <<< msg.data3, gain >>>;
        gain => g.gain;
    }

    while (hi.recv(msgJoy)) {
        // joystick axis motion
        if (msgJoy.isAxisMotion())
        {
            if (msgJoy.which == 3) {
                (-(msgJoy.axisPosition) + 1.0) / 2.0 => volume;
            }
            // <<< "volume", volume >>>;
            volume => master.gain;
            if (msgJoy.which == 0) {
                -msgJoy.axisPosition => float yVal;
                if (yVal < 0) {
                    (yVal * 100) + baseNoteLength => noteLength;
                }
                else {
                    (yVal * 500) + baseNoteLength => noteLength;
                }
                // <<< "noteLength", noteLength >>>;
            }
            if (msgJoy.which == 1) {
                (msgJoy.axisPosition * 11000.0) => float cutoff;
                if (cutoff < 0)
                    50 +=> cutoff;
                -(msgJoy.axisPosition * 100.0) => float res;
                lpf.set(baseCutoff + cutoff, baseRes + res);
                // <<< cutoff, res >>>;
            }
            if (msgJoy.which == 2) {
                (msgJoy.axisPosition * 5.0) $ int => density;
                // <<< density >>>;
            }
        }
        else if (msgJoy.isButtonDown() && (msgJoy.which == 0)) {
            <<< "Playing minor" >>>;
            1 => minor;
            first + 3 => third;
        }
        else if (msgJoy.isButtonUp() && (msgJoy.which == 0)) {
            <<< "Playing major" >>>;
            0 => minor;
            first + 4 => third;
        }
        else if (msgJoy.isButtonDown() && (msgJoy.which == 1)) {
            <<< "Holding note" >>>;
            1 => hold;
        }
        else if (msgJoy.isButtonUp() && (msgJoy.which == 1)) {
            <<< "Not holding" >>>;
            0 => hold;
        }
    }

    [first, first + 12, fifth, third, first - 12, fifth + 12, first - 24, first - 12, third + 12, fifth + 12, first + 24] @=> int notes[];
    
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => fmv.freq;
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => r.freq;
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => b3.freq;
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => m.freq;
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => bb.freq;
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => moog.freq;
    Std.mtof(notes[Math.random2(0, baseDensity + density)]) => w.freq;
    
    1 => r.noteOn;
    1 => b3.noteOn;
    1 => fmv.noteOn;
    1 => m.noteOn;
    1 => bb.noteOn;
    1 => moog.noteOn;
    1 => w.noteOn;

    if ((msg.data2 == first) && (msg.data1 == 144)) {
        // <<< "Attacking" >>>;
        adsr.keyOn();
    }
    
    noteLength::ms => now;   

    if ((msg.data2 == first) && (msg.data1 == 128) && (hold == 0)) {
        // <<< "Releasing" >>>;
        adsr.keyOff();
    }

}

