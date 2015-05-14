/*
TODO:
controls:
    probability
    volume
    reverb
instrument:
    dont know how we're synthesizing
*/

// root directory
me.sourceDir() + "/" => string dirRoot;
if( me.args() ) me.arg(0) => dirRoot;

[
    "taiko.wav",
    "taiko2.wav",
    "mid1.wav",
    "high-bell1.wav",
    "high-bell2.wav"
] @=> string sampleFiles[];

5 => int nSamples;

// the device number to open
0 => int deviceNum;

// instantiate a HidIn object
HidIn hi;
// structure to hold HID messages
HidMsg msg;

// open keyboard
if( !hi.openKeyboard( deviceNum ) ) me.exit();
// successful! print name of device
<<< "keyboard '", hi.name(), "' ready" >>>;

spork ~ handleKeyboard();

// beat 
0 => int nBeats;
0 => int count;

// percussion control
Gain masterGain;
0 => int instrument;
float percProbabilities[nSamples];
Gain percGains[nSamples];
NRev percRev[nSamples];

// percussion samples
SndBuf percSamples[nSamples];

for (0 => int i; i < nSamples; i++) {
    0 => percProbabilities[i];
    0 => percGains[i].gain;
    0 => percRev[i].mix;

    dirRoot + sampleFiles[i] => string sampleSrc;
    sampleSrc => percSamples[i].read;
    0 => percSamples[i].rate;

    percSamples[i] => percRev[i] => percGains[i] => masterGain => dac;    
}

fun void playPerc(int id) {
    if (id < 0)
        return;

    1 => percSamples[id].rate;   
    0 => percSamples[id].pos;
}

// osc port
6449 => int OSC_PORT;

// OSC
OscIn in;
OscMsg omsg;

// the port
OSC_PORT => in.port;
// the address to listen for
in.addAddress( "/slork/play" );

// network
spork ~ network();

// infinite time loop
while( true ) 1::second => now;


// ---------------------
// Functions
// ---------------------

fun void network()
{
    while(true)
    {
        // wait for incoming event
        in => now;
        
        // drain the message queue
        while( in.recv(omsg) )
        {
            if( omsg.address == "/slork/play" )
            {
                omsg.getFloat(0) => float pitch;
                omsg.getFloat(1) => float master;
                omsg.getInt(2) => nBeats;
                omsg.getInt(3) => count;

                master => masterGain.gain;
                
                play(pitch);
            }
        }
    }
}

fun void play(float pitch) {
    <<< "--------------------------    " >>>;
    <<< "Prob:   Gain:    Reverb:      " >>>;

    for (0 => int i; i < nSamples; i++) {
        percProbabilities[i] => float prob;
        percGains[i].gain() => float _gain;

        <<< prob, percGains[i].gain(), percRev[i].mix() >>>;

        if (count == 0) {
            percProbabilities[i] * 4 => prob;            
            _gain * Math.random2f(1.9, 2.1) => percGains[i].gain;
        }
        else if (count == (nBeats / 2)) {
            percProbabilities[i] * 2 => prob;
            _gain * Math.random2f(1.5, 1.7) => percGains[i].gain;
        }
        else if (count == (nBeats / 4)) {
            _gain * Math.random2f(1.25, 1.4) => percGains[i].gain;
        }
        else {
            _gain * Math.random2f(0.75, 1.2) => percGains[i].gain;
        }

        if (Math.random2f(0, 1) < prob) {
            playPerc(i);
        }

        _gain => percGains[i].gain;
    }
}

fun void handleKeyboard() {
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
                // print
                // <<< "down:", msg.which >>>;

                msg.which => int key;

                // instrument selector (0, 1)
                if (key == 30) {
                    0 => instrument;
                }
                if (key == 31) {
                    1 => instrument;
                }
                if (key == 32) {
                    2 => instrument;
                }
                if (key == 33) {
                    3 => instrument;
                }
                if (key == 34) {
                    4 => instrument;
                }
                /*
                */

                // rev
                if (key == 29) {
                    if (percRev[instrument].mix() > 0) {
                        percRev[instrument].mix() - 0.0025 => percRev[instrument].mix;
                    }
                }
                if (key == 27) {
                    if (percRev[instrument].mix() < 1) {
                        0.0025 + percRev[instrument].mix() => percRev[instrument].mix;
                    }
                }

                // prob
                if (key == 48) {
                    if (percProbabilities[instrument] < 1) {
                        0.025 + percProbabilities[instrument] => percProbabilities[instrument];
                    }
                }
                if (key == 47) {
                    if (percProbabilities[instrument] > 0) {
                        percProbabilities[instrument] - 0.025 => percProbabilities[instrument];
                    }
                }

                // gain
                if (key == 46) {
                    if (percGains[instrument].gain() < 2) {
                        0.025 + percGains[instrument].gain() => percGains[instrument].gain;
                    }
                }
                if (key == 45) {
                    if (percGains[instrument].gain() > 0) {
                        percGains[instrument].gain() - 0.025 => percGains[instrument].gain;
                    }
                }
                
                /*
                if( key == 30 ) 0.0 => clientGain;
                if( key == 31 ) 0.1 => clientGain;
                if( key == 32 ) 0.3 => clientGain;
                if( key == 33 ) 0.6 => clientGain;
                if( key == 34 ) 1.0 => clientGain;
                */
                
            }
            else
            {
                // print
                // <<< "up:", msg.which >>>;
            }
        }
    }
}

