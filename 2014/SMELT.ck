/*---------------------------------------------------------------------------
    S.M.E.L.T. : Small Musically Expressive Laptop Toolkit

    Copyright (c) 2007 Rebecca Fiebrink and Ge Wang.  All rights reserved.
      http://smelt.cs.princeton.edu/
      http://soundlab.cs.princeton.edu/

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
    U.S.A.
-----------------------------------------------------------------------------*/

//-----------------------------------------------------------------------------
// name: breath-flute.ck
// desc: mic-based, do-it-yourself threshold detector
//
// authors: Rebecca Fiebrink and Ge Wang
// based on Matt Hoffman
//
// to run (in command line chuck):
//     %> chuck breath-flute.ck
//
// to run (in miniAudicle):
//     (make sure VM is started, add the thing)
//-----------------------------------------------------------------------------

// patch to Gain (workaround for adc.last() not working)
// and then to blackhole (the silent sample sucker)
adc => Gain d => blackhole;

// sound output
SinOsc s => ADSR e => JCRev r => dac;
// env
e.set( 10::ms, 5::ms, .5, 20::ms );
// reverb mix
.1 => r.mix;
// close the env
e.keyOff();
// sin freq
600 => s.freq;

// more or less arbitrary threshold
2.0 => float zcthresh;
// whether input is above threshold
0 => int state;
// the previous input
0 => float prevSamp;
// pause duration
50::ms => dur pauseDur;
// number of samples until key off
0 => int count;

// infinite time loop
while(true)
{
    // if the threshold has been crossed
    if( ( prevSamp - zcthresh ) * ( d.last() - zcthresh ) < 0 )
    {
        // rising above threshold
        if( !state )
        {
            1 => state;
            e.keyOn();
            <<< "RISING ABOVE THRESHOLD", "time:", now/second >>>;
            4000 => count;
        }
        // check for going below threshold
        else if( state )
        {
            0 => state;
            <<< "FALLING BELOW THRESHOLD", "time:", now/second >>>;
            if( count ) 1 => count;
        }
    }
    
    // keep count
    if( count )
    {
        if( !(--count ) )
        {
            e.keyOff();
        }
    }

    // remember this
    d.last() => prevSamp;   

    // brute force sample-at-a-time processing
    1::samp => now;
}
