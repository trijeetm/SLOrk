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

    Metronome metro;
    Synth synth;
    Sequencer seq;

    false => int isPlaying;
    0 => int state;

    0 => int offset;

    fun void init(int _id, OscSend _xmit, float bpm) {
        _id => id;
        _xmit @=> xmit;

        metro.setup(bpm, 12, 8);

        initPlayer(metro.getSixteenthBeatDur());
        synth.init(metro.getSixteenthBeatDur());

        int measure[][];
        [[36, 1], [36, 1], [36, 1], [0, 1], [60, 1], [60, 1], [0, 1], [60, 1], [0, 1], [48, 1], [48, 1], [0, 1]] @=> measure;
        // int measure[][];
        // [[36, 1], [36, 1], [36, 1], [60, 1], [60, 1], [60, 1], [60, 1], [60, 1], [60, 1], [48, 1], [48, 1], [60, 1]] @=> measure;
        seq.addMeasure(measure);
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

            if (seq.hasNote()) {
                triggerPlayer(seq.getNote(), seq.getLength());
            }

            seq.tick();
        }
    }

    fun void watch() {
        while (isPlaying) {
            metro.measureTick => now;

            <<< metro.getMeasure() >>>;
            <<< "   track: ", id, "offset: ", seq.getOffset() >>>;
        }
    }

    fun void incOffset() {
        metro.measureTick => now;
        seq.incOffset();
    }

    fun void decOffset() {
        metro.measureTick => now;
        seq.decOffset();
    }

    fun void cue(int s) {

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
}