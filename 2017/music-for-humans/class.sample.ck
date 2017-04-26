//-----------------------------------------------------------------------------
// name: sample.ck
// desc: play sound samples from the samples directory
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: winter 2016
//       Stanford University
//-----------------------------------------------------------------------------

public class Sample {
    me.sourceDir() + "/samples/" => string path;
    SndBuf buff;
    0.3 => float gainJitter;

    fun void init(string file) {
        path + file => string filename;
        filename => buff.read;
        0 => buff.gain;
        0 => buff.pos;
        0 => buff.rate;
    }

    fun SndBuf getBuff() {
        return buff;
    }

    fun void play(float gain, float rate, int pos) {
        0 => buff.gain;
        pos => buff.pos;
        gain => buff.gain;
        rate => buff.rate;
    }

    fun void play(float gain, float rate) {
        0 => buff.gain;
        if (rate >= 0)
            0 => buff.pos;
        else 
            buff.samples() => buff.pos;
        gain => buff.gain;
        rate => buff.rate;
    }

    fun void playWithJitter(float gain, float rate) {
        0 => buff.gain;
        0 => buff.pos;
        Math.random2f(gain - gainJitter / 2, gain + gainJitter / 2) => buff.gain;
        rate => buff.rate;
    }

    fun void play(float gain) {
        0 => buff.gain;
        0 => buff.pos;
        gain => buff.gain;
        1 => buff.rate;
    }

    fun void play() {
        0 => buff.gain;
        0 => buff.pos;
        1 => buff.gain;
        1 => buff.rate;
    }

    fun void stop() {
        0 => buff.gain;
        0 => buff.rate;
        buff.samples() => buff.pos;
    }

    fun void fadeOut(dur duration) {
        buff.gain() => float start;
        0 => float end;
        Interpolator interp;
        interp.setup(start, end, duration);
        interp.interpolate();
        while (interp.getCurrent() != interp.end) {
            interp.getCurrent() => buff.gain;
            interp.delta => now;
        }
        interp.getCurrent() => buff.gain;
        stop();
    }

    fun dur getLength() {
        return buff.length();
    }
}