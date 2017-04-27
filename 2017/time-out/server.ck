// launch with OSC_recv.ck

// host name and port
string HOSTS[0];
6449 => int port;

HOSTS << "Trijeet.local";

HOSTS.size() => int nHosts;

// send object
OscSend xmit[nHosts];

// aim the transmitter
for (0 => int i; i < nHosts; i++) {
    xmit[i].setHost(HOSTS[i], port);
}

2000 => float measureLength;   // in ms

// infinite time loop
while( true )
{
    for (0 => int i; i < nHosts; i++) {
        // start the message...
        // the type string ',f' expects a single float argument
        xmit[i].startMsg( "/conductor/beat", "f" );

        // a message is kicked as soon as it is complete
        // - type string is satisfied and bundles are closed
        measureLength => xmit[i].addFloat;
    }

    <<< measureLength::ms >>>;

    // advance time
    measureLength::ms => now;
}