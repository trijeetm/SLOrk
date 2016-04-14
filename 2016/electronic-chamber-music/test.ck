//-----------------------------------------------------------------------------
// name: LiSa
// desc: Live sampling utilities for ChucK
//
// author: Dan Trueman, 2007
//
// to run (in command line chuck):
//     %> chuck LiSa_readme.ck
//-----------------------------------------------------------------------------

/*

These three example files demonstrate a couple ways to approach granular sampling
with ChucK and LiSa. All are modeled after the munger~ from PeRColate. One of the
cool things about doing this in ChucK is that there is a lot more ready flexibility
in designing grain playback patterns; rolling one's own idiosyncratic munger is 
a lot easier. 

Example 1 (below) is simple, but will feature some clicking due to playing back
over the record-point discontinuity.

*/

//-----------------------------------------------------------------------------
SinOsc s => LiSa l => NRev r => dac;
0.2 => r.mix;
s=>dac;
//freq params
s.freq(440.);
s.gain(0.2);
SinOsc freqmod => blackhole;
freqmod.freq(0.1);


//LiSa params
l.duration(1::second);
//set it recording constantly; loop records by default
l.record(1);
l.gain(0.1);

now + 1000::ms => time later;
while(now<later) {
   
   freqmod.last() * 500. + 200. => s.freq;
   10::ms => now;
}

l.record(0);
s.gain(0.);
l.recRamp(20::ms);

l.maxVoices(30);
//<<<l.maxvoices()>>>;

//this arrangment will create some clicks because of discontinuities from
//the loop recording. to fix, need to make a rotating buffer approach.
//see the next two example files....
while (true) {
 
   Std.rand2f(1.5, 2.0) => float newrate;
   Std.rand2f(250, 750) * 1::ms => dur newdur;
 
   spork ~ getgrain(newdur, 20::ms, 20::ms, newrate);
 
   100::ms => now;
 
}


fun void getgrain(dur grainlen, dur rampup, dur rampdown, float rate)
{
   l.getVoice() => int newvoice;
   //<<<newvoice>>>;
   
   if(newvoice > -1) {
     l.rate(newvoice, rate);
     //l.playpos(newvoice, Std.rand2f(0., 1000.) * 1::ms);
     l.playPos(newvoice, 20::ms);
     //<<<l.playpos(newvoice)>>>;
     l.rampUp(newvoice, rampup);
     (grainlen - (rampup + rampdown)) => now;
     l.rampDown(newvoice, rampdown);
     rampdown => now;
   }
 
 }