// Mallet client

200::ms => dur Q; // duration of 16th note, remove later

0 => int setMotif;
0 => int triggerMotif; // if on, next quarter note changes motif
                       // controlled by gametrak pedal


///////////////////////
// QUADRANT => MOTIF // (for Gametrak)
///////////////////////

/*
Define quadrants:
Left:
north : motif 1
south : motif 3
east  : motif 0 (mute)
west  : motif 2
Right:
north : pitch shift up
south : pitch shift down
east  : playback rate up
west  : playback rate down
*/

// Helpful to determine quadrant
float axisDiff;

// Outputs: 
// 1. Intervals to add to serverPitch
// 2. Gains
float setGain;
0 => int setRate;
0 => int setPitch;

fun void quadrant_output(float axis[]) {
    
    // Difference between abs. values of up/down and left/right
    Math.fabs(axis[1]) - Math.fabs(axis[0]) => axisDiff;
    
    // Left: quadrant defines motif no.
    if (axisDiff > 0) {
        if (axis[1] > 0) 1 => setMotif; //north
        else             3 => setMotif; //south
    } else {
        if (axis[0] > 0) 0 => setMotif; //east
        else             2 => setMotif; //west
    }
    
    // Right
    if (axis[3] > 0.5) {
        1 => setRate;
    } else if (axis[3] < -0.5) {
        -1 => setRate;
    } else {
        0 => setRate;
    }
    
    if (axis[4] > 0.5) {
        1 => setPitch;
    } else if (axis[4] < -0.5) {
        -1 => setPitch;
    } else {
        0 => setPitch;
    }
    
    // Gain = axis[2]
    (axis[2] - 0.05) / 0.95 => setGain;
    
}

////////////////////
// SET UP NETWORK //
////////////////////

// osc port
6449 => int OSC_PORT;

// OSC
OscIn in;
OscMsg omsg;

// the port
OSC_PORT => in.port;
// the address to listen for
in.addAddress( "/slork/play" );

int serverPitch;
float serverGain;
0 => int count;

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
                if(omsg.getInt(3) != count) {
                    omsg.getInt(0) => serverPitch;
                    omsg.getFloat(1) => serverGain;
                    omsg.getInt(3) => count;
                    <<< setMotif >>>;
                }
            }
            
            // New events can only occur on quarter notes
            if (count % 4 == 0) {
                //<<< "Quarter note!" >>>;
                if (triggerMotif == 1) {
                    spork ~ playMotif(setMotif);
                    0 => triggerMotif;
                }
                
            }
            
        }
    }
}


//////////////////////
// INSTRUMENT UGENS //
//////////////////////

ModalBar bar1 => Gain g => NRev r => dac;
ModalBar bar2 => g;

1 => r.gain;
0.02 => r.mix;

0 => bar1.preset; //Marimba
0.5 => bar1.stickHardness;
0.5 => bar1.strikePosition;


////////////
// MOTIFS //
////////////

// Play function
fun void play (int pitch, dur T) {
    pitch => Std.mtof => bar1.freq;
    1 => bar1.strike;
    T => now;
}

// PlayMotif function
fun void playMotif (int motif) {
    //while (true) {
        if (motif == 1) {
            for(0 => int i; i < 16; i++) {
                play(serverPitch, Q);
            }
        } else if (motif == 2) {
            for(0 => int i; i < 16; i++) {
                play(serverPitch + i, Q);
            }
        } else if (motif == 3) {
            play(serverPitch - 5, 2*Q);
            play(serverPitch, Q);
            play(serverPitch + 2, Q);
            play(serverPitch + 4, 2*Q);
            play(serverPitch, 2*Q);
            play(serverPitch + 2, 0.5*Q);
            play(serverPitch - 10, 0.5*Q);
            play(serverPitch, 0.5*Q);
            play(serverPitch - 12, 0.5*Q);
            play(serverPitch - 1, 0.5*Q);
            play(serverPitch - 13, 0.5*Q);
            play(serverPitch - 5, 0.5*Q);
            play(serverPitch - 10, 0.5*Q);
            play(serverPitch, 2*Q);
        }
    //}
}


////////////////////////
// GAMETRACK FUNCTION //
////////////////////////

0 => float DEADZONE;

0 => int device;
if( me.args() ) me.arg(0) => Std.atoi => device;

Hid trak;
HidMsg msg;

if( !trak.openJoystick( device ) ) me.exit();

// print
<<< "joystick '" + trak.name() + "' ready", "" >>>;

// data structure for gametrak
class GameTrak
{
    // timestamps
    time lastTime;
    time currTime;
    
    // previous axis data
    float lastAxis[6];
    // current axis data
    float axis[6];
}

// gametrack
GameTrak gt;

fun void gametrak()
{
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( msg ) )
        {
            // joystick axis motion
            if( msg.isAxisMotion() )
            {            
                // check which
                if( msg.which >= 0 && msg.which < 6 )
                {
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 )
                    { 
                        msg.axisPosition => gt.axis[msg.which];
                        quadrant_output(gt.axis);
                    }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            } else if (msg.isButtonDown()) {
                1 => triggerMotif;
            }
        }
    }
}


/////////////////
// RUN THREADS //
/////////////////

spork ~ network();
spork ~ gametrak();

100::ms => dur REFRESH; // refresh rate

// infinite time loop
while( true ) {
    
    // Set gain
    serverGain * setGain => g.gain;
    REFRESH => now;
}



