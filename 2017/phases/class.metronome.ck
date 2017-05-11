//-----------------------------------------------------------------------------
// name: metronome.ck
// desc: a metronome with a sixteenth note resolution
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: winter 2016
//       Stanford University
//-----------------------------------------------------------------------------

public class Metronome {
    // fidelity of metronome
    16 => int NOTE_SUBDIVISION;

    int measure;
    int wholeNoteCount, halfNoteCount, quarterNoteCount, eighthNoteCount, sixteenthNoteCount;
    float bpm;
    dur quanta;
    int isMetroOn;
    Event tick;
    Event measureTick;
    Event wholeNoteTick;
    Event halfNoteTick;
    Event quarterNoteTick;
    Event eighthNoteTick;
    Event sixteenthNoteTick;
    int beatNumber, beatMeasure;

    // init
    0 => measure;
    0 => wholeNoteCount;
    0 => halfNoteCount;
    0 => quarterNoteCount;
    0 => eighthNoteCount;
    0 => sixteenthNoteCount;
    false => isMetroOn;

    // setup
    fun void setup(float _bpm, int _beatNumber, int _beatMeasure) {
        _bpm => bpm;
        _beatNumber => beatNumber;
        _beatMeasure => beatMeasure;
        ((1 / bpm) / (NOTE_SUBDIVISION / 4))::minute => quanta;
        <<< quanta >>>;
    }

    fun void updateBpm(float newBpm) {
        newBpm => bpm;
        ((1 / bpm) / (NOTE_SUBDIVISION / 4))::minute => quanta;
    }

    fun float getBpm() {
        return bpm;
    }

    fun void interpBpm(float start, float end, dur duration) {
        Interpolator iBpm;
        iBpm.setup(start, end, duration);
        iBpm.interpolate();
        while (start != end) {
            updateBpm(iBpm.getCurrent());
            1::samp => now;
        }
    }

    fun void start() {
        true => isMetroOn;
        spork ~ startTick();
    }

    fun void stop() {
        false => isMetroOn;
    }

    fun int getSixteenthNoteCount() {
        return (sixteenthNoteCount % 16) + 1;
    }

    fun int getEighthNoteCount() {
        return (eighthNoteCount % 8) + 1;
    }

    fun int getQuarterNoteCount() {
        return (quarterNoteCount % 4) + 1;
    }

    fun int getHalfNoteCount() {
        return (halfNoteCount % 2) + 1;
    }

    fun int getWholeNoteCount() {
        return (wholeNoteCount % 1) + 1;
    }

    // TODO: update for other time signatures
    fun dur getSixteenthBeatDur() {
        return quanta * 1;
    }

    fun dur getEighthBeatDur() {
        return quanta * 2;
    }

    fun dur getQuarterBeatDur() {
        return quanta * 4;
    }

    fun dur getHalfBeatDur() {
        return quanta * 8;
    }

    fun dur getWholeBeatDur() {
        return quanta * 16;
    }
    // TODO

    fun dur getMeasureDur() {
        return (quanta * NOTE_SUBDIVISION) * (beatNumber / beatMeasure);
    }

    fun dur getMeasureDur(int nMeasures) {
        return (quanta * NOTE_SUBDIVISION) * (beatNumber / beatMeasure) * nMeasures;
    }

    fun int getMeasure() {
        return measure;
    }

    fun void tickMeasure() {
        measure + 1 => measure;
        measureTick.broadcast();
    }

    fun void waitTillMeasure(int _measure) {
        while (measure < _measure) {
            measureTick => now;
        }
    }

    fun void waitForMeasures(int n) {
        for (0 => int m; m < n; m++)
            measureTick => now;
    }

    fun void startTick() {
        while (isMetroOn) {
            // update beat counts and measure
            // 1/16th
            sixteenthNoteCount + 1 => sixteenthNoteCount;
            sixteenthNoteTick.broadcast();

            // 1/8th
            if (sixteenthNoteCount % 2 == 0) {
                1 +=> eighthNoteCount;
                eighthNoteTick.broadcast();

                if (beatMeasure == 8) {
                    if (eighthNoteCount % beatNumber == 0) {
                        tickMeasure();
                    }
                }
            }

            // 1/4th
            if (sixteenthNoteCount % 4 == 0) {
                1 +=> quarterNoteCount;
                quarterNoteTick.broadcast();

                if (beatMeasure == 4) {
                    if (eighthNoteCount % beatNumber == 0) {
                        tickMeasure();
                    }
                }
            }

            // 1/2
            if (sixteenthNoteCount % 8 == 0) {
                1 +=> halfNoteCount;
                halfNoteTick.broadcast();
            }

            // 1
            if (sixteenthNoteCount % 16 == 0) {
                1 +=> wholeNoteCount;
                wholeNoteTick.broadcast();
            }

            // fire tick (at sixteenth note quanta)
            tick.broadcast();
            quanta => now;
        }
    }
}

//     16th
//  1  2  3  4
//  5  6  7  8
//  9 10 11 12
// 13 14 15 16