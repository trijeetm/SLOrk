OscSend xmitters[6];
Track tracks[6];
0 => int currTrack;

initNetwork();

spork ~ handleMIDI();

main();

fun void main() {
    tracks[0].init(0, xmitters[0], 100);
    tracks[0].play();

    /*
        workaround to play full clapping seq by default without midi controller
    */
    tracks[0].unmute();
    tracks[0].selectClappingSeq(7);

    /*
    tracks[1].init(1, xmitters[1], 200);
    tracks[1].play();

    tracks[2].init(2, xmitters[2], 200);
    tracks[2].play();

    tracks[3].init(3, xmitters[3], 200);
    tracks[3].play();

    tracks[4].init(4, xmitters[4], 200);
    tracks[4].play();

    tracks[5].init(5, xmitters[5], 200);
    tracks[5].play();
    */

    while (true) 1::second => now;
}

fun void initNetwork() {
    // host name and port
    string HOSTS[0];
    6449 => int port;

    HOSTS << "localhost";

    HOSTS.size() => int nHosts;

    // send object
    OscSend xmit[nHosts];

    // aim the transmitter
    for (0 => int i; i < nHosts; i++) {
        xmit[i].setHost(HOSTS[i], port);
    }

    xmit @=> xmitters;
}

fun void handleMIDI() {
    // number of the device to open (see: chuck --probe)
    1 => int device;
    // get command line
    if( me.args() ) me.arg(0) => Std.atoi => device;

    // the midi event
    MidiIn min;
    // the message for retrieving data
    MidiMsg msg;

    // open the device
    if( !min.open( device ) ) me.exit();

    // print out device that was opened
    <<< "MIDI device:", min.num(), " -> ", min.name() >>>;

    // infinite time-loop
    while(true) {
        // wait on the event 'min'
        min => now;

        // get the message(s)
        while(min.recv(msg)) {
            // <<< msg.data1, msg.data2, msg.data3 >>>;
            if ((msg.data1 >= 176) && (msg.data1 <= 181)) {
                // select track
                if (msg.data2 == 16) {
                    msg.data1 - 176 => currTrack;
                    //<<< currTrack >>>;
                }
                // set osc gain
                if ((msg.data2 >= 20) && (msg.data2 <= 23)) {
                    tracks[currTrack].setSynthGain(msg.data2 - 20, msg.data3);
                }

                // set attack
                if (msg.data2 == 16) {
                    tracks[currTrack].setSynthAttack(msg.data3);
                }
                // set release
                if (msg.data2 == 19) {
                    tracks[currTrack].setSynthRelease(msg.data3);
                }
            }

            // change offset
            if ((msg.data2 == 101) && (msg.data1 == 144)) {
                tracks[currTrack].decOffset();
            }
            if ((msg.data2 == 100) && (msg.data1 == 144)) {
                tracks[currTrack].incOffset();
            }

            // mute / unmute
            if ((msg.data2 == 91) && (msg.data1 == 144)) {
                tracks[currTrack].unmute();
            }
            if ((msg.data2 == 92) && (msg.data1 == 144)) {
                tracks[currTrack].mute();
            }

            // select clapping seq
            if (msg.data2 == 53) {
                if ((msg.data1 >= 144) && (msg.data1 <= 151)) {
                    tracks[currTrack].selectClappingSeq(msg.data1 - 144);
                }
            }

            // select phase
            if (msg.data2 == 52) {
                if (msg.data1 == 144)
                    tracks[currTrack].phase(50);
                if (msg.data1 == 145)
                    tracks[currTrack].phase(25);
                if (msg.data1 == 146)
                    tracks[currTrack].phase(10);
                if (msg.data1 == 147)
                    tracks[currTrack].phase(5);
                if (msg.data1 == 148)
                    tracks[currTrack].phase(4);
            }
        }
    }
}