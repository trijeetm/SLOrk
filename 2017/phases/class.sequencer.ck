//-----------------------------------------------------------------------------
// name: sequencer.ck
// desc: a 12/8 time sequencer
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: spring 2017
//       Stanford University
//-----------------------------------------------------------------------------

public class Sequencer {
    12 => int SEQ_LEN;

    int sequence[0][SEQ_LEN][2];

    0 => int measures;
    0 => int playhead;
    0 => int offset;
    0 => int measure;

    fun void addMeasure(int measure[][]) {
        sequence << measure;
        measures++;
    }

    fun int tick() {
        playhead + 1 => playhead;
        if (playhead == SEQ_LEN) {
            0 => playhead;
            (measure + 1) % measures => measure;
            return -1;
        }
        else {
            return playhead;
        }
    }

    fun void incOffset() {
        (offset + 1) % SEQ_LEN => offset;
    }

    fun void decOffset() {
        if (offset > 0) offset - 1 => offset;
    }

    fun void resetOffset() {
        0 => offset;
    }

    fun int getOffset() {
        return offset;
    }

    fun int getPlayheadPosition() {
        return (playhead + offset) % SEQ_LEN;
    }

    fun int hasNote() {
        if (measures == 0) {
            return false;
        }
        return sequence[measure][getPlayheadPosition()][0];
    }

    fun int getNote() {
        return sequence[measure][getPlayheadPosition()][0];
    }

    fun int getLength() {
        return sequence[measure][getPlayheadPosition()][1];
    }
}