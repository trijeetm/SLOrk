/*
TODO:
controls:
    probability
    volume
    reverb
instrument:
    dont know how we're synthesizing
*/

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
                
                // set pitch
                pitch => Std.mtof => k.freq;
                // pluck it
                velocity => k.noteOn;
            }
        }
    }
}

// network
spork ~ network();

// infinite time loop
while( true ) 1::second => now;





