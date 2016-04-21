Snap snaps[4];
0 => int currSnap;
1 => int chord;

main();

fun void main() {
    Metronome metro;
    metro.setup(120, 4, 4);

    snaps[0].init(metro, 1);
    snaps[1].init(metro, 2);
    snaps[2].init(metro, 1);
    snaps[3].init(metro, 2);

    metro.start();

    snaps[0].start();
    snaps[1].start();
    snaps[2].start();
    snaps[3].start();

    spork ~ keyboard();

    while (true) {
        <<< "---------------", currSnap, chord, "---------------" >>>;
        snaps[0].log();
        snaps[1].log();
        snaps[2].log();
        snaps[3].log();

        100::ms => now;
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
                // gain
                if (key == 82) 
                    snaps[currSnap].rampGain(0.005);
                if (key == 81) 
                    snaps[currSnap].rampGain(-0.005);

                // rate
                if (key == 80) 
                    snaps[currSnap].rampRate(-0.0025);
                if (key == 79) 
                    snaps[currSnap].rampRate(0.0025);

                // rev
                if (key == 54) 
                    snaps[currSnap].rampRev(-0.001);
                if (key == 55) 
                    snaps[currSnap].rampRev(0.001);

                // feedback
                if (key == 51) 
                    snaps[currSnap].rampFeedback(-0.01);
                if (key == 52) 
                    snaps[currSnap].rampFeedback(0.01);

                // freq
                if ((key >= 30) || (key <= 34))
                    snaps[currSnap].setFreq(key - 29);

                // motif
                if (key == 20)
                    snaps[currSnap].selectMotif(0);
                if (key == 26)
                    snaps[currSnap].selectMotif(1);
                if (key == 8)
                    snaps[currSnap].selectMotif(2);
                if (key == 21)
                    snaps[currSnap].selectMotif(3);

                // chord
                if (key == 4) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(60, 64, 67, 71);
                    1 => chord;
                }
                if (key == 22) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(62, 66, 69, 74);
                    2 => chord;
                }
                if (key == 7) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(59, 60, 64, 67);
                    3 => chord;
                }
                if (key == 9) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(60, 64, 67, 71);
                    4 => chord;
                }
                if (key == 10) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(57, 60, 64, 67);
                    5 => chord;
                }
                if (key == 11) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(59, 60, 64, 67);
                    6 => chord;
                }
                if (key == 13) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(60 - 12, 64 - 12, 67 - 12, 72 - 12);
                    7 => chord;
                }
                if (key == 14) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(62 - 12, 66 - 12, 69 - 12, 74 - 12);
                    7 => chord;
                }
                if (key == 15) {
                    for (0 => int i; i < 4; i++)
                        snaps[i].tune(64 - 12, 67 - 12, 71 - 12, 76 - 12);
                    8 => chord;
                }

                // rand
                if (key == 46)
                    snaps[currSnap].incRand(0.1);
                if (key == 45)
                    snaps[currSnap].decRand(0.1);

                // snap
                if (key == 29)
                    0 => currSnap;
                if (key == 27)
                    1 => currSnap;
                if (key == 6)
                    2 => currSnap;
                if (key == 25)
                    3 => currSnap;
            }
            else {
                if ((key == 82) || (key == 81))
                    snaps[currSnap].rampGain(0);

                if ((key == 80) || (key == 79))
                    snaps[currSnap].rampRate(0);

                if ((key == 54) || (key == 55))
                    snaps[currSnap].rampRev(0);

                if ((key == 51) || (key == 52))
                    snaps[currSnap].rampFeedback(0);
            }
        }
    }
}
