// the device number to open
0 => int deviceNum;

// instantiate a HidIn object
Hid hi;
// structure to hold HID messages
HidMsg msg;

// open keyboard
if( !hi.openKeyboard( deviceNum ) ) me.exit();
// successful! print name of device
<<< "keyboard '", hi.name(), "' ready" >>>;

spork ~ handleKeyboard();

// Notes: Also include "playDrums", "playBass", "playBowed" functions

90::ms => dur TEMPO;

// osc port
6449 => int OSC_PORT;

// host name to send to
string HOSTS[0];

// add localhost by default, if no other hosts specified
if( HOSTS.size() == 0 )
{
    HOSTS << "localhost";

    // battery (6)

    // mallets (3)

    // pads (3)

    /*
    HOSTS << "gelato.local";
    HOSTS << "foiegras.local";
    HOSTS << "kimchi.local";
    HOSTS << "lasagna.local";
    HOSTS << "hamburger.local";
    HOSTS << "icetea.local";
    HOSTS << "empanada.local";
    HOSTS << "nachos.local";
    HOSTS << "omelet.local";
    HOSTS << "xanax.local";
    HOSTS << "banhmi.local";
    HOSTS << "spam.local";
    HOSTS << "peanutbutter.local";
    HOSTS << "jambalaya.local";
    */

    // HOSTS << "chowder.local";
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
fun void play( int host, int scale, float master, int nBeats, int count )
{
    // sanity check
    if( host < 0 || host >= XMIT.size() )
        return;
    
    // start a message
    XMIT[host].start( "/slork/play" );
    // add parameters to be sent
    XMIT[host].add( scale );
    XMIT[host].add( master );
    XMIT[host].add( nBeats );
    XMIT[host].add( count );
    // fire!
    XMIT[host].send();
}

// play all
fun void playAll( int scale, float master, int nBeats, int count )
{
    for( int i; i < XMIT.size(); i++ )
    {
        play( i, scale, master, nBeats, count );
    }
}

0 => int count;
0 => int scale;

while( true )
{
    32 => int nBeats;

    playAll( scale, 1, nBeats, count );

    (count + 1) % nBeats => count;

    <<< TEMPO, count >>>;
    
    // wait
    TEMPO => now;
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

                // note selector
                if (key == 30) {
                    0 => scale;
                }
                if (key == 31) {
                    1 => scale;
                }
                if (key == 32) {
                    2 => scale;
                }
                if (key == 33) {
                    3 => scale;
                }
                /*
                if (key == 34) {
                    4 => scale;
                }
                */
                
                /*
                // tempo
                if (key == 38) {
                    if (TEMPO < 120::ms) {
                        5::ms + TEMPO => TEMPO;
                    }
                }
                if (key == 39) {
                    if (TEMPO > 60::ms) {
                        TEMPO - 5::ms => TEMPO;
                    }
                }
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