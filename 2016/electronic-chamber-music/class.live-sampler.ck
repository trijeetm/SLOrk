//-----------------------------------------------------------------------------
// name: live-sampler.ck
// desc: live sampler and granulizer wrapper for lisa
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: spring 2016
//       Stanford University
//-----------------------------------------------------------------------------

public class LiveSampler {
    LiSa sampler; 
    false => int isSampling;
    false => int isPlaying;
    true => int loading;
    false => int modulating;
    NRev rev;
    Gain master;

    // granulator parameters
    1::second => dur duration;
    duration => dur length;
    0::second => dur position;
    1 => float rate;
    100::ms => dur rampUp;
    100::ms => dur rampDown;
    length => dur fireRate;

    fun void init() {
        sampler => rev => master => dac;

        sampler.maxVoices(200);

        0.2 => rev.mix;
        0 => master.gain;
    }

    fun void sample() {
        record();

        SndBuf buff;
        me.dir() + "mic-sample.wav" => buff.read;

        buff.samples()::samp => sampler.duration;
        buff.samples()::samp => duration;
        buff.samples()::samp => length;
        buff.samples()::samp => fireRate;

        for (0 => int i; i < buff.samples(); i++) {
            (buff.valueAt(i), i::samp) => sampler.valueAt;
        }

        <<< sampler.duration() >>>;

        false => loading;
    }

    fun void record() {
        adc => WvOut w => blackhole;
        "mic-sample.wav" => string sampleFilename;
        sampleFilename => w.wavFilename;

        while (isSampling)
            512::samp => now;

        w.closeFile();

        0.1::second => now;
    }

    fun void startSampling() {
        true => isSampling;
        true => loading;

        spork ~ sample();
    }

    fun void stopSampling() {
        false => isSampling;
    }

    fun void setLength(float l) {
        duration * l => length;
    }

    fun void setPos(float p) {
        duration * p => position;
    }

    fun void setRate(float r) {
        r => rate;
    }

    fun void setFireRate(dur r) {
        r => fireRate;
    }

    fun void setGain(float g) {
        g => master.gain;
    }

    fun void play() {
        while (loading)
            512::samp => now; 

        true => isPlaying;

        spork ~ loop();
    }

    fun void pause() {
        false => isPlaying;
    }

    fun void loop() {
        while (isPlaying) {
            fireGrain();
            fireRate => now;
        }
    }

    fun void fireGrain(float l, float p, float r) {
        setLength(l);
        setPos(p);
        setRate(r);

        fireGrain();
    }

    fun void fireGrain() {
        spork ~ grain();
    }

    fun void hold() {
        true => modulating;

        spork ~ fade();
    }

    fun void release() {
        false => modulating;
    }

    fun void fade() {
        master.gain() => float start;
        (start / (30 * 100)) => float step;

        while (modulating) {
            setGain(master.gain() - step);
            1::ms => now;
        }
    }

    fun void grain() {
        <<< master.gain(), fireRate, position, length, rate >>>;
        sampler.getVoice() => int voice;

        if (voice > -1) {
            sampler.rate(voice, rate);
            sampler.loop(voice, 0);
            sampler.playPos(voice, position);
            sampler.rampUp(voice, rampUp);
            length - (rampUp + rampDown) => now;
            sampler.rampDown(voice, rampDown);
            rampDown => now;
        }
    }
}