//-----------------------------------------------------------------------------
// name: track.ck
// desc: a collection of synth tied to a metronome
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: spring 2017
//       Stanford University
//-----------------------------------------------------------------------------

public class Track {
    int id;
    OscSend xmit;
    float originalBpm;

    Metronome metro;
    Synth synth;
    dur baseNoteLen;

    Sequencer clappingSeq[8];
    0 => int currClappingSeq;

    Sequencer wavingSeq[1];
    0 => int currWavingSeq;

    false => int isPlaying;
    true => int isMute;
    false => int isPhasing;

    false => int isClappingSeq;
    false => int isWavingSeq;

    0 => int offset;

    fun void init(int _id, OscSend _xmit, float bpm) {
        _id => id;
        _xmit @=> xmit;
        bpm => originalBpm;

        metro.setup(bpm, 12, 8);

        metro.getSixteenthBeatDur() => baseNoteLen;

        initPlayer(metro.getSixteenthBeatDur());
        synth.init(metro.getSixteenthBeatDur());

        int measure[][];

        // xxx- xx-x -xx-

        // clapping seq 1
        [[36, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1]] @=> measure;
        clappingSeq[0].addMeasure(measure);

        // clapping seq 2
        [[36, 1], [36, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1]] @=> measure;
        clappingSeq[1].addMeasure(measure);

        // clapping seq 3
        [[36, 1], [36, 1], [0, 1], [0, 1], [60, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1]] @=> measure;
        clappingSeq[2].addMeasure(measure);

        // clapping seq 4
        [[36, 1], [36, 1], [0, 1], [0, 1], [60, 1], [0, 1], [0, 1], [60, 1], [0, 1], [48, 1], [0, 1], [0, 1]] @=> measure;
        clappingSeq[3].addMeasure(measure);

        // clapping seq 5
        [[36, 1], [36, 1], [0, 1], [0, 1], [60, 1], [60, 1], [0, 1], [60, 1], [0, 1], [48, 1], [48, 1], [0, 1]] @=> measure;
        clappingSeq[4].addMeasure(measure);

        // clapping seq 6
        [[36, 1], [36, 1], [36, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1]] @=> measure;
        clappingSeq[5].addMeasure(measure);

        // clapping seq 7
        [[0, 1], [0, 1], [0, 1], [0, 1], [60, 1], [60, 1], [0, 1], [60, 1], [0, 1], [48, 1], [48, 1], [0, 1]] @=> measure;
        clappingSeq[6].addMeasure(measure);

        // clapping seq full
        [[36, 1], [36, 1], [36, 1], [0, 1], [60, 1], [60, 1], [0, 1], [60, 1], [0, 1], [48, 1], [48, 1], [0, 1]] @=> measure;
        clappingSeq[7].addMeasure(measure);


        // waving seq 1
        [[48, 1], [50, 1], [52, 1], [54, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1], [0, 1]] @=> measure;
        wavingSeq[0].addMeasure(measure);
    }

    fun void play() {
        metro.start();
        true => isPlaying;
        spork ~ loop();
        spork ~ watch();
    }

    fun void pause() {
        false => isPlaying;
    }

    fun void stop() {
        metro.stop();
        false => isPlaying;
    }

    fun void loop() {
        while (isPlaying) {
            metro.eighthNoteTick => now;

            if (clappingSeq[currClappingSeq].hasNote() && !isMute && isClappingSeq) {
                <<< "." >>>;
                triggerPlayer(clappingSeq[currClappingSeq].getNote(), clappingSeq[currClappingSeq].getLength());
            }

            if (wavingSeq[currWavingSeq].hasNote() && !isMute && isWavingSeq) {
                if (wavingSeq[currWavingSeq].playhead == id) {
                    <<< "." >>>;
                    triggerPlayer(wavingSeq[currWavingSeq].getNote(), wavingSeq[currWavingSeq].getLength());
                }
            }

            clappingSeq[currClappingSeq].tick();
            wavingSeq[currWavingSeq].tick();
        }
    }

    // use only for reading, never writing
    fun void watch() {
        while (isPlaying) {
            metro.measureTick => now;
            1::samp => now;
            <<< metro.getMeasure() >>>;
            if (isClappingSeq)
                <<< "[", !isMute, "]", " track:", id, "offset:", clappingSeq[currClappingSeq].getOffset(), "seq:", currClappingSeq, "(", isPhasing, ")" >>>;
            if (isWavingSeq)
                <<< "[", !isMute, "]", " track:", id, "offset:", wavingSeq[currWavingSeq].getOffset(), "seq:", currWavingSeq, "(", isPhasing, ")" >>>;
        }
    }

    fun void incOffset() {
        spork ~ _incOffset();
    }

    fun void _incOffset() {
        metro.measureTick => now;
        if (isClappingSeq)
            clappingSeq[currClappingSeq].incOffset();
        if (isWavingSeq)
            wavingSeq[currWavingSeq].incOffset();
    }

    fun void decOffset() {
        spork ~ _decOffset();
    }

    fun void _decOffset() {
        metro.measureTick => now;
        if (isClappingSeq)
            clappingSeq[currClappingSeq].decOffset();
        if (isWavingSeq)
            wavingSeq[currWavingSeq].decOffset();
    }

    fun void mute() {
        spork ~ _mute();
    }

    fun void _mute() {
        metro.measureTick => now;
        true => isMute;
    }

    fun void unmute() {
        spork ~ _unmute();
    }

    fun void _unmute() {
        metro.measureTick => now;
        false => isMute;
    }

    fun void selectClappingSeq(int s) {
        metro.measureTick => now;
        s => currClappingSeq;
        true => isClappingSeq;
        false => isWavingSeq;
    }

    fun void selectWavingSeq(int s) {
        metro.measureTick => now;
        s => currWavingSeq;
        true => isWavingSeq;
        false => isClappingSeq;
    }

    fun void phase(int phaseLvl) {
        if (!isPhasing) {
            metro.measureTick => now;
            spork ~ _phase(phaseLvl);
        }
    }

    fun void _phase(int phaseLvl) {
        <<< "starting phase:", phaseLvl >>>;
        true => isPhasing;
        // slow
        if (phaseLvl == 4) {
            originalBpm * 1.04 => float newBpm;
            <<< newBpm, 26 >>>;
            metro.updateBpm(newBpm);
            metro.waitForMeasures(26);
            metro.updateBpm(originalBpm);
        }
        // slow
        if (phaseLvl == 5) {
            originalBpm * 1.05 => float newBpm;
            <<< newBpm, 21 >>>;
            metro.updateBpm(newBpm);
            metro.waitForMeasures(21);
            metro.updateBpm(originalBpm);
        }
        // med
        if (phaseLvl == 10) {
            originalBpm * 1.1 => float newBpm;
            <<< newBpm >>>;
            metro.updateBpm(newBpm);
            metro.waitForMeasures(11);
            metro.updateBpm(originalBpm);
        }
        // fast
        if (phaseLvl == 25) {
            originalBpm * 1.25 => float newBpm;
            <<< newBpm >>>;
            metro.updateBpm(newBpm);
            metro.waitForMeasures(5);
            metro.updateBpm(originalBpm);
        }
        // v fast
        if (phaseLvl == 50) {
            originalBpm * 1.5 => float newBpm;
            <<< newBpm >>>;
            metro.updateBpm(newBpm);
            metro.waitForMeasures(3);
            metro.updateBpm(originalBpm);
        }
        false => isPhasing;
    }

    fun void initPlayer(dur baseNoteLen) {
        baseNoteLen / 1::samp => float lenInFloat;
        "/player/init" => string path;
        xmit.startMsg(path, "i f");
        id => xmit.addInt;
        lenInFloat => xmit.addFloat;
        <<< "init-ing player" >>>;
    }

    fun void triggerPlayer(int note, int len) {
        spork ~ triggerNoteOn(note);
        spork ~ triggerNoteOff(baseNoteLen * len);
    }

    fun void triggerNoteOn(int note) {
        "/player/synth/noteOn" => string path;
        xmit.startMsg(path, "i i");
        id => xmit.addInt;
        note => xmit.addInt;
    }

    fun void triggerNoteOff(dur len) {
        len => now;
        "/player/synth/noteOff" => string path;
        xmit.startMsg(path, "i");
        id => xmit.addInt;
    }

    fun void setSynthGain(int osc, int gain) {
        "/player/synth/gain" => string path;
        xmit.startMsg(path, "i i i");
        id => xmit.addInt;
        osc => xmit.addInt;
        gain => xmit.addInt;
    }

    fun void setSynthAttack(int atk) {
        "/player/synth/attack" => string path;
        xmit.startMsg(path, "i i");
        id => xmit.addInt;
        atk => xmit.addInt;
    }

    fun void setSynthRelease(int rel) {
        "/player/synth/release" => string path;
        xmit.startMsg(path, "i i");
        id => xmit.addInt;
        rel => xmit.addInt;
    }
}