// Synth pad client

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

float pitch;
float velocity;

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
                if(omsg.getFloat(0) != pitch || omsg.getFloat(1) != velocity) {
                    omsg.getFloat(0) => pitch;
                    omsg.getFloat(1) => velocity;
                    receiveMsg (pitch, velocity);
                }
            }
        }
    }
}

//////////////////////
// INSTRUMENT UGENS //
//////////////////////

ModalBar bar1 => NRev r => dac;
ModalBar bar2 => r;

1 => r.gain;
0.02 => r.mix;

0 => bar1.preset; //Marimba
0.5 => bar1.stickHardness;
0.5 => bar1.strikePosition;

// These will be controlled by the server
0 => float clientGain;
20 => float clientPitch;

fun void receiveMsg (float pitch, float velocity) {
    
    // set pitch
    pitch => clientPitch;
    // set max gain
    velocity => clientGain;
}


////////////////////////////
// QUADRANT => PITCH/GAIN // (for Gametrak)
////////////////////////////

/*
Define quadrants:
Left:
north : motif 1
south : motif 3
east  : motif 2
west  : motif 4
Right:
north : pitch shift up
south : pitch shift down
east  : playback rate up
west  : playback rate down
*/

// Helpful to determine quadrant
float axisDiff[2];

// Outputs: 
// 1. Intervals to add to clientPitch
// 2. Gains
int setMotif;
float setGain;
int p.shift;
int r.shift;

fun void quadrant_output(float axis[]) {
    
    // Difference between abs. values of up/down and left/right
    Math.fabs(axis[1]) - Math.fabs(axis[0]) => axisDiff[0];
    Math.fabs(axis[4]) - Math.fabs(axis[3]) => axisDiff[1];
    
    // Quadrants define pitches
    // Left
    if (axisDiff[0] > 0) {
        if (axis[1] > 0) 1 => setMotif; //north
        else             3 => setMotif; //south
    } else {
        if (axis[0] > 0) 2 => setMotif; //east
        else             4 => setMotif; //west
    }
    // Right
    if (axisDiff[1] > 0) {
        if (axis[4] > 0) 11 => setMotif; //north
        else              4 => setMotif; //south
    } else {
        if (axis[3] > 0) 12 => setMotif; //east
        else              7 => setMotif; //west
    }
    
    // Gain = absolute differences * axis[2 or 5]
    // Boundaries padded by mute zone
    for (0 => int i; i < 2; i++) {
        3 * i + 2 => int pullAxis;
        if (Math.fabs(axisDiff[i]) > 0.05) {
            axis[pullAxis] * Math.fabs(axisDiff[i]) => setGain[i];
            // Could have mapped "... * (Math.fabs(axisDiff[i]) - 0.05) / 0.95
        } else {
            0 => setGain[i];
        }
    }
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
                1 => vibrato;
            } else if (msg.isButtonUp()) {
                0 => vibrato;
            }
        }
    }
}


/////////////////
// RUN THREADS //
/////////////////

spork ~ network();
spork ~ gametrak();

100::ms => dur TEMPO;

// infinite time loop
while( true ) {
    
    // Set gain and pitch depending on quadrant function
    clientGain * setGain[0] => osc1.gain;
    clientGain * setGain[1] => osc2.gain;
    
    clientPitch + setMotif[0] => Std.mtof => osc1.freq;
    clientPitch + setMotif[1] => Std.mtof => osc2.freq;
    
    //<<< setMotif[0], setMotif[1] >>>;
    //<<< setGain[0], setGain[1] >>>;
    //<<< axisDiff[0], axisDiff[1] >>>;

    if (vibrato == 1) {
        0.02 => c.modDepth;
    } else {
        0 => c.modDepth;
    }
    
    TEMPO => now;
}



