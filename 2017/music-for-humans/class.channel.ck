//-----------------------------------------------------------------------------
// name: channel.ck
// desc: a multichannel system for brewery
//
// authors: Trijeet Mukhopadhyay (trijeetm@ccrma.stanford.edu)
// date: winter 2016
//       Stanford University
//-----------------------------------------------------------------------------

public class Channel extends Chubgraph {
    Pan2 pan;
    Pan2 dist;
    Gain master;
    NRev rev;
    LPF lpf;

    0 => rev.mix;
    0 => pan.pan;
    0 => dist.pan;
    20000 => lpf.freq;

    int id;

    inlet => rev => master => pan => dist => outlet;

    // ---
    // osc
    // ---

    // name
    "localhost" => string hostname;
    4242 => int port;

    // send object
    OscSend xmit;

    // aim the transmitter
    xmit.setHost( hostname, port );

    // outlet is not stereo, so instead on connection outlet to dac, connect 
    // Channel.L and Channel.R as shown below
    // Channel.L() => dac.left; Channel.R() => dac.right;
    fun UGen L() { return pan.left; }
    fun UGen R() { return pan.right; }
    fun UGen F() { return dist.left; }
    fun UGen B() { return dist.right; }

    fun void addLPF() {
        inlet =< rev;
        inlet => lpf => rev;
    }

    fun void setup(int _id) {
        _id => id;
        L() => dac.left;
        R() => dac.right;
    }

    fun void multichannelSetup(int _id) {
        _id => id;
        // 0    1
        // 
        // 6    7
        L() => dac.chan(0);
        L() => dac.chan(6);
        R() => dac.chan(1);
        R() => dac.chan(7);

        F() => dac.chan(0);
        F() => dac.chan(1);
        B() => dac.chan(6);
        B() => dac.chan(7);
    }

    // range (0, ?)
    fun void setMaster(float g) {
        g => master.gain;

        xmit.startMsg( "/granulizer/prop/gain", "i f" );
        id => xmit.addInt;
        g => xmit.addFloat;
    }

    // range (-1, 1)
    fun void setPan(float p) {
        if (p > 1)
            1 => p;
        if (p < -1)
            -1 => p;
        p => pan.pan;

        xmit.startMsg( "/granulizer/prop/pan", "i f" );
        id => xmit.addInt;
        p => xmit.addFloat;
    }

    // range (-1, 1)
    fun void setDist(float p) {
        if (p > 1)
            1 => p;
        if (p < -1)
            -1 => p;
        p => dist.pan;

        xmit.startMsg( "/granulizer/prop/dist", "i f" );
        id => xmit.addInt;
        p => xmit.addFloat;
    }

    fun void setRev(float mix) {
        mix => rev.mix;

        xmit.startMsg( "/granulizer/prop/rev", "i f" );
        id => xmit.addInt;
        Math.pow(mix, 0.5) => xmit.addFloat;
    }

    fun void interpPan(float end, dur duration) {
        Interpolator interpPan;
        interpPan.setup(pan.pan(), end, duration);
        interpPan.interpolate();
        while (interpPan.getCurrent() != interpPan.end) {
            setPan(interpPan.getCurrent());
            interpPan.delta => now;
        }
        setPan(interpPan.getCurrent());
    }

    fun void interpPan(float start, float end, dur duration) {
        Interpolator interpPan;
        interpPan.setup(start, end, duration);
        interpPan.interpolate();
        while (interpPan.getCurrent() != interpPan.end) {
            setPan(interpPan.getCurrent());
            interpPan.delta => now;
        }
        setPan(interpPan.getCurrent());
    }

    fun void interpMaster(float end, dur duration) {
        Interpolator iGain;
        iGain.setup(master.gain(), end, duration);
        iGain.interpolate();
        while (iGain.getCurrent() != iGain.end) {
            setMaster(iGain.getCurrent());
            iGain.delta => now;
        }
        setMaster(iGain.getCurrent());
    }

    fun void interpMaster(float start, float end, dur duration) {
        start => master.gain;
        Interpolator iGain;
        iGain.setup(start, end, duration);
        iGain.interpolate();
        while (iGain.getCurrent() != iGain.end) {
            setMaster(iGain.getCurrent());
            iGain.delta => now;
        }
        setMaster(iGain.getCurrent());
    }

    fun void interpRev(float start, float end, dur duration) {
        Interpolator iRev;
        iRev.setup(start, end, duration);
        iRev.interpolate();
        while (iRev.getCurrent() != iRev.end) {
            iRev.getCurrent() => rev.mix;
            iRev.delta => now;
        }
        iRev.getCurrent() => rev.mix;
    }

    fun void setLPF(float freq, float Q) {
        freq => lpf.freq;
        Q => lpf.Q;
    }

    fun void interpLPFFreq(float start, float end, dur duration) {
        Interpolator interp;
        interp.setup(start, end, duration);
        interp.interpolate();
        while (interp.getCurrent() != interp.end) {
            interp.getCurrent() => lpf.freq;
            interp.delta => now;
        }
        interp.getCurrent() => lpf.freq;
    }

    fun void interpLPFQ(float start, float end, dur duration) {
        Interpolator interp;
        interp.setup(start, end, duration);
        interp.interpolate();
        while (interp.getCurrent() != interp.end) {
            interp.getCurrent() => lpf.Q;
            interp.delta => now;
        }
        interp.getCurrent() => lpf.Q;
    }
}