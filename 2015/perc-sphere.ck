// name: gametra.ck
// desc: gametrak boilerplate example
//
// author: Ge Wang (ge@ccrma.stanford.edu)
// date: summer 2014

// z axis deadzone
0 => float DEADZONE;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// HID objects
Hid trak;
HidMsg msg;

// open joystick 0, exit on fail
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

    // button 
    int isButton;
}

// gametrack
GameTrak gt;


// spork control
spork ~ gametrak();
// print
spork ~ print();

// globals
1000::ms => dur period;

Shakers shake => JCRev r => dac;
// set the gain
0.5 => r.gain;
// set the reverb mix
0.1 => r.mix;

// root directory
me.sourceDir() + "/" => string dirRoot;
if( me.args() ) me.arg(0) => dirRoot;

// sound buffers 
6 => int nSamples;
SndBuf samples[nSamples];

["High 1_bip.aif", "High 2_bip.aif", "Low 1_bip.aif", "Low 2_bip.aif", "Mid 1_bip.aif", "Mid 2_bip.aif"] @=> string sampleFiles[];

// load samples and chuck to dac
for (0 => int i; i < nSamples; i++) {
    dirRoot + sampleFiles[i] => string sampleSrc;
    samples[i] => dac;
    sampleSrc => samples[i].read;
    0 => samples[i].rate;
}

0 => int instrument;

// main loop
while( true )
{   
    triggerPercussion(instrument);        
    (instrument + 1) % nSamples => instrument;

    period => now;
}

fun void triggerPercussion(int id) {
    1 => samples[id].rate;   
    0 => samples[id].pos;
}

// print
fun void print()
{
    // time loop
    while( true )
    {
        // values
        <<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2], gt.axis[3],gt.axis[4],gt.axis[5] >>>;
        // advance time
        period => now;
    }
}

// gametrack handling
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
            }
            
            // joystick button down
            else if( msg.isButtonDown() )
            {
                <<< "button", msg.which, "down" >>>;
                1 => gt.isButton;
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                <<< "button", msg.which, "up" >>>;
                0 => gt.isButton;
            }
        }
    }
}