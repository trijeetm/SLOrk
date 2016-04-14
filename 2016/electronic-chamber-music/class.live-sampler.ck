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
    NRev rev;
    Gain master;

    // granulator parameters
    3::second => dur duration;
    duration => dur length;
    0::second => dur position;
    1 => float rate;
    100::ms => dur rampUp;
    100::ms => dur rampDown;
    duration => dur fireRate;

    fun void init() {
        adc => sampler => rev => master => dac;

        sampler.duration(1::second);
        sampler.maxVoices(200);
        sampler.recRamp(20::ms);

        0.1 => rev.mix;
        0 => master.gain;
    }

    fun void sample() {
        sampler.record(1);

        while (isSampling) {
            512::samp => now;
        }

        sampler.record(0);
    }

    fun void startSampling() {
        true => isSampling;

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