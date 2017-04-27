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
    Chorus chorus;
    Envelope env;

    // granulator parameters
    [0.0, 1.0, 0.0] @=> float envelopeArr[];
    1::second => dur duration;
    duration => dur length;
    0::second => dur position;
    1 => float rate;
    0 => float rateMod;
    0::ms => dur rampUp;
    0::ms => dur rampDown;
    length => dur fireRate;

    fun void init() {
        sampler => env => chorus => rev => master => dac;

        spork ~ vibrato();

        sampler.maxVoices(200);

        0 => chorus.modDepth;
        0 => chorus.modFreq;
        0 => chorus.mix;

        0.05 => rev.mix;
        0 => master.gain;
    }

    fun void vibrato() {
        0.0001 => float delta;
        while (true) {
            delta + chorus.modDepth() => chorus.modDepth;

            if (chorus.modDepth() >= 0.1 - Math.fabs(delta))
            (-0.0001) => delta;
            if (chorus.modDepth() <= Math.fabs(delta))
            0.0001 => delta;

            10::ms => now;
        }
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
        spork ~ wobble();
        spork ~ modulate();
    }

    fun void release() {
        false => modulating;
    }

    fun void wobble() {
        (-1)::ms => dur delta;

        while (modulating) {
            if (fireRate <= 10::ms)
            1::ms => delta;
            if (fireRate >= 400::ms)
            (-1)::ms => delta;

            delta +=> fireRate;

            20::ms => now;
        }
    }

    fun void modulate() {
        500::ms => dur period;

        0::samp => dur t;
        1::ms => dur step;

        while (modulating) {
            Math.fabs(Math.sin(t / period)) * 0.2 => rateMod;

            t + step => t;
            step => now;
        }
    }

    fun void fade() {
        master.gain() => float start;
        (start / (60 * 1000)) => float step;

        while (modulating) {
            setGain(master.gain() - step);
            1::ms => now;

            if (master.gain() <= 0) {
                0 => master.gain;
                break;
            }
        }
    }

    fun void grain() {
        if (modulating)
        <<< "gain: ", master.gain(), "fireRate: ", fireRate / 1::ms, "pos: ", position / duration, "playback: ", rate + rateMod, "Chorus: ", chorus.mix(), chorus.modFreq(), chorus.modDepth(), "SUSTAINED" >>>;
        else
        <<< "gain: ", master.gain(), "fireRate: ", fireRate / 1::ms, "pos: ", position / duration, "playback: ", rate + rateMod, "Chorus: ", chorus.mix(), chorus.modFreq(), chorus.modDepth() >>>;
        sampler.getVoice() => int voice;

        if (voice > -1) {
            sampler.rate(voice, rate + rateMod);
            sampler.loop(voice, 0);
            sampler.playPos(voice, position);
            sampler.rampUp(voice, rampUp);
            length - (rampUp + rampDown) => now;
            sampler.rampDown(voice, rampDown);
            rampDown => now;
        }
    }

    fun void trigger(float gain) {
        setGain(gain);
        trigger();
    }

    fun void trigger() {
        sampler.getVoice() => int voice;

        if (voice > -1) {
            sampler.rate(voice, rate);
            sampler.loop(voice, 0);
            spork ~ envelope(length);
            sampler.playPos(voice, position);
            sampler.rampUp(voice, rampUp);
            length - (rampUp + rampDown) => now;
            sampler.rampDown(voice, rampDown);
            rampDown => now;
        }
    }

    fun void setEnvelopeArr(float envelopeVals[]) {
        envelopeVals @=> envelopeArr;
    }

    fun void envelope(dur duration) {
        envelopeArr.cap() => int numEnvSamples;
        (duration / (numEnvSamples - 1)) => dur envSampleDuration;
        env.value(envelopeArr[0]);
        for ( 0 => int i; i < numEnvSamples - 1; i++ ) {
            env.duration(envSampleDuration);
            env.target(envelopeArr[i+1]);
            envSampleDuration => now;
        }
    }
}
