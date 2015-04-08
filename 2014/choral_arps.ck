// Keyboard
Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

<<< "----------" >>>;
<<< "Choral_Arp" >>>;
<<< "----------" >>>;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

// Patch
// STK StifKarp

// patch
StifKarp m => NRev r => Gain master => dac;
.75 => r.gain;
.02 => r.mix;

// master
0.0 => float currentGain;
currentGain => master.gain;

// our notes
[ 48, 51, 53, 55, 58, 60 ] @=> int notes[];
//[ 0, 3, 5, 7, 10 ] @=> int scale[];

// note length
100 => int length;

// infinite time-loop
while( true )
{
	while (hi.recv(msg)) {
	    // check for action type
	    if (msg.isButtonDown()) {
	        <<< msg.which >>>;
	        if (msg.which == 52) {
	            0.1 +=> currentGain;
	            if (currentGain > 5) { 
	                <<< "Max gain reached" >>>;
	                5 => currentGain;
	            }
	        }
	        if (msg.which == 55) {
	            1.0 +=> currentGain;
	            if (currentGain > 5) { 
	                <<< "Max gain reached" >>>;
	                5 => currentGain;
	            }
	        }
	        if (msg.which == 51) {
	            0.1 -=> currentGain;
	            if (currentGain < 0) { 
	                <<< "Least gain reached" >>>;
	                0 => currentGain;
	            }
	        }
	        if (msg.which == 54) {
	            1.0 -=> currentGain;
	            if (currentGain < 0) { 
	                <<< "Least gain reached" >>>;
	                0 => currentGain;
	            }
	        }
	        if (msg.which == 29) {
	            25 -=> length;
	            if (length < 50) { 
	                <<< "Shortest notelength (fastest arp)" >>>;
	                50 => length;
	            }
	        }
	        if (msg.which == 27) {
	            25 +=> length;
	            if (length > 300) { 
	                <<< "Longest notelength (slowest arp)" >>>;
	                300 => length;
	            }
	        }
	        currentGain => master.gain;
	        <<< "Current gain = ", currentGain >>>;
	        <<< "Note length = ", length >>>;
	    }
	}

    //Math.random2f( 0, 0 ) => m.pickupPosition;
    1 => m.pickupPosition;
    Math.random2f( 0, 1 ) => m.sustain;
    1 => m.stretch;



    // factor
    //Math.random2f( 1, 4 ) => float factor;

    Math.random2(5, notes.cap()) => int limit;

    Math.random2(0, 2) * 12 => int pitch_factor;

    for( int i; i < limit; i++ )
    {
        play(notes[i] + pitch_factor, Math.random2f( .6, .9 ));
        length::ms => now;
    }
    for( limit - 2 => int i; i > 0; i-- )
    {
        play(notes[i] + pitch_factor, Math.random2f( .6, .9 ));
        length::ms => now;
    }
}

// basic play function (add more arguments as needed)
fun void play( float note, float velocity )
{
    // start the note
    Std.mtof( note ) => m.freq;
    velocity => m.pluck;
}