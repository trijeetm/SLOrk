//-----------------------------------------------------------------------------
// name: snap.ck
// desc: snap beat machine
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: spring 2016
//       Stanford University
//-----------------------------------------------------------------------------

public class Snap {
    Sample snap;
    Metronome metro;
    false => int isSnapping;
    0 => int count;
    1 => int rate;

    // control parameters
    float c_gain;
    float c_rate;
    float c_feedback;
    float c_rand;

    // filters
    KSChord ks;
    Echo echo;
    NRev rev;

    // motifs
    0 => int playhead;
    0 => int currMotif;
    [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
        [1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1],
        [1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]
    ] @=> int motifs[][];

    false => int r_gain;
    false => int r_rate;
    false => int r_rev;
    false => int r_feedback;

    fun void log() {
        <<< 
            "gain: ", c_gain,
            "rate: ", c_rate,
            "rev: ", rev.mix(),
            "feedback: ", c_feedback,
            "motif: ", currMotif,
            "random", c_rand
        >>>;
    }

    fun void init(Metronome _metro, int type) {
        if (type == 1)
            snap.init("snap1.wav");
        else
            snap.init("snap2.wav");

        snap.getBuff() => rev => dac;
        //snap.getBuff() => ks => rev => dac;

        tune(60, 64, 67, 71);

        0 => rev.mix;

        _metro @=> metro;

        0 => c_gain;
        1 => c_rate;
        0 => c_feedback;
        0 => c_rand;
    }

    fun void play(float gain, float rate) {
        snap.play(gain, rate - ((0.2 + Math.random2f(0, 0.4)) * c_rand));
    }

    fun void start() {
        true => isSnapping;

        spork ~ startSnapping();
    }

    fun void stop() {
        false => isSnapping;
    }

    fun void startSnapping() {
        while (isSnapping) {
            metro.tick => now;

            if (count % (16 / Math.pow(2, rate - 1)) == 0) {
                if (motifs[currMotif][playhead] == 1)
                    play(c_gain, c_rate);
                (playhead + 1) % 16 => playhead;        
            }

            (count + 1) % 16 => count;
        }
    }

    fun void setFreq(int f) {
        if ((f >= 1) && (f <= 5))
            f => rate;
    }

    fun void setGain(float g) {
        if ((g >= 0) && g <= 2)
            g => c_gain;
    }

    fun void setRev(float r) {
        if ((r >= 0) && r <= 1)
            r => rev.mix;
    }

    fun void setRand(float r) {
        if ((r >= 0) && r <= 1)
            r => c_rand;
    }

    fun void setRate(float r) {
        if ((r >= -2) && r <= 2)
            r => c_rate;
    }

    fun void _rampGain(float g) {
        true => r_gain;

        while (r_gain) {
            setGain(g + c_gain);
            50::ms => now;
        }
    }

    fun void rampGain(float g) {
        if (g == 0)
            false => r_gain;
        else
            spork ~ _rampGain(g);
    }

    fun void _rampRate(float r) {
        true => r_rate;

        while (r_rate) {
            setRate(r + c_rate);
            50::ms => now;
        }
    }

    fun void rampRate(float r) {
        if (r == 0)
            false => r_rate;
        else
            spork ~ _rampRate(r);
    }

    fun void _rampRev(float r) {
        true => r_rev;

        while (r_rev) {
            setRev(r + rev.mix());
            50::ms => now;
        }
    }

    fun void rampRev(float r) {
        if (r == 0)
            false => r_rev;
        else
            spork ~ _rampRev(r);
    }

    fun void selectMotif(int m) {
        m => currMotif;
    }

    fun void tune(float p1, float p2, float p3, float p4) {
        ks.tune(p1, p2, p3, p4);
    }

    fun void setFeedback(float fb) {
        if ((c_feedback < 1) && (c_feedback >= 0)) {
            (Math.pow(c_feedback, 0.3)) => float f;
            if ((f >= 0) && (f < 1)) {
                ks.feedback(f);
            }
        }
    }

    fun void _rampFeedback(float fb) {
        true => r_feedback;

        while (r_feedback) {
            fb +=> c_feedback;
            if (c_feedback < 0)
                0 => c_feedback;
            if (c_feedback > 1)
                1 => c_feedback;
            setFeedback(c_feedback);
            100::ms => now;
        }
    }

    fun void rampFeedback(float fb) {
        if (fb == 0)
            false => r_feedback;
        else
            spork ~ _rampFeedback(fb);
    }

    fun void incRand(float r) {
        setRand(r + c_rand);
    }

    fun void decRand(float r) {
        setRand(c_rand - r);
    }
}