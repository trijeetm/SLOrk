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

    fun void init(int _id, OscSend _xmit, float bpm) {
        _id => id;
        _xmit @=> xmit;

        metro.setup(bpm, 4, 4);

        initPlayer(metro.getSixteenthBeatDur());
        synth.init(metro.getSixteenthBeatDur());

        int measure[][];
        [[36, 1], [0, 1], [48, 1], [0, 1], [60, 1], [0, 1], [72, 1], [0, 1]] @=> measure;
        //seq.addMeasure(measure);
        //[[36, 4], [0, 1], [0, 1], [0, 1], [60, 1], [0, 1], [63, 1], [0, 1]] @=> measure;
        seq.addMeasure(measure);
    }

    fun void play() {
        metro.start();
        true => isPlaying;
        spork ~ loop();
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
                synth.play(seq.getNote(), seq.getLength() * metro.getSixteenthBeatDur());
            }

            seq.tick();
        }
    }

    fun void initPlayer(dur baseNoteLen) {
        baseNoteLen / 1::samp => float lenInFloat;
        "/player/init/" + id => string path;
        xmit.startMsg(path, "f");
        lenInFloat => xmit.addFloat;
        <<< "init-ing player" >>>;
    }
}