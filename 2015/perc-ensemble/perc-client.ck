/*
TODO:
controls:
    probability
    volume
    reverb
instrument:
    dont know how we're synthesizing
*/

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

// perc controls
0 => float prob;
0 => float clientGain;

spork ~ handleKeyboard();

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

                // prob
                if (key == 48) {
                    if (prob < 1) {
                        0.05 + prob => prob;
                    }
                }
                if (key == 47) {
                    if (prob > 0) {
                        prob - 0.05 => prob;
                    }
                }

                // gain
                if (key == 46) {
                    if (clientGain < 2) {
                        0.025 + clientGain => clientGain;
                    }
                }
                if (key == 45) {
                    if (clientGain > 0) {
                        clientGain - 0.025 => clientGain;
                    }
                }
                
                if( key == 30 ) 0.0 => clientgain;
                if( key == 31 ) 0.1 => clientgain;
                if( key == 32 ) 0.3 => clientgain;
                if( key == 33 ) 0.6 => clientgain;
                if( key == 34 ) 1.0 => clientgain;
                
            }
            else
            {
                // print
                // <<< "up:", msg.which >>>;
            }
        }
    }
}

// osc port
6449 => int OSC_PORT;

StifKarp k => NRev r => Gain g => dac;
.1 => r.mix;

// OSC
OscIn in;
OscMsg omsg;

// the port
OSC_PORT => in.port;
// the address to listen for
in.addAddress( "/slork/play" );

// handle
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
                omsg.getFloat(1) => float velocity;
                
                // log
                // <<< "RECV pitch:", pitch, "velocity:", velocity >>>;
                

                play(pitch, velocity);
            }
        }
    }
}

fun void play(float pitch, float velocity) {
    <<< velocity, prob >>>;
    
    // set pitch
    pitch => Std.mtof => k.freq;

    clientGain => g.gain;

    if (Math.random2f(0, 1) < prob) {
        // pluck it
        velocity => k.noteOn;
    }
}

// network
spork ~ network();

// infinite time loop
while( true ) 1::second => now;





