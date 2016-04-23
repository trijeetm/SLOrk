LiveSampler sampler;

false => int sustain;

main();

fun void main() {
    sampler.init();

    spork ~ gametrak();
    spork ~ keyboard();

    while (true) 1::second => now;
}

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

// print
fun void print(GameTrak gt) {
    // time loop
    while( true )
    {
        // values
        <<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2], gt.axis[3],gt.axis[4],gt.axis[5] >>>;
        // advance time
        100::ms => now;
    }
}

fun void gametrak() {
    // z axis deadzone
    .032 => float DEADZONE;

    // which joystick
    0 => int device;
    // get from command line
    if( me.args() ) me.arg(0) => Std.atoi => device;
    // gametrack
    GameTrak gt;

    // HID objects
    Hid trak;
    HidMsg msg;

    // open joystick 0, exit on fail
    if( !trak.openJoystick( device ) ) me.exit();

    // print
    <<< "joystick '" + trak.name() + "' ready", "" >>>;

    // spork ~ print(gt);

    while (true) {
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

                if (sustain == false) {
                    // hook up gametrack values 
                    // left hand
                    sampler.setGain(Math.pow(gt.axis[2], 0.5));
                    ((gt.axis[0] + 1) / 2) * 1::second + 50::ms => dur fireRate;
                    sampler.setFireRate(fireRate);

                    // right hand
                    sampler.setPos((gt.axis[3] + 1) / 5);
                    // sampler.setLength((gt.axis[4] + 1) / 2);
                    sampler.setRate(Math.pow(gt.axis[5], 0.25));
                    
                }
            }
            
            // joystick button down
            else if( msg.isButtonDown() )
            {
                <<< "button", msg.which, "down" >>>;
                if (sustain == false) {
                    true => sustain;
                    sampler.hold();
                }
                else {
                    false => sustain;
                    sampler.release();
                }
                // sampler.pause();
                // sampler.startSampling();
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                <<< "button", msg.which, "up" >>>;
                // sampler.stopSampling();
                // sampler.play();
            }
        }
    }
}

fun void keyboard() {
/*
    ---------------------
    | mapping           |
    ---------------------
    | up:       82      |
    | down:     81      |
    | left:     80      |
    | right:    79      |
    ---------------------
    | 1 - 5:    30 - 34 |
    | <:        54      |
    | >:        55      |
    | q:        20      |
    | w:        26      |
    | e:        8       |
    | r:        21      |
    | ;:        51      |
    | ':        52      |
    | a:        4       |
    | s:        22      |
    | d:        7       |
    | f:        9       |
    | g:        10      |
    | h:        11      |
    | j:        13      |
    | k:        14      |
    | l:        15      |
    | -:        45      |
    | +:        46      |
    | z:        29      |
    | x:        27      |
    | c:        6       |
    | v:        25      |
    ---------------------
    44 space   
    ---------------------   
*/

    // the device number to open
    0 => int deviceNum;

    // instantiate a HidIn object
    HidIn hi;
    // structure to hold HID messages
    HidMsg msg;

    // open keyboard
    if (!hi.openKeyboard(deviceNum)) me.exit();
    // successful! print name of device
    <<< "keyboard '", hi.name(), "' ready" >>>;

    // infinite event loop
    while (true) {
        // wait on event
        hi => now;

        // get one or more messages
        while (hi.recv(msg)){
            msg.which => int key;
            // <<< "key: ", key >>>;

            // check for action type
            if (msg.isButtonDown()) {
                if (key == 44) {
                    sampler.pause();
                    sampler.startSampling();
                }

            }
            else {
                if (key == 44) {
                    sampler.stopSampling();
                    sampler.play();
                }
            }
        }
    }
}
