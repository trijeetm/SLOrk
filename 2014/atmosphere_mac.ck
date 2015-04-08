// actual FM using sinosc (sync is 0)
// (note: this is not quite the classic "FM synthesis"; also see fm2.ck)

Hid hi;
HidMsg msg;

// which keyboard
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open keyboard (get device number from command line)
if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;



// global noise source 
TriOsc n;
// sweep shred
fun void sweep( float st, float inc, time end)
{

    //set up the audio chain
    n => TwoPole z => dac.chan(0); 
    1  => z.norm;
    0.1 => z.gain;
    st => z.freq;

    //store the time we entered the thread
    now => time my_start;
    0.0 => float my_seconds;

    Math.random2f( 0.94, 0.99 ) => z.radius;

    // keep going until we've passed the end time sent in by the control thread.
    while( now < end)
    {
        ( now - my_start ) / 1.0::second => my_seconds; 
        Math.max( my_seconds * 4.0, 1.0 ) * 0.1  => z.gain; 
        z.freq() + inc * -0.03  => z.freq;
        10::ms => now;
    }

}


// modulator to carrier
SinOsc m => Gain g => Chorus ch => ADSR env;
SinOsc c => Gain g2 => Chorus ch2 => ADSR env2;

// modulator to carrier
SinOsc m2 => Gain g3 => dac.chan(1);
SinOsc c2 => g2 => env2;

// modulator to carrier
SinOsc m3 => g => env;
SinOsc c3 => g2 => env2;

env => Delay d => dac.chan(0);
env2=> Delay d2=> dac.chan(1);

0.0 => m2.gain;
0.0 => g3.gain;



0.3 => ch.mix;
1 => ch.modFreq;
0.3 => ch.modDepth;

0.9 => ch2.mix;
0.05 => ch2.modDepth;
0.25 => ch2.modFreq;

0.1 => m3.gain;
0.15 => g.gain;
0.2=> g2.gain;

0 => env.target;
0 => env2.target;

env.set(0.1, 0.5, 1.0, 1.0);
env2.set(2.0, 2.0, 1, 2);

fun int keyToMidi(int i){
    
    if (i==7) return 0;
    if (i==21) return 1;
    if (i==9) return 2;
    if (i==23) return 3;
    if (i==10) return 4;
    if (i==11) return 5;
    if (i==24) return 6;
    if (i==13) return 7;
    if (i==12) return 8;
    if (i==14) return 9;
    if (i==18) return 10;
    if (i==15) return 11;
    if (i==51) return -1;
    return -2;
}


fun void setChord(int chord){
    //C minor
    if (chord == 0){
        60 => Std.mtof => c.freq;
        // modulator frequency
        36 => Std.mtof => m.freq;
        
        // carrier frequency
        63 => Std.mtof => c2.freq;
        // modulator frequency
        //39 => Std.mtof => m2.freq;
        
        // carrier frequency
        67 => Std.mtof => c3.freq;
        // modulator frequency
        43 => Std.mtof => m3.freq;
        
    }
    //G major
    if (chord == 1){
        59 => Std.mtof => c.freq;
        // modulator frequency
        43 => Std.mtof => m.freq;
        
        // carrier frequency
        62 => Std.mtof => c2.freq;
        // modulator frequency
        //39 => Std.mtof => m2.freq;
        
        // carrier frequency
        67 => Std.mtof => c3.freq;
        // modulator frequency
        50 => Std.mtof => m3.freq;
        
    }
    //F minor
    if (chord == 2){
        60 => Std.mtof => c.freq;
        // modulator frequency
        41 => Std.mtof => m.freq;
        
        // carrier frequency
        65 => Std.mtof => c2.freq;
        // modulator frequency
        //39 => Std.mtof => m2.freq;
        
        // carrier frequency
        68 => Std.mtof => c3.freq;
        // modulator frequency
        48 => Std.mtof => m3.freq;
        
    }
    //Eb major
    if (chord == 3){
        58 => Std.mtof => c.freq;
        // modulator frequency
        39 => Std.mtof => m.freq;
        
        // carrier frequency
        63 => Std.mtof => c2.freq;
        // modulator frequency
        //39 => Std.mtof => m2.freq;
        
        // carrier frequency
        67 => Std.mtof => c3.freq;
        // modulator frequency
        46 => Std.mtof => m3.freq;
        
    }
    //Ab major
    if (chord == 4){
        60 => Std.mtof => c.freq;
        // modulator frequency
        32 => Std.mtof => m.freq;
        
        // carrier frequency
        63 => Std.mtof => c2.freq;
        // modulator frequency
        //39 => Std.mtof => m2.freq;
        
        // carrier frequency
        68 => Std.mtof => c3.freq;
        // modulator frequency
        39 => Std.mtof => m3.freq;
        
    }

    
    
}


// infinite event loop
while( true )
{
    // wait on event
    hi => now;
    
    // get one or more messages
    while( hi.recv( msg ) )
    {
        // check for action type
        if( msg.isButtonDown() )
        {
            
            if (msg.which>20 && msg.which<39){
                msg.which - 30 => int chord;
                
                setChord(chord);
                
                1.0 => env.target;
                0.3 => env2.target;
            }
            else{
                msg.which => keyToMidi => float note;
                if (note >= 0) 72+note => Std.mtof => n.freq;
                <<<note>>>;
                spork ~ sweep( 220.0 * Math.random2(1,8), 
        	       880.0 + Math.random2f(100.0, 880.0), 
		           now + Math.random2f(1.0, 3.0)::second );
            }
            
        }
        
        else
        {
            <<< "up:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
            if (msg.which >29 && msg.which <39){
                0.0 => env.target;
                0.0 => env2.target;  
            }
        }
    }
}


