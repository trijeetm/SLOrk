// Keyboard
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

// patch
VoicForm voc=> JCRev r => Echo a => Echo b => Echo c => Gain master => dac;

// settings
220.0 => voc.freq;
0.95 => voc.gain;
.8 => r.gain;
.2 => r.mix;
1000::ms => a.max => b.max => c.max;
750::ms => a.delay => b.delay => c.delay;
.50 => a.mix => b.mix => c.mix;

// master
0.0 => float currentGain;
currentGain => master.gain;

// shred to modulate the mix
fun void vecho_Shred( )
{
    0.0 => float decider;
    0.0 => float mix;
    0.0 => float old;
    0.0 => float inc;
    0 => int n;

    // time loop
    while( true )
    {
        Math.random2f(0.0,1.0) => decider;
        if( decider < .3 ) 0.0 => mix;
        else if( decider < .6 ) .08 => mix;
        else if( decider < .8 ) .5 => mix;
        else .15 => mix;

        // find the increment
        (mix-old)/1000.0 => inc;
        1000 => n;
        while( n-- )
        {
            old + inc => old;
            old => a.mix => b.mix => c.mix;
            1::ms => now;
        }
        mix => old;
        Math.random2(2,6)::second => now;
    }
}

// let echo shred go
spork ~ vecho_Shred();
0.5 => voc.loudness;
0.01 => voc.vibratoGain;

// scale
[ 0, 3, 5, 7, 10 ] @=> int scale[];

// our main time loop
while (true) {
    if (hi.recv(msg)) {
        // check for action type
        if (msg.isButtonDown()) {
            //<<< msg.which >>>;
            if (msg.which == 82) {
                0.1 +=> currentGain;
                if (currentGain > 5) { 
                    <<< "Max gain reached" >>>;
                    5 => currentGain;
                }
            }
            if (msg.which == 79) {
                0.5 +=> currentGain;
                if (currentGain > 5) { 
                    <<< "Max gain reached" >>>;
                    5 => currentGain;
                }
            }
            if (msg.which == 81) {
                0.1 -=> currentGain;
                if (currentGain < 0) { 
                    <<< "Least gain reached" >>>;
                    0 => currentGain;
                }
            }
            if (msg.which == 80) {
                0.5 -=> currentGain;
                if (currentGain < 0) { 
                    <<< "Least gain reached" >>>;
                    0 => currentGain;
                }
            }
            currentGain => master.gain;
            <<< "Current gain = ", currentGain >>>;
        }
    }
    2 * Math.random2( 0,2 ) => int bphon;
    bphon => voc.phonemeNum;
    Math.random2f( 0.6, 0.8 ) => voc.noteOn;

    // note: Math.randomf() returns value between 0 and 1
    if( Math.randomf() > 0.85 )
    { 1000::ms => now; }
    else if( Math.randomf() > .85 )
    { 500::ms => now; }
    else if( Math.randomf() > .1 )
    { 250::ms => now; }
    else
    {
        0 => int i;
        4 * Math.random2( 1, 4 ) => int pick;
        0 => int pick_dir;
        0.0 => float pluck;

	for( ; i < pick; i++ )
        {
	    bphon + 1 * pick_dir => voc.phonemeNum;
            Math.random2f(.4,.6) + i*.035 => pluck;
            pluck + 0.0 * pick_dir => voc.noteOn;
            !pick_dir => pick_dir;
            250::ms => now;
        }
    }

    // pentatonic
    scale[Math.random2(0,scale.cap()-1)] => int freq;
    Std.mtof( ( 48 + Math.random2(0,2) * 12 + freq ) ) => voc.freq;
}