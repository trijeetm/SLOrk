// ----------------------------------------------------
// name: circle of zen
//
// author: Trijeet Mukhopadhyay (trijeetm@stanford.edu)
// ----------------------------------------------------

// ----------------------------------------------------
// notes:
// phones: 0
// vol: 0.5, low pass: 140
// master: -10
// ----------------------------------------------------

// z axis deadzone
0.02 => float DEADZONE;

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

6000::ms => dur maxLooperPeriod;
6 => int maxLevels;
maxLooperPeriod / Math.pow(2, maxLevels) => dur minLooperPeriod;

class Percussor {
    // sound buffers 
    8 => int nSamples;
    SndBuf bassSamples[nSamples];
    SndBuf hemiSamples1[nSamples];
    Gain hemiSamples1Gain;
    0 => hemiSamples1Gain.gain;
    SndBuf hemiSamples2[nSamples];
    Gain hemiSamples2Gain;
    0 => hemiSamples2Gain.gain;
    
    Math.random2(0, 1) => int speaker;
    
    // data members
    int level;
    int instrument;
    Gain g[nSamples];
    NRev r[nSamples];
    float gain[nSamples];
    float rmix[nSamples];

fun void init(int c1, int c2) {
        // load samples and chuck to dac
        for (0 => int i; i < nSamples; i++) {
            0 => g[i].gain;
            0 => r[i].mix;
            .15 => r[i].gain;
            dirRoot + sampleFiles[i] => string sampleSrc;
            
            sampleSrc => bassSamples[i].read;
            0 => bassSamples[i].rate;
            
            sampleSrc => hemiSamples1[i].read;
            0 => hemiSamples1[i].rate;
            
            sampleSrc => hemiSamples2[i].read;
            0 => hemiSamples2[i].rate;
            
            // bass channel
            if (c1 < 3)
                bassSamples[i] => r[i] => g[i] => dac.chan(1);
            else
                bassSamples[i] => r[i] => g[i] => dac.chan(0); 
                
            // hemi channels
            hemiSamples1[i] => r[i] => g[i] => hemiSamples1Gain => dac.chan(c1);
            hemiSamples2[i] => r[i] => g[i] => hemiSamples2Gain => dac.chan(c2);
            
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
            }

            period => now;
        }
    }

    fun void triggerPercussion(int id) {
        if (id < 0)
            return;

        1 => bassSamples[id].rate;   
        0 => bassSamples[id].pos;
        
        (speaker + 1) % 2 => speaker;
        if (speaker == 0) {
            0.5 => hemiSamples1Gain.gain;
            0.05 => hemiSamples2Gain.gain;
        }
        else {
            0.05 => hemiSamples1Gain.gain;
            0.5 => hemiSamples2Gain.gain;
        }
        
        <<< "perc: (i, l, g, r, s)", instrument, level, gain[instrument], rmix[instrument], speaker >>>;

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

leftPercussor.init(4, 5);
rightPercussor.init(2, 3);

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
    Math.pow(Math.fabs(gt.axis[0] * 100) / 100 * 1.5, 1) + 0.1 => leftPercussor.gain[leftPercussor.instrument] => leftPercussor.g[leftPercussor.instrument].gain;
    Math.pow(Math.fabs(gt.axis[3] * 100) / 100 * 1.5, 1) + 0.1 => rightPercussor.gain[rightPercussor.instrument] => rightPercussor.g[rightPercussor.instrument].gain;
    0.2 => float revRange;
    0.05 => float minRev;
    minRev + revRange - Math.pow(Math.fabs(gt.axis[1] * 100) / 100 * revRange, 1) => leftPercussor.rmix[leftPercussor.instrument] => leftPercussor.r[leftPercussor.instrument].mix;
    minRev + revRange - Math.pow(Math.fabs(gt.axis[4] * 100) / 100 * revRange, 1) => rightPercussor.rmix[rightPercussor.instrument] => rightPercussor.r[rightPercussor.instrument].mix;

// level selector
    0.08 => float zPerlevel;
    0 => int _level;
    // left hand
    (gt.axis[2] / zPerlevel) $ int => _level;
    leftPercussor.updateLevel(_level);
    // right hand
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