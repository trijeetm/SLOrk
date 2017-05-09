//-----------------------------------------------------------------------------
// name: interpolator.ck
// desc: interpolator for float values
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: winter 2016
//       Stanford University
//-----------------------------------------------------------------------------

// TODO create a non blokcing interpolator

public class Interpolator {
    // interpolator values
	float start, end, current;
    dur duration, delta;

    // setup
    fun void setup(float _start, float _end, dur _duration) {
        _start => start;
        _start => current;
        _end => end;
        _duration => duration;
        100::samp => delta;
    }

    // interpolate
    fun void interpolate() {
        spork ~ interpolator();
    }

    // interpolator
    fun void interpolator() {
        start => current;
        (end - start) / (duration / delta) => float step;
        if (end > start) {
            while (current < end) {
                current + step => current;
                delta => now;
            }   
        }
        else {
            while (current > end) {
                current + step => current;
                delta => now;
            }
        }
        end => current;
    }

    // current interpolated value
    fun float getCurrent() {
        return current;
    }
}