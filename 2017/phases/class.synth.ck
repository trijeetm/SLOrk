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
    SqrOsc sqr => env;
    SawOsc saw => env;
    Noise noise => BiQuad filter => env;

    dur baseNoteDur;
    0::ms => dur noteDur;

    OscSend gfxXmit;
    float rlsTime, atkTime;

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
        0 => sqr.gain;
        0 => saw.gain;
        0 => noise.gain;

        env.set(0.001, 0, 1, 0.001);

        gfxXmit.setHost("localhost", 12000);
        0.5 => rlsTime => atkTime;
    }

    fun void setNote(int note) {
        Std.mtof(note) => float freq;

        freq => sin.freq;
        freq => sqr.freq;
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
        float _gain;
        Math.pow(gain / 127.0, 2) => _gain;
        if (osc == 0)
            _gain => sin.gain;
        if (osc == 1)
            _gain => sqr.gain;
        if (osc == 2)
            _gain => saw.gain;
        if (osc == 3)
            _gain => noise.gain;
    }

    fun void setAttack(int atk) {
        <<< atk >>>;
        env.attackTime((atk / 127.0) * noteDur);
        <<< env.attackTime() >>>;
    }

    fun void setRelease(int rel) {
        <<< rel >>>;
        env.releaseTime((rel / 127.0) * noteDur * 8);
        <<< env.releaseTime() >>>;
    }

    fun void play(int _note, int _len) {
        setNote(_note);
        setDur(_len);

        spork ~ _play();
    }

    fun void _play() {
        gfxFadeIn();
        env.keyOn();
        noteDur => now;
        gfxFadeOut();
        env.keyOff();
    }

    fun void gfxFadeIn() {
        "/screen/fadeIn" => string path;
        gfxXmit.startMsg(path, "f");
        atkTime => gfxXmit.addFloat;
    }

    fun void gfxFadeOut() {
        "/screen/fadeOut" => string path;
        gfxXmit.startMsg(path, "f");
        rlsTime => gfxXmit.addFloat;
    }
}