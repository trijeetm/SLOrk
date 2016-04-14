LiveSampler sampler;

main();

fun void main() {
    sampler.init();

    spork ~ gametrak();

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

                // hook up gametrack values 
                // left hand
                sampler.setGain(Math.pow(gt.axis[2], 0.5));
                ((gt.axis[0] + 1) / 2) * 1::second + 50::ms => dur fireRate;
                sampler.setFireRate(fireRate);

                // right hand
                sampler.setRate(Math.pow(gt.axis[5], 0.25));
                sampler.setLength((gt.axis[3] + 1) / 2);
                sampler.setPos((gt.axis[4] + 1) / 2);
            }
            
            // joystick button down
            else if( msg.isButtonDown() )
            {
                <<< "button", msg.which, "down" >>>;
                sampler.pause();
                sampler.startSampling();
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                <<< "button", msg.which, "up" >>>;
                sampler.stopSampling();
                sampler.play();
            }
        }
    }
}