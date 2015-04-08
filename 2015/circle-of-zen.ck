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


// root directory
me.sourceDir() + "/" => string dirRoot;
if( me.args() ) me.arg(0) => dirRoot;

// sound buffers 
8 => int nSamples;
SndBuf samples[nSamples];

[
    "High 1_bip.aif",
    "Mid 1_bip.aif",
    "Low 1_bip.aif",
    "Cym 1.aif",
    "High 2_bip.aif",
    "Low 2_bip.aif",
    "Mid 2_bip.aif",
    "Cym 2.aif"
] @=> string sampleFiles[];

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

4000::ms => dur maxLooperPeriod;
5 => int maxLevels;
maxLooperPeriod / Math.pow(2, maxLevels) => dur minLooperPeriod;

class Percussor {
    int level;
    int instrument;
    Gain g;
    JCRev r;
    float gain;
    float rmix;

    fun void init(int channel) {
        0 => g.gain;
        0 => r.mix;
        // load samples and chuck to dac
        for (0 => int i; i < nSamples; i++) {
            dirRoot + sampleFiles[i] => string sampleSrc;
            samples[i] => r => g => dac.chan(channel);
            sampleSrc => samples[i].read;
            0 => samples[i].rate;
        }
    }

    fun void looper() {
        while (true) {
            dur period;

            if (level == 0)
                minLooperPeriod => period;
            else {
                maxLooperPeriod => period;
                for (0 => int i; i < level; i++)
                    period / 2 => period;
                triggerPercussion(instrument);

                <<< "perc: (i, l, g, r)", instrument, level, gain, rmix >>>;
            }

            period => now;
        }
    }

    fun void triggerPercussion(int id) {
        if (id < 0)
            return;

        1 => samples[id].rate;   
        0 => samples[id].pos;
    }

    fun void updateLevel(int lev) {
        if (lev > maxLevels)
            maxLevels => level;
        else 
            lev => level;
    }
}

Percussor leftPercussor;
Percussor rightPercussor;

leftPercussor.init(0);
rightPercussor.init(1);

// spork control
spork ~ gametrak();
// print
// spork ~ print();
// looper for left percs
spork ~ leftPercussor.looper();
// looper for right percs
spork ~ rightPercussor.looper();

100 => int gainAmp;

// main loop
while( true )
{  
// instrument selector
    // left hand
    if (gt.axis[0] > 0) {
        if (gt.axis[1] > 0)
            0 => leftPercussor.instrument;
        else {
            1 => leftPercussor.instrument;
        }
    }
    else {
        if (gt.axis[1] > 0)
            2 => leftPercussor.instrument;
        else {
            3 => leftPercussor.instrument;
        }
    }
    // right hand
    if (gt.axis[3] > 0) {
        if (gt.axis[4] > 0)
            4 => rightPercussor.instrument;
        else {
            5 => rightPercussor.instrument;
        }
    }
    else {
        if (gt.axis[4] > 0)
            6 => rightPercussor.instrument;
        else {
            7 => rightPercussor.instrument;
        }
    }

// control parameters
    Math.pow(Math.fabs(gt.axis[0]), 2) => leftPercussor.gain => leftPercussor.g.gain;
    Math.pow(Math.fabs(gt.axis[3]), 2) => rightPercussor.gain => rightPercussor.g.gain;
    Math.pow(Math.fabs(gt.axis[1]) * 0.25, 1) => leftPercussor.rmix => leftPercussor.r.mix;
    Math.pow(Math.fabs(gt.axis[4]) * 0.25, 1) => rightPercussor.rmix => rightPercussor.r.mix;

// level selector
    0.1 => float zPerlevel;
    0 => int _level;
    // left hand
    0.1 => leftPercussor.gain;
    (gt.axis[2] / zPerlevel) $ int => _level;
    leftPercussor.updateLevel(_level);
    // right hand
    0.1 => rightPercussor.gain;
    (gt.axis[5] / zPerlevel) $ int => _level;
    rightPercussor.updateLevel(_level);

// beat
    1::ms => now;
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
        10::ms => now;
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