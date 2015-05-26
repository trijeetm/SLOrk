// the device number to open
0 => int deviceNum;

// instantiate a HidIn object
Hid hi;
// structure to hold HID messages
HidMsg msg;

// open keyboard
if( !hi.openKeyboard( deviceNum ) ) me.exit();
// successful! print name of device
<<< "keyboard '", hi.name(), "' ready" >>>;

spork ~ handleKeyboard();


fun void rampToGain(float current, float target){
    1 => int notThere;
    1 => int GAIN_RAMPING;
    
    0 => int increasing;
    if(target > current) 1 => increasing;
    
    while(notThere){
        if(increasing) current + 0.002 => current;
        else current - 0.002 => current;
        
        if( current >= target && increasing) 0 => notThere; //we've increased enough
        if( current <= target && !increasing) 0 => notThere; //we've decreased enough
        80::ms => now;
        <<<"gain is : ",current>>>;
    }
    // target => current;
    
    0 => GAIN_RAMPING;
}

1 => float x;

while (true) {
    <<< x >>>;

    1::ms => now;
}

fun void handleKeyboard() {
    // infinite event loop
    while( true )
    {
        // wait on event
        hi => now;
        
        // get one or more messages
        while( hi.recv( msg ) )
        {
            // check for action type
            if( msg.isButtonDown() )
            {
                // print
                // <<< "down:", msg.which >>>;

                msg.which => int key;

                // note selector
                if (key == 30) {
                    48 => x;
                }
                if (key == 31) {
                    48 + 5 => x;
                }
                if (key == 32) {
                    48 + 7 => x;
                }
                if (key == 33) {
                    48 + 11 => x;
                }
                if (key == 34) {
                    48 + 12 => x;
                }
                /*
                */

            }
            else
            {
                // print
                // <<< "up:", msg.which >>>;
            }
        }
    }
}