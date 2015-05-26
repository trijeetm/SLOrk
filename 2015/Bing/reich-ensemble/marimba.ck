/////////
// STK //
/////////
ModalBar bar => NRev r => LPF lpf => Gain g => Gain master => dac;

0.03 => r.mix;
0 => g.gain;

3000 => lpf.freq;

0 => bar.preset;        // marimba
0.1 => bar.stickHardness;
0.1 => bar.strikePosition;

////////////
// SCALES //
////////////
0 => int scale;
int scales[4][7];

// number of octave to start from 
6 - 2 => int octaveOffset;

// cMaj
// eMaj
// DflatMaj
// bMaj

// scale 1
[0, 2, 4, 5, 7, 9, 11] @=> scales[0];
// scale 2
[4, 6, 8, 9, 11, 13, 15] @=> scales[1];
// scale 3
[1, 3, 5, 6, 8, 10, 12] @=> scales[2];
// scale 4
[11, 13, 15, 16, 18, 20, 22] @=> scales[3];

////////////
// MOTIFS //
////////////
0 => int motif;
int motifs[3][16];
3 => int nMotifs;       // number of motifs, update when changed

/*
-1 : rest
0+ : note number in scale 
*/
// motif 1
[14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14] @=> motifs[0];
// motif 2
[19, -1, -1, 18, 16, -1, 19, -1, -1, 18, 16, -1, 23, -1, 18, -1] @=> motifs[1];
// motif 3
[21, 18, 15, -1, 19, 16, -1, 13, -1, 18, -1, 15, 12, -1, 16, -1] @=> motifs[2];

0 => int motifPlayhead;

// 0: half-time, 1: regular-time, 2: double-time
0 => int currentMotifRate;     
0 => int nextMotifRate;

0 => int pitchShift;
// root, third, fifth
[-3, 0, 3] @=> int pitchShiftAmounts[];

//////////////
// GAMETRAK //
//////////////
// z axis deadzone
0.02 => float DEADZONE;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// HID objects
Hid trak;
HidMsg msg;

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
spork ~ gametrak();

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
                // <<< "button", msg.which, "down" >>>;
                1 => gt.isButton;
                cycleMotif();
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                // <<< "button", msg.which, "up" >>>;
                0 => gt.isButton;
            }
        }
    }
}

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

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

// server properties
float serverGain;
0 => int count;
0 => int nBeats;

// all ze sporks!
spork ~ network();

spork ~ lfo();

// infinite time loop
while( true ) 1::second => now;

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
                omsg.getInt(0) => scale;
                omsg.getFloat(1) => serverGain;
                omsg.getInt(2) => nBeats;
                omsg.getInt(3) => count;

                serverGain => master.gain;

                play();
            }
        }
    }
}

///////////////
// SYNTHESIS //
///////////////
false => int sync;

fun void play() {
    if (sync == false) {
        if (count != 0)
            return;
        else
            true => sync;
    }

    // gametrak modulation
    // gain
    Math.pow(gt.axis[5], 2) * 2 => g.gain;
    // pitch shift
    ((gt.axis[3] + 0.9) / (2.0 / 3)) $ int => pitchShift;
//    <<< gt.axis[3] >>>;
    // rate
    if (gt.axis[2] < 0.3)
        0 => nextMotifRate;
    else if (gt.axis[2] < 0.5)
        1 => nextMotifRate;
    else 
        2 => nextMotifRate;

    // change motifRate
    if (nextMotifRate != currentMotifRate) {
        if (count % nBeats == 0) {
            nextMotifRate => currentMotifRate;
            0 => motifPlayhead;
        }
    }

    // regular-time
    if (currentMotifRate == 1) {
        playRegularTime();
    }
    // double-time
    if (currentMotifRate == 2) {
        playDoubleTime();
    }
    // half-time
    if (currentMotifRate == 0) {
        playHalfTime();
    }
}

fun void playRegularTime() {
    if (count % 2 == 0)
        tickBar();
}

fun void playDoubleTime() {
    tickBar();
}

fun void playHalfTime() {
    if (count % 4 == 0)
        tickBar();
}

fun void tickBar() {
    motifs[motif][motifPlayhead] => int note;
    (motifPlayhead + 1) % 16 => motifPlayhead;
    if (note == -1)
        return; 
    pitchShiftAmounts[pitchShift] + note => note;
    (12 * (octaveOffset + (note / 7))) + scales[scale][note % 7] => int midi;
    midi => Std.mtof => bar.freq;
    
    Math.random2f(0.2, 0.4) => bar.stickHardness;
    Math.random2f(0.4, 0.4) => bar.strikePosition;
    
    1 => bar.masterGain;
    0.6 => bar.directGain;
    
    Math.random2f(0.5, 1) => bar.strike;

    <<< "-------------------------------------------------" >>>;
    <<< "Rate:", nextMotifRate, " |  Motif:", motif, " |  Shift:", pitchShift, " |  Note:", midi >>>;
}

fun void cycleMotif() {
    (motif + 1) % nMotifs => motif;
}

fun void lfo() {
    0 => float T;
    
    while (true) {
        
        1000 + (Math.fabs(Math.sin(T)) * 4000) => lpf.freq;
        //0 => lpf.freq;
        
        //        <<< Math.fabs(Math.sin(T)) * 0.01 >>>;
        
        90::ms => now;
        T + (2 * Math.PI / 360) => T; 
    }
}