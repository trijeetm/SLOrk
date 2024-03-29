// root directory
me.sourceDir() + "/" => string dirRoot;
if( me.args() ) me.arg(0) => dirRoot;

[
    "high-bell1.wav",
    "high-bell2.wav"
] @=> string sampleFiles[];

2 => int nSamples;

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

true => int pause;
true => int _pause;

// percussion control
Gain masterGain;
0 => int instrument;
0 => int beatPeriod;
5 => int nBeatPeriods;
float percProbabilities[1][nBeatPeriods];
Gain percGains[1];
0 => float inputGain;
NRev percRev[1];

// percussion samples
SndBuf percSamples[nSamples];

for (0 => int i; i < 1; i++) {
    for (0 => int j; j < nBeatPeriods; j++)
        0 => percProbabilities[i][j];
    0 => percGains[i].gain;
    0 => percRev[i].mix;

    dirRoot + sampleFiles[i] => string sampleSrc;
    sampleSrc => percSamples[i].read;
    0 => percSamples[i].rate;

    percSamples[i] => percRev[i] => percGains[i] => masterGain => dac;

    dirRoot + sampleFiles[i + 1] => sampleSrc;
    sampleSrc => percSamples[i + 1].read;
    0 => percSamples[i + 1].rate;

    percSamples[i + 1] => percRev[i] => percGains[i] => masterGain => dac;   
}

fun void playPerc(int id) {
    if (id < 0)
        return;

    // Math.random2(0, 1) => id;

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
    <<< "-----------------------------------    " >>>;
    <<< "Controls:                              " >>>;
    <<< "-----------------------------------    " >>>;
    <<< "1 2 3 4 5 : Select beat period         " >>>;
    <<< "[ ]       : Probability down / up      " >>>;
    <<< "- +       : Volume down / up           " >>>;
    <<< "z x       : Reverb down / up           " >>>;
    <<< "-----------------------------------    " >>>;
    <<< " Prob:    Gain:    Reverb:             " >>>;

    for (0 => int i; i < 1; i++) {
        <<< "------------------------               " >>>;
        for (0 => int j; j < nBeatPeriods; j++) {
            percProbabilities[i][j] => float prob;
            0 => float _gain;

            <<< j + 1, prob, inputGain, percRev[i].mix() >>>;

            if (count % nBeats == 0) {
                percProbabilities[i][j] * 4 => prob;            
                inputGain * Math.random2f(0.9, 1) => _gain;
            }
            else if (count % (nBeats / 2) == 0) {
                percProbabilities[i][j] * 2 => prob;
                inputGain * Math.random2f(0.8, 0.9) => _gain;
            }
            else if (count % (nBeats / 4) == 0) {
                percProbabilities[i][j] * 1 => prob;
                inputGain * Math.random2f(0.7, 0.8) => _gain;
            }
            else if (count % (nBeats / 8) == 0) {
                inputGain * Math.random2f(0.6, 0.7) => _gain;
            }
            else if (count % (nBeats / 16) == 0) {
                inputGain * Math.random2f(0.5, 0.6) => _gain;
            }
            else {
                inputGain * Math.random2f(0.4, 0.5) => _gain;
            }

            if (count == 0)
                pause => _pause;

            if ((j == nBeatPeriods - 1) || (count % (nBeats / Math.pow(2, j)) == 0)) {
                // <<< count >>>;
                if ((Math.random2f(0, 1) < prob) && !_pause) {
                    _gain => percGains[i].gain;
                    playPerc(i);
                }
            }
        }
    }
}

false => int SHIFT_TOGGLE;

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

                if (key == 225)
                    true => SHIFT_TOGGLE;

                // period selector
                if (key == 30) {
                    0 => beatPeriod;
                }
                if (key == 31) {
                    1 => beatPeriod;
                }
                if (key == 32) {
                    2 => beatPeriod;
                }
                if (key == 33) {
                    3 => beatPeriod;
                }
                if (key == 34) {
                    4 => beatPeriod;
                }

                // rev
                if (key == 29) {
                    if (SHIFT_TOGGLE == true) {
                        0 => percRev[instrument].mix;
                    }
                    else if (percRev[instrument].mix() > 0) {
                        percRev[instrument].mix() - 0.0025 => percRev[instrument].mix;
                    }
                }
                if (key == 27) {
                    if (SHIFT_TOGGLE == true) {
                        0.25 => percRev[instrument].mix;
                    }
                    else if (percRev[instrument].mix() < 0.25) {
                        0.0025 + percRev[instrument].mix() => percRev[instrument].mix;
                    }
                }

                // prob
                if (key == 48) {
                    if (SHIFT_TOGGLE == true) {
                        1 => percProbabilities[instrument][beatPeriod];
                    }
                    else if (percProbabilities[instrument][beatPeriod] < 1) {
                        0.025 + percProbabilities[instrument][beatPeriod] => percProbabilities[instrument][beatPeriod];
                    }
                }
                if (key == 47) {
                    if (SHIFT_TOGGLE == true) {
                        0 => percProbabilities[instrument][beatPeriod];
                    }
                    else if (percProbabilities[instrument][beatPeriod] > 0) {
                        percProbabilities[instrument][beatPeriod] - 0.025 => percProbabilities[instrument][beatPeriod];
                    }
                }

                // gain
                if (key == 46) {
                    if (SHIFT_TOGGLE == true) {
                        1 => inputGain;
                    }
                    else if (inputGain < 1) {
                        0.025 + inputGain => inputGain;
                    }
                }
                if (key == 45) {
                    if (SHIFT_TOGGLE == true) {
                        0 => inputGain;
                    }
                    else if (inputGain > 0) {
                        inputGain - 0.025 => inputGain;
                    }
                }

                if (key == 44) {
                    if (pause == false)
                        true => pause;
                    else 
                        false => pause;
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
                if (msg.which == 225)
                    false => SHIFT_TOGGLE;
            }
        }
    }
}

