//-----------------------------------------------------------------------------
// name: ks-chord.ck
// desc: karplus strong comb filter bank
//
// authors: Madeline Huberth (mhuberth@ccrma.stanford.edu)
//          Ge Wang (ge@ccrma.stanford.edu)
// date: summer 2014
//       Stanford Center @ Peking University
//-----------------------------------------------------------------------------

// chord class for KS
public class KSChord extends Chubgraph
{
    // array of KS objects    
    KS chordArray[4];
    
    // connect to inlet and outlet of chubgraph
    for( int i; i < chordArray.size(); i++ ) {
        inlet => chordArray[i] => outlet;
    }

    feedback(0);

    // set feedback    
    fun float feedback( float att )
    {
        // sanith check
        if( att >= 1 || att < 0 )
        {
            <<< "set feedback value between 0 and 1 (non-inclusive)" >>>;
            return att;
        }
        
        // set feedback on each element
        for( int i; i < chordArray.size(); i++ )
        {
            att => chordArray[i].feedback;
        }

        return att;
    }
    
    // tune 4 objects
    fun float tune( float pitch1, float pitch2, float pitch3, float pitch4 )
    {
        pitch1 => chordArray[0].tune;
        pitch2 => chordArray[1].tune;
        pitch3 => chordArray[2].tune;
        pitch4 => chordArray[3].tune;
    }

    fun void interpolateFeedback(float start, float end, dur duration) {
        Interpolator interp;
        interp.setup(start, end, duration);
        interp.interpolate();
        while (interp.getCurrent() != interp.end) {
            feedback(interp.getCurrent());
            interp.delta => now;
        }
        feedback(interp.getCurrent());
    }

    fun void interpolateTune(float pitch1, float pitch2, float pitch3, float pitch4, float offset, dur duration) {
        Interpolator interp;
        interp.setup(0, offset, duration);
        interp.interpolate();
        while (interp.getCurrent() != interp.end) {
            tune(pitch1 + interp.getCurrent(), pitch2 + interp.getCurrent(), pitch3 + interp.getCurrent(), pitch4 + interp.getCurrent());
            interp.delta => now;
        }
        tune(pitch1 + interp.getCurrent(), pitch2 + interp.getCurrent(), pitch3 + interp.getCurrent(), pitch4 + interp.getCurrent());
    }
}

// 7th
// 4 7 11