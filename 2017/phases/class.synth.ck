//-----------------------------------------------------------------------------
// name: synth.ck
// desc: a synth composed of simple signals
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: spring 2017
//       Stanford University
//-----------------------------------------------------------------------------

public class Synth {
    ADSR env => dac;

    SinOsc sin => env;
    TriOsc tri => env;
    Noise noise => TwoPole filter => env;

    dur baseNoteDur;
    0::ms => dur noteDur;

    fun void init(dur _baseNoteDur) {
        _baseNoteDur => baseNoteDur;

        setNote(48);
        setDur(baseNoteDur);

        1  => filter.norm;
        0.1 => filter.gain;
        0.1 => noise.gain;

        env.set(0.001, 0, 1, 0.1);
    }

    fun void setNote(int note) {
        Std.mtof(note) => float freq;

        freq => sin.freq;
        freq + 2 => tri.freq;
        freq => filter.freq;
    }

    fun void setDur(dur _dur) {
        _dur => noteDur;
    }

    fun void setDur(int _len) {
        _len * baseNoteDur => noteDur;
    }

    fun void play(int _note, int _len) {
        setNote(_note);
        setDur(_len);

        spork ~ _play();
    }

    fun void _play() {
        env.keyOn();
        noteDur => now;
        env.keyOff();
    }
}