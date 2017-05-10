Synth synth;
false => int ready;
0 => int id;

// create our OSC receiver
OscRecv recv;

main();

fun void main() {
    Std.atoi(me.arg(0)) => id;

    setupNetwork();

    spork ~ init();
    spork ~ handleConductor();

    spork ~ handleSynthGain();

    while (true) 1::second => now;
}

fun void setupNetwork() {
    // use port 6449
    6449 + id => recv.port;
    // start listening (launch thread)
    recv.listen();
}

fun void init() {
    // create an address in the receiver, store in new variable
    "/player/init/" + id + ", " + "f" => string path;
    recv.event(path) @=> OscEvent oe;

    // infinite event loop
    while (true) {
        // wait for event to arrive
        oe => now;

        // grab the next message from the queue.
        while (oe.nextMsg() != 0) {
            oe.getFloat()::samp => dur baseNoteDur;
            synth.init(baseNoteDur);
            true => ready;
            <<< "player init" >>>;
        }
    }
}

fun void handleConductor() {
    // create an address in the receiver, store in new variable
    "/player/trigger/" + id + ", " + "i, i" => string path;
    recv.event(path) @=> OscEvent oe;

    // infinite event loop
    while (true) {
        oe => now;

        if (ready) {
            // wait for event to arrive

            // grab the next message from the queue.
            while (oe.nextMsg() != 0) {
                oe.getInt() => int note;
                oe.getInt() => int len;
                <<< note, len >>>;
                synth.play(note, len);
            }
        }
    }
}

fun void handleSynthGain() {
    // create an address in the receiver, store in new variable
    "/player/synth/gain/" + id + ", " + "i, i" => string path;
    recv.event(path) @=> OscEvent oe;

    // infinite event loop
    while (true) {
        oe => now;

        if (ready) {
            // wait for event to arrive

            // grab the next message from the queue.
            while (oe.nextMsg() != 0) {
                oe.getInt() => int osc;
                oe.getInt() => int gain;
                synth.setOscGain(osc, gain);
            }
        }
    }
}