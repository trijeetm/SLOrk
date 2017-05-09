//-----------------------------------------------------------------------------
// name: sequencer.ck
// desc: a 4/4 time sequencer with 8th note resolution
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: spring 2017
//       Stanford University
//-----------------------------------------------------------------------------

public class Sequencer {
    int sequence[0][8][2];

    0 => int measures;
    0 => int playhead;
    0 => int measure;

    fun void addMeasure(int measure[][]) {
        sequence << measure;
        measures++;
    }

    fun void tick() {
        playhead + 1 => playhead;
        if (playhead == 8) {
            0 => playhead;
            (measure + 1) % measures => measure;
        }
    }

    fun int hasNote() {
        if (measures == 0) {
            return false;
        }
        return sequence[measure][playhead][0];
    }

    fun int getNote() {
        return sequence[measure][playhead][0];
    }

    fun int getLength() {
        return sequence[measure][playhead][1];
    }
}