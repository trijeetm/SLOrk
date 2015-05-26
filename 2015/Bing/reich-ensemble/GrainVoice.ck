dac.channels() => int NUM_CHANNELS;
<<<NUM_CHANNELS>>>;

48000 => float srate; //just for reference (could change elsewhere!)

// default filename (can be overwritten via input argument)
//"E2_Ah.wav" => string FILENAME;
"E2_Ee.wav" => string FILENAME;
//"E2_Ooh.wav" => string FILENAME;

// get file name, if one specified as input argument
if( me.args() > 0 ) me.arg(0) => FILENAME;

// overall volume
1 => float MAIN_VOLUME;
// grain duration base
200::ms => dur GRAIN_LENGTH;
// factor relating grain duration to ramp up/down time
.50 => float GRAIN_RAMP_FACTOR;
// playback rate
1 => float GRAIN_PLAY_RATE;
// grain position (0 start; 1 end)
1 => float NEW_GRAIN_PLAY_RATE;

0.2 => float GRAIN_POSITION;
// grain position randomization
0 => float GRAIN_POSITION_RANDOM;
// grain jitter (0 == periodic fire rate)
55 => float GRAIN_FIRE_RANDOM;
60 => int FUNDAMENTAL;

1::ms => dur GLISS_TIME;

0.0 => float interval;

// max lisa voices=
30 => int LISA_MAX_VOICES;
// load file into a LiSa (use one LiSa per sound)
load( FILENAME ) @=> LiSa @ lisa;

// patch it
PoleZero blocker => Gain g => LPF lpf => LPF lpf_block => NRev reverb => dac;
// connect
lisa.chan(0) => blocker;

// reverb mix
.2 => reverb.mix;
// pole location to block DC and ultra low frequencies
.99 => blocker.blockZero;
10000 => lpf.freq;
10000 => lpf_block.freq;
0.0 => g.gain;

// HID objects
Hid hi;
HidMsg msg;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// open joystick 0, exit on fail
if( !hi.openKeyboard( device ) ) me.exit();
// log
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

// keys

54 => int KEY_COMMA;
55 => int KEY_PERIOD;
79 => int KEY_RIGHT;
80 => int KEY_LEFT;
81 => int KEY_DOWN;
82 => int KEY_UP;
53 => int KEY_TILDE;
30 => int KEY_1;
31 => int KEY_2;
32 => int KEY_3;
33 => int KEY_4;
34 => int KEY_5;
35 => int KEY_6;
36 => int KEY_7;
37 => int KEY_8;
38 => int KEY_9;
39 => int KEY_0;
45 => int KEY_DASH;
46 => int KEY_EQUAL;
42 => int KEY_DELETE;
229 => int KEY_SHIFT;
29 => int KEY_Z;
27 => int KEY_X;
56 => int KEY_SLASH;
4 => int KEY_A;
22 => int KEY_S;
7 => int KEY_D;
9 => int KEY_F;
10 => int KEY_G;
11 => int KEY_H;

//40 => int KEY_DASH;

//booleans
0 => int UP_HELD;
0 => int DOWN_HELD;
0 => int SHIFT_HELD;
0 => int Z_HELD;
0 => int X_HELD;
0 => int SLASH_HELD;
0 => int GAIN_RAMPING;

// spork it
spork ~ kb();

// main loop
while( true )
{
    // fire a grain
    fireGrain();
    // amount here naturally controls amount of overlap between grains
    (GRAIN_LENGTH / 2 + Math.random2f(0,GRAIN_FIRE_RANDOM)::ms)/10 => dur delta;
    delta => now;
    
    delta/GLISS_TIME => float percentChange;
    //<<<percentChange>>>;
    //<<<interval>>>;
    
    if(interval > 0.0) percentChange * interval + GRAIN_PLAY_RATE => GRAIN_PLAY_RATE;
    if(interval < 0.0) percentChange * interval * 2 + GRAIN_PLAY_RATE => GRAIN_PLAY_RATE;
    
    
    if(interval > 0.0 && GRAIN_PLAY_RATE > NEW_GRAIN_PLAY_RATE){
        NEW_GRAIN_PLAY_RATE => GRAIN_PLAY_RATE;
        0.0 => interval;
    }
    if(interval < 0.0 && GRAIN_PLAY_RATE < NEW_GRAIN_PLAY_RATE){
        NEW_GRAIN_PLAY_RATE => GRAIN_PLAY_RATE;
        0.0 => interval;
    }
    
    
}

// fire!
fun void fireGrain()
{
    // grain length
    GRAIN_LENGTH => dur grainLen;
    // ramp time
    GRAIN_LENGTH * GRAIN_RAMP_FACTOR => dur rampTime;
    // play pos
    GRAIN_POSITION + Math.random2f(0,GRAIN_POSITION_RANDOM) => float pos;
    // a grain
    if( lisa != null && pos >= 0 )
        spork ~ grain( lisa, pos * lisa.duration(), grainLen, rampTime, rampTime, 
        GRAIN_PLAY_RATE );
}

// grain sporkee
fun void grain( LiSa @ lisa, dur pos, dur grainLen, dur rampUp, dur rampDown, float rate )
{
    // get a voice to use
    lisa.getVoice() => int voice;
    
    // if available
    if( voice > -1 )
    {
        //<<<"Rate is :", rate>>>;
        // set rate
        lisa.rate( voice, rate );
        // set playhead
        lisa.playPos( voice, pos );
        // ramp up
        lisa.rampUp( voice, rampUp );
        // wait
        (grainLen - rampUp) => now;
        // ramp down
        lisa.rampDown( voice, rampDown );
        // wait
        rampDown => now;
    }
}

fun void shift(int note){
    FUNDAMENTAL => Std.mtof => float fund;
    fund => float target;
    if(SHIFT_HELD) note + 12 => note;
    if(SHIFT_HELD && SLASH_HELD) note + 12 => note;
    if(UP_HELD) FUNDAMENTAL + note => Std.mtof => target;
    if(DOWN_HELD) FUNDAMENTAL - note => Std.mtof => target;
    
    //target/fund - 1.0 => interval;
    target/fund => NEW_GRAIN_PLAY_RATE;
    NEW_GRAIN_PLAY_RATE / GRAIN_PLAY_RATE - 1.0 => interval;
}

fun string getFullFilename(string ext){
    return (me.sourceDir() + "/clips/" + ext);
}

fun void handleLeft(){
    if(GLISS_TIME > 1000::ms) GLISS_TIME - 1000::ms => GLISS_TIME;
    else 1::ms => GLISS_TIME;
    <<<"gliss time is : ", GLISS_TIME/srate, "s">>>;
}

fun void handleRight(){
    if(GLISS_TIME < 10::second) GLISS_TIME + 1000::ms => GLISS_TIME;
    <<<"gliss time is : ", GLISS_TIME/srate, "s">>>;
}

fun void gainDown(){
    while(Z_HELD){
        g.gain() - 0.003 => g.gain;
        Math.max(g.gain(), 0.0) => g.gain;
        50::ms => now;
        <<<"gain is : ",g.gain()>>>;

    }
}

fun void gainUp(){
    while(X_HELD){
        g.gain() + 0.003 => g.gain;
        Math.min(g.gain(), 1.0) => g.gain;
        50::ms => now;
        <<<"gain is : ",g.gain()>>>;
    }
}

fun void rampToGain(float target){
    1 => int notThere;
    1 => GAIN_RAMPING;
    
    0 => int increasing;
    if(target > g.gain()) 1 => increasing;
    
    while(notThere){
        if(increasing) g.gain() + 0.002 => g.gain;
        else g.gain() - 0.002 => g.gain;
        
        if( g.gain() >= target && increasing) 0 => notThere; //we've increased enough
        if( g.gain() <= target && !increasing) 0 => notThere; //we've decreased enough
        80::ms => now;
        <<<"gain is : ",g.gain()>>>;
    }
    target => g.gain;
    
    0 => GAIN_RAMPING;
}

fun void handleZ(){
    spork ~ gainDown();
}

fun void handleX(){
    spork ~ gainUp();
}

// keyboard
fun void kb()
{
    // infinite event loop
    while( true )
    {
        // wait on HidIn as event
        hi => now;
        
        // messages received
        while( hi.recv( msg ) )
        {
            // button donw
            //<<<msg.which>>>;
            if( msg.isButtonDown() )
            {
                if( msg.which == KEY_LEFT )
                {
                    handleLeft();
                }
                else if( msg.which == KEY_RIGHT )
                {
                   handleRight();
                }
                else if( msg.which == KEY_DOWN )
                {
                    1 => DOWN_HELD;
                }
                else if( msg.which == KEY_UP )
                {
                    1 => UP_HELD;
                }
                else if( msg.which == KEY_COMMA )
                {
                    
                }
                else if( msg.which == KEY_PERIOD )
                {
                    
                }
                else if( msg.which == KEY_TILDE )
                {
                    shift(0);
                }
                else if( msg.which == KEY_1 )
                {
                    shift(1);
                }
                else if( msg.which == KEY_2 )
                {
                    shift(2);
                }
                else if( msg.which == KEY_3 )
                {
                    shift(3);
                }
                else if( msg.which == KEY_4 )
                {
                    shift(4);
                }
                else if( msg.which == KEY_5 )
                {
                    shift(5);
                }
                else if( msg.which == KEY_6 )
                {
                    shift(6);
                }
                else if( msg.which == KEY_7 )
                {
                    shift(7);
                }
                else if( msg.which == KEY_8 )
                {
                    shift(8);
                }
                else if( msg.which == KEY_9 )
                {
                    shift(9);
                }
                else if( msg.which == KEY_0 )
                {
                    shift(10);
                }
                else if( msg.which == KEY_DASH )
                {
                    shift(11);
                }
                else if( msg.which == KEY_EQUAL )
                {
                    shift(12);
                }
                else if( msg.which == KEY_SHIFT )
                {
                    1 => SHIFT_HELD;
                }
                else if( msg.which == KEY_Z )
                {
                    1 => Z_HELD;
                    handleZ();
                }
                else if( msg.which == KEY_X )
                {
                    1 => X_HELD;
                    handleX();
                }
                else if( msg.which == KEY_SLASH )
                {
                    1 => SLASH_HELD;
                }
                else if( msg.which == KEY_A )
                {
                    if(!GAIN_RAMPING) spork ~ rampToGain(0.00);
                }
                else if( msg.which == KEY_S )
                {
                    if(!GAIN_RAMPING) spork ~ rampToGain(0.005);
                }
                else if( msg.which == KEY_D )
                {
                    if(!GAIN_RAMPING) spork ~ rampToGain(0.02);
                }
                else if( msg.which == KEY_F )
                {
                    if(!GAIN_RAMPING) spork ~ rampToGain(0.08);
                }
                else if( msg.which == KEY_G )
                {
                    if(!GAIN_RAMPING) spork ~ rampToGain(0.15);
                }
                else if( msg.which == KEY_H )
                {
                    if(!GAIN_RAMPING) spork ~ rampToGain(0.3);
                }
            } else{
                if( msg.which == KEY_DOWN )
                {
                    0 => DOWN_HELD;
                }
                else if( msg.which == KEY_UP )
                {
                    0 => UP_HELD;
                }
                else if( msg.which == KEY_SHIFT )
                {
                    0 => SHIFT_HELD;
                }
                else if( msg.which == KEY_Z )
                {
                    0 => Z_HELD;
                }
                else if( msg.which == KEY_X )
                {
                    0 => X_HELD;
                }
                else if( msg.which == KEY_SLASH )
                {
                    0 => SLASH_HELD;
                }
                
            }
        }
    }
}

// load file into a LiSa
fun LiSa load( string filename )
{
    // sound buffer
    SndBuf buffy;
    // load it
    getFullFilename(filename) => buffy.read;
    
    // new LiSa
    LiSa lisa;
    // set duration
    buffy.samples()::samp => lisa.duration;
    
    // transfer values from SndBuf to LiSa
    for( 0 => int i; i < buffy.samples(); i++ )
    {
        // args are sample value and sample index
        // (dur must be integral in samples)
        lisa.valueAt( buffy.valueAt(i), i::samp );        
    }
    
    // set LiSa parameters
    lisa.play( false );
    lisa.loop( false );
    lisa.maxVoices( LISA_MAX_VOICES );
    
    return lisa;
}
