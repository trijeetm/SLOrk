
0.5::second => dur Q;

ModalBar bar1 => NRev r => dac;
ModalBar bar2 => r;

1 => r.gain;
0.02 => r.mix;

0 => bar1.preset; //Marimba
1 => bar1.stickHardness;
0.4 => bar1.strikePosition;

// Received from server


// Controlled by gametrak
0 => int diddit; // pedal
// could also control strikePosition using forward-back axis

fun void play (int pitch, dur T) {
    pitch => Std.mtof => bar1.freq;
    1 => bar1.strike;
    0.5 * Q => now;
    if (diddit == 1 ) {
        //pitch - 5 => Std.mtof => bar1.freq;
        1 => bar1.strike;
    }
    T - 0.5 * Q => now;
}

fun void play (int pitch1, int pitch2, dur T) {
    pitch1 => Std.mtof => bar1.freq;
    pitch2 => Std.mtof => bar2.freq;
    1 => bar1.strike;
    1 => bar2.strike;
    0.5 * Q => now;
    if (diddit == 1 ) {
        //pitch1 - 5 => Std.mtof => bar1.freq;
        //pitch2 - 5 => Std.mtof => bar2.freq;
        1 => bar1.strike;
        1 => bar2.strike;
    }
    T - 0.5 * Q => now;
}

while( true ) {
    play(64, 2*Q);
    play(69, Q);
    play(71, Q);
    play(73, 2*Q);
    play(69, 2*Q);
    play(71, 0.5*Q);
    play(59, 0.5*Q);
    play(69, 0.5*Q);
    play(57, 0.5*Q);
    play(68, 0.5*Q);
    play(56, 0.5*Q);
    play(64, 0.5*Q);
    play(59, 0.5*Q);
    play(69, 2*Q);
    play(81, 85, 2*Q);
}
