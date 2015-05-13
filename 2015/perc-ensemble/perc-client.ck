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
            <<< "down:", msg.which >>>;
        }
        else
        {
            // print
            <<< "up:", msg.which >>>;
        }
    }
}

// osc port
6449 => int OSC_PORT;

StifKarp k => NRev r => dac;
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
                <<< "RECV pitch:", pitch, "velocity:", velocity >>>;
                

                play(pitch, velocity);
            }
        }
    }
}

0.9 => float prob;

fun void play(float pitch, float velocity) {
    // set pitch
    pitch => Std.mtof => k.freq;

    if (Math.random2f(0, 1) < prob) {
        // pluck it
        velocity => k.noteOn;
    }
}

// network
spork ~ network();

// infinite time loop
while( true ) 1::second => now;





