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
    Sequencer clappingSeq[8];
    0 => int currSeq;

    false => int isPlaying;
    true => int isMute;
    false => int isPhasing;

    0 => int offset;

    fun void init(int _id, OscSend _xmit, float bpm) {
        _id => id;
        _xmit @=> xmit;
        bpm => originalBpm;

        metro.setup(bpm, 12, 8);

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

            if (clappingSeq[currSeq].hasNote() && !isMute) {
                triggerPlayer(clappingSeq[currSeq].getNote(), clappingSeq[currSeq].getLength());
            }

            clappingSeq[currSeq].tick();
        }
    }

    // use only for reading, never writing
    fun void watch() {
        while (isPlaying) {
            metro.measureTick => now;
            1::samp => now;
            <<< metro.getMeasure() >>>;
            <<< "[", !isMute, "]", " track:", id, "offset:", clappingSeq[currSeq].getOffset(), "seq:", currSeq, "(", isPhasing, ")" >>>;
        }
    }

    fun void incOffset() {
        spork ~ _incOffset();
    }

    fun void _incOffset() {
        metro.measureTick => now;
        clappingSeq[currSeq].incOffset();
    }

    fun void decOffset() {
        spork ~ _decOffset();
    }

    fun void _decOffset() {
        metro.measureTick => now;
        clappingSeq[currSeq].decOffset();
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
        s => currSeq;
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
        "/player/init/" + id => string path;
        xmit.startMsg(path, "f");
        lenInFloat => xmit.addFloat;
        <<< "init-ing player" >>>;
    }

    fun void triggerPlayer(int note, int len) {
        "/player/trigger/" + id => string path;
        xmit.startMsg(path, "i i");
        note => xmit.addInt;
        len => xmit.addInt;
    }

    fun void setSynthGain(int osc, int gain) {
        "/player/synth/gain/" + id => string path;
        xmit.startMsg(path, "i i");
        osc => xmit.addInt;
        gain => xmit.addInt;
    }

    fun void setSynthAttack(int atk) {
        "/player/synth/attack/" + id => string path;
        xmit.startMsg(path, "i");
        atk => xmit.addInt;
    }

    fun void setSynthRelease(int rel) {
        "/player/synth/release/" + id => string path;
        xmit.startMsg(path, "i");
        rel => xmit.addInt;
    }
}