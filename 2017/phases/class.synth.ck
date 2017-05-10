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
    SawOsc saw => env;
    Noise noise => BiQuad filter => env;

    dur baseNoteDur;
    0::ms => dur noteDur;

    fun void init(dur _baseNoteDur) {
        _baseNoteDur => baseNoteDur;

        setNote(48);
        setDur(baseNoteDur);

        // set biquad pole radius
        .99 => filter.prad;
        // set biquad gain
        .05 => filter.gain;
        // set equal zeros
        1 => filter.eqzs;

        0 => sin.gain;
        0 => tri.gain;
        0 => saw.gain;
        0 => noise.gain;

        env.set(0.001, 0, 1, 0.1);
    }

    fun void setNote(int note) {
        Std.mtof(note) => float freq;

        freq => sin.freq;
        freq => tri.freq;
        freq => saw.freq;
        freq * 2 => filter.pfreq;
    }

    fun void setDur(dur _dur) {
        _dur => noteDur;
    }

    fun void setDur(int _len) {
        _len * baseNoteDur => noteDur;
    }

    fun void setOscGain(int osc, int gain) {
        <<< osc, gain >>>;
        if (osc == 0)
            gain / 127.0 => sin.gain;
        if (osc == 1)
            gain / 127.0 => tri.gain;
        if (osc == 2)
            gain / 127.0 => saw.gain;
        if (osc == 3)
            gain / 127.0 => noise.gain;
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