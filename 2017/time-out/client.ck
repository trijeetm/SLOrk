LiveSampler sampler;

// gametrack
GameTrak gt;

dur measureLength;
4 => int subdivisions;

[ 0, 0, 0, 0, 0, 0, 0, 0, 0 ] @=> int sequence[];

false => int envelopeSetMode;
false => int currentlyRecordingEnvelope;
[0.0, 1.0, 0.0] @=> float envArr[];

main();

fun void main() {
    spork ~ handleServer();

    sampler.init();
    sampler.setEnvelopeArr(envArr);

    // spork ~ gametrak();
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
            }

            // joystick button down
            else if( msg.isButtonDown() )
            {
                <<< "button", msg.which, "down" >>>;
                if (envelopeSetMode) {
                    true => currentlyRecordingEnvelope;
                    spork ~ trackEnvelope();
                }
            }

            // joystick button up
            else if( msg.isButtonUp() )
            {
                <<< "button", msg.which, "up" >>>;
                false => currentlyRecordingEnvelope;
                if (envelopeSetMode) {
                  sampler.setEnvelopeArr(envArr);
                  false => envelopeSetMode;
                }
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
    | 1 - 9:    30 - 38 |
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
    | space     44      |
    | l_shift   225     |
    ---------------------
*/

    // the device number to open
    0 => int deviceNum;

    // instantiate a HidIn object
    HidIn hi;
    // structure to hold HID messages
    HidMsg msg;
    false => int shiftDn;
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
            //<<< "key: ", key >>>;

            // check for action type
            if (msg.isButtonDown()) {
                // use SPACE to start recording sampler
                if (key == 44) {
                    /*sampler.pause();*/
                    sampler.startSampling();
                }
                // use UP ARROW to fire sampler
                if (key == 25) {
                    sampler.trigger(1);
                }
                // when LSHIFT is pressed, enable shift mode
                if (key == 225) {
                    true => shiftDn;
                }
                // use NUMERIC KEYS to configure sequencer
                if (30 <= key && key <= 38) {
                    (key - 29) => int seqNum;
                    if (shiftDn) {
                        seqNum => subdivisions;
                    } else {
                        if (sequence[seqNum-1]) {
                            false => sequence[seqNum-1];
                        } else {
                            true => sequence[seqNum-1];
                        }
                    }
                }
                // use LETTER E to toggle envelope setting mode
                if (key == 8) {
                  if (envelopeSetMode) {
                    false => envelopeSetMode;
                  } else {
                    true => envelopeSetMode;
                  }
                }
            }
            else {
                if (key == 44) {
                    sampler.stopSampling();
                    /*sampler.play();*/
                }
                if (key == 225) {
                    false => shiftDn;
                }
            }
        }
    }
}

fun void handleServer() {
    // create our OSC receiver
    OscRecv recv;
    // use port 6449
    6449 => recv.port;
    // start listening (launch thread)
    recv.listen();

    // create an address in the receiver, store in new variable
    recv.event( "/conductor/beat, f" ) @=> OscEvent oe;

    // infinite event loop
    while ( true )
    {
        // wait for event to arrive
        oe => now;

        // grab the next message from the queue.
        while ( oe.nextMsg() != 0 )
        {
            // getFloat fetches the expected float (as indicated by "f")
            oe.getFloat()::ms => measureLength;
            <<< measureLength >>>;

            spork ~ tickMeasure();
        }
    }
}

fun void tickMeasure() {
    for (0 => int i; i < subdivisions; i++) {
        if (sequence[i]) {
            spork ~ playSample();
        }
        "" => string sequenceState;
        for (0 => int j; j < subdivisions; j++) {
            if (i == j) {
                sequenceState + "[|]" => sequenceState;
            } else if (sequence[j]) {
                sequenceState + "[•]" => sequenceState;
            } else {
                sequenceState + "[ ]" => sequenceState;
            }
        }
        <<< sequenceState >>>;
        measureLength / subdivisions => now;
    }
}

fun void playSample() {
    sampler.trigger(1);
}

fun void trackEnvelope() {
    float _envArr[0];
    _envArr @=> envArr;

    while (currentlyRecordingEnvelope) {
        float value;
        if (gt.axis[2] < 0.5) {
            gt.axis[2] * 2 => value;
        }
        else {
            1.0 => value;
        }
        envArr << value;

        256::samp => now;
    }
}
