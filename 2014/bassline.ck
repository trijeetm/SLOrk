// Psychedelic Arpeggiator
// -----------------------
// Takes root chord (polyphony 3) from a MIDI controller
// Joystick to modulate sound
// x-axis for density, y-axis for duration
// z-rot for cutoff

Gain g => Gain master => ADSR adsr => dac;

1 => g.gain;

0.8 => master.gain;

adsr.set(500::ms, 10::ms, 0.5, 1000::ms);

// Patches
// -------

HevyMetl fmv => g;

1 => fmv.gain;

// Setting up MIDI keyboard
// ------------------------

// number of the device to open (see: chuck --probe)
1 => int device;
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

// Instrument
// ----------

// Inits
0 => int first;
0 => int third;
0 => int fifth;

15 => int baseNoteLength;
baseNoteLength => float noteLength;

0.5 => float baseVolume;

0.5 => float volume;

0 => int minor;

0 => int hold;

0 => int baseDensity;
0 => int density;

min => now;

0 => int noteOn;

// infinite time-loop
while (true) {
    // wait on the event 'min'
    // min => now;
    
    // <<< msg.data1, msg.data2, msg.data3 >>>;

    if ((min.recv(msg)) && (msg.data1 == 144)) {
        msg.data2 => first;
        <<< first >>>;
        first + 4 - minor => third;
        first + 7 => fifth;
        //baseVolume => float gain;
        (((msg.data3 / 127.00) - 0.5)) * 0.5 + baseVolume => float gain;
        <<< msg.data3, gain >>>;
        gain => g.gain;
    }


    //[first] @=> int notes[];
    //[first, first + 12, fifth, first, first - 12, fifth + 12, first - 24, first - 12, first + 12, fifth + 12, first + 24] @=> int notes[];
    
    //Std.mtof(notes[Math.random2(0, baseDensity + density)]) => fmv.freq;
    Std.mtof(first) => fmv.freq;
    
    

    if ((msg.data2 == first) && (msg.data1 == 144) && (noteOn == 0)) {
        //<<< "Attacking" >>>;
        1 => fmv.noteOn;
        adsr.keyOn();
        1 => noteOn;
    }
    
    noteLength::ms => now;   

    if ((msg.data2 == first) && (msg.data1 == 128) && (hold == 0)) {
        //<<< "Releasing" >>>;
        adsr.keyOff();
        0 => noteOn;
    }

}