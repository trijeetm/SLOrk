OscSend xmitters[6];
Track tracks[6];
0 => int currTrack;

initNetwork();

spork ~ handleMIDI();

main();

fun void main() {
    tracks[0].init(0, xmitters[0], 200);
    tracks[0].play();

    tracks[1].init(1, xmitters[1], 200);
    tracks[1].play();

    tracks[2].init(2, xmitters[2], 200);
    tracks[2].play();

    while (true) 1::second => now;
}

fun void initNetwork() {
    // host name and port
    string HOSTS[0];
    6449 => int port;

    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";
    HOSTS << "localhost";

    HOSTS.size() => int nHosts;

    // send object
    OscSend xmit[nHosts];

    // aim the transmitter
    for (0 => int i; i < nHosts; i++) {
        xmit[i].setHost(HOSTS[i], port + i);
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
                    <<< currTrack >>>;
                }
                // set osc gain
                if ((msg.data2 >= 20) && (msg.data2 <= 23)) {
                    tracks[currTrack].setSynthGain(msg.data2 - 20, msg.data3);
                }
            }

            if ((msg.data2 == 101) && (msg.data1 == 144)) {
                tracks[currTrack].decOffset();
            }
            if ((msg.data2 == 100) && (msg.data1 == 144)) {
                tracks[currTrack].incOffset();
            }
        }
    }
}