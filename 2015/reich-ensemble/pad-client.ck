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

int serverPitch;
float serverGain;

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
                if(omsg.getFloat(0) != serverPitch || omsg.getFloat(1) != serverGain) {
                    omsg.getInt(0) => serverPitch;
                    omsg.getFloat(1) => serverGain;
                }
            }
        }
    }
}

//////////////////////
// INSTRUMENT UGENS //
//////////////////////

SinOsc osc1 => Gain g => Chorus c => NRev r => dac;
TriOsc osc2 => g;

1 => g.gain;
3 => c.modFreq;
0 => c.modDepth;
0.5 => c.mix;
0.1 => r.mix;

// These will be controlled by the gametrak
0 => int vibrato;


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
    
    // prious axis data
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


////////////////////////////
// QUADRANT => PITCH/GAIN // (for Gametrak)
////////////////////////////

/*
Define quadrants:
Left:
   north : +7 (V)
   south : +0 (I)
   east  : +5 (IV)
   west  : -3 (vi)
Right:
   north : +11 (vii)
   south : +4  (iii)
   east  : +12 (I)
   west  : +7  (V)
*/

// Helpful to determine quadrant
float axisDiff[2];

// Outputs: 
// 1. Intervals to add to serverPitch
// 2. Gains
int addPitch[2];
float setGain[2];

fun void quadrant_output(float axis[]) {
    
    // Difference between abs. values of up/down and left/right
    Math.fabs(axis[1]) - Math.fabs(axis[0]) => axisDiff[0];
    Math.fabs(axis[4]) - Math.fabs(axis[3]) => axisDiff[1];
    
    // Quadrants define pitches
    // Left
    if (axisDiff[0] > 0) {
        if (axis[1] > 0) 7 => addPitch[0]; //north
        else             0 => addPitch[0]; //south
    } else {
        if (axis[0] > 0) 5 => addPitch[0]; //east
        else            -3 => addPitch[0]; //west
    }
    // Right
    if (axisDiff[1] > 0) {
        if (axis[4] > 0) 11 => addPitch[1]; //north
        else              4 => addPitch[1]; //south
    } else {
        if (axis[3] > 0) 12 => addPitch[1]; //east
        else              7 => addPitch[1]; //west
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


/////////////////
// RUN THREADS //
/////////////////

spork ~ network();
spork ~ gametrak();

100::ms => dur TEMPO;

// infinite time loop
while( true ) {
    
    // Set gain and pitch depending on quadrant function
    serverGain * setGain[0] => osc1.gain;
    serverGain * setGain[1] => osc2.gain;
    
    serverPitch + addPitch[0] => Std.mtof => osc1.freq;
    serverPitch + addPitch[1] => Std.mtof => osc2.freq;
    
    //<<< addPitch[0], addPitch[1] >>>;
    //<<< setGain[0], setGain[1] >>>;
    //<<< axisDiff[0], axisDiff[1] >>>;

    if (vibrato == 1) {
        0.02 => c.modDepth;
    } else {
        0 => c.modDepth;
    }
    
    TEMPO => now;
}



