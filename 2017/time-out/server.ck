// launch with OSC_recv.ck

// host name and port
"localhost" => string hostname;
6449 => int port;

// get command line
if( me.args() ) me.arg(0) => hostname;
if( me.args() > 1 ) me.arg(1) => Std.atoi => port;

// send object
OscSend xmit;

// aim the transmitter
xmit.setHost( hostname, port );

2000 => float measureLength;   // in ms

// infinite time loop
while( true )
{
    // start the message...
    // the type string ',f' expects a single float argument
    xmit.startMsg( "/conductor/beat", "f" );

    // a message is kicked as soon as it is complete
    // - type string is satisfied and bundles are closed
    measureLength => xmit.addFloat;

    <<< measureLength::ms >>>;

    // advance time
    measureLength::ms => now;
}