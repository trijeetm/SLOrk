//-----------------------------------------------------------------------------
// name: ks-chord.ck
// desc: karplus strong comb filter bank
//
// authors: Madeline Huberth (mhuberth@ccrma.stanford.edu)
//          Ge Wang (ge@ccrma.stanford.edu)
// date: summer 2014
//       Stanford Center @ Peking University
//-----------------------------------------------------------------------------

// single voice Karplus Strong chubgraph
public class KS extends Chubgraph
{
    // sample rate
    second / samp => float SRATE;
    
    // ugens!
    DelayA delay;
    OneZero lowpass;
    
    // noise, only for internal use
    Noise n => delay;
    // silence so it doesn't play
    0 => n.gain;
    
    // the feedback
    inlet => delay => lowpass => delay => outlet;
    // max delay
    1::second => delay.max;
    // set lowpass
    -1 => lowpass.zero;
    // set feedback attenuation
    .9 => lowpass.gain;

    // mostly for testing
    fun void play( float pitch, dur T )
    {
        tune( pitch ) => float length;
        // turn on noise
        1 => n.gain;
        // fill delay with length samples
        length::samp => now;
        // silence
        0 => n.gain;
        // let it play
        T-length::samp => now;
    }
    
    // tune the fundamental resonance
    fun float tune( float pitch )
    {
        // computes further pitch tuning for higher pitches
        pitch - 43 => float diff;
        0 => float adjust;
        if( diff > 0 ) diff * .0125 => adjust;
        // compute length
        computeDelay( Std.mtof(pitch+adjust) ) => float length;
        // set the delay
        length::samp => delay.delay;
        //return
        return length;
    }
    
    // set feedback attenuation
    fun float feedback( float att )
    {
        // sanity check
        if( att >= 1 || att < 0 )
        {
            <<< "set feedback value between 0 and 1 (non-inclusive)" >>>;
            return lowpass.gain();
        }

        // set it        
        att => lowpass.gain;
        // return
        return att;
    }
    
    // compute delay from frequency
    fun float computeDelay( float freq )
    {
        // compute delay length from srate and desired freq
        return SRATE / freq;
    }
}