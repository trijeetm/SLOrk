// Notes: Also include "playDrums", "playBass", "playBowed" functions

200::ms => dur TEMPO;

// osc port
6449 => int OSC_PORT;

// host name to send to
string HOSTS[0];

// add localhost by default, if no other hosts specified
if( HOSTS.size() == 0 )
{
    HOSTS << "localhost";
    // HOSTS << "foiegras.local";
    // HOSTS << "lasagna.local";
    // HOSTS << "chowder.local";
    // HOSTS << "hamburger.local";
    // HOSTS << "icetea.local";
    // HOSTS << "empanada.local";
    // HOSTS << "albacore.local";
}

// number of targets
HOSTS.size() => int NUM_HOSTS;
// osc output
OscOut XMIT[NUM_HOSTS];

// log
<<< "[server]: configuring network, # of nodes:", HOSTS.size() >>>;
// loop over
for( int i; i < HOSTS.size(); i++ )
{
    // print
    <<< "[server]:   |-host:", HOSTS[i] >>>;
    // aim the transmitter at port
    XMIT[i].dest( HOSTS[i], OSC_PORT );
}

// play
fun void play( int host, float pitch, float master, int nBeats, int count )
{
    // sanity check
    if( host < 0 || host >= XMIT.size() )
        return;
    
    // start a message
    XMIT[host].start( "/slork/play" );
    // add parameters to be sent
    XMIT[host].add( pitch );
    XMIT[host].add( master );
    XMIT[host].add( nBeats );
    XMIT[host].add( count );
    // fire!
    XMIT[host].send();
}

// play all
fun void playAll( float pitch, float master, int nBeats, int count )
{
    for( int i; i < XMIT.size(); i++ )
    {
        play( i, pitch, master, nBeats, count );
    }
}

0 => int count;

while( true )
{
    8 => int nBeats;

    playAll( 48, 1, nBeats, count );

    (count + 1) % nBeats => count;

    <<< count >>>;
    
    // wait
    TEMPO => now;
}