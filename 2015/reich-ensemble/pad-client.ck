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
                    play(pitch, velocity);
                }
            }
        }
    }
}

///////////////////////
// INSTRUMENT SOUNDS //
///////////////////////

SinOsc sin => Gain g => Chorus c => NRev r => dac;
5 => c.modFreq;
0 => c.modDepth;
1 => c.mix;

0 => float clientGain;
0 => int mute;

fun void play (float pitch, float velocity) {
    
    // set pitch
    pitch - 12 => Std.mtof => sin.freq;

    clientGain => g.gain;
    
    velocity => clientGain;
}

///////////////////////
// GAMETRACK FUNCTION //
///////////////////////

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
                    { msg.axisPosition => gt.axis[msg.which]; }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            } else if (msg.isButtonDown()) {
                1 => mute;
            } else if (msg.isButtonUp()) {
                0 => mute;
            }
        }
    }
}


/////////////////
// RUN THREADS //
/////////////////

spork ~ network();
spork ~ gametrak();

dur remainder;

// infinite time loop
while( true ) {
    clientGain * gt.axis[2] * 2 => g.gain;
    
    if (gt.axis[0] > 0.1) {
        (gt.axis[0] - 0.1) / 5 => r.mix;
    } else {
        0 => r.mix;
    }
    
    if (gt.axis[5] > 0.1) {
        (gt.axis[5] - 0.1) * 0.1 => c.modDepth;
        <<< (gt.axis[5] - 0.1) * 0.1 >>>;
    }
    
    if (mute == 1) {
        0 => g.gain;
    }
        
    
    50::ms => now;
}




