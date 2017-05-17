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
    0.2 => float jitter;

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
        0 => buff.pos;
        gain => buff.gain;
        rate => buff.rate;
    }

    fun void playWithJitter(float gain, float rate) {
        0 => buff.gain;
        0 => buff.pos;
        Math.random2f(gain - jitter / 2, gain + jitter / 2) => buff.gain;
        Math.random2f(rate - (jitter * 2) / 2, rate + (jitter * 2) / 2) => buff.rate;
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

    fun dur getLength() {
        return buff.length();
    }
}