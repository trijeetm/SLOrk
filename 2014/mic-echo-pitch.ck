// name: karptrak.ck
// desc: gametrak + stifkarp example
//
// author: Ge Wang (ge@ccrma.stanford.edu)
// date: spring 2014
//
// note: this is currently configured for 6 channels;
//       may need to do some wranglin' to make it work on stereo

// channel
2 => int CHANNELS;
// offset
0 => int CHAN_OFFSET;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;


// HID objects
Hid trak;
HidMsg msg;

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

<<< "joystick '" + trak.name() + "' ready", "" >>>;

// data structure for gametrak
class GameTrak
{
   // timestamps
   time lastTime;
   time currTime;
   
   // previous axis data
   float lastAxis[6];
   // current axis data
   float axis[6];
}

// gametrack
GameTrak gt;

// adc / dac
// feedforward
adc => Gain g => PitShift p => Gain master => dac;
// feedback
g => Gain feedback => DelayL delay => g;

1 => master.gain;

// duration
150::ms => dur T;
// counter
int n;

// spork control
spork ~ gametrak();
spork ~ voice();


// main loop
while( true )
{
   // wait
   135::ms => now;

}

// print
fun void voice()
{

  0.5 => g.gain;
  // set feedback
  0.5::second => delay.max => delay.delay;
  .5 => feedback.gain;
  // set effects mix
  .75 => delay.gain;
   // time loop
   while( true )
   {   
         
      0.5::second => now;

   }
}

// map
fun void map()
{
  //<<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2], gt.axis[3],gt.axis[4],gt.axis[5] >>>;
  <<< "pitch shift:", (gt.axis[5] * 6) >>>;
   (gt.axis[5] * 6) => p.shift;
      0.5::second => now;
   
  <<< "y: ", gt.axis[4] >>>;
  if (gt.axis[4] > 0) {
    <<< "master: ", 1.25 - gt.axis[4] >>>;
    1.25 - gt.axis[4] => master.gain;
  }
  else if (gt.axis[4] < -0.7) {
    float val;
    0.5 + gt.axis[4] => val;
    <<< "master: ", val >>>;
    val => master.gain;
  }
}

// gametrack handling
fun void gametrak()
{
   while( true )
   {
      // wait on HidIn as event
      trak => now;

      // messages received
      while( trak.recv( msg ) ) {
         // joystick axis motion
         if( msg.isAxisMotion() )
         {            
             // check which
             if( msg.which >= 0 && msg.which < 6 )
             {
                 // check if fresh
                 if( now > gt.currTime )
                 {
                     // time stamp
                     gt.currTime => gt.lastTime;
                     // set
                     now => gt.currTime;
                 }
                 // save last
                 gt.axis[msg.which] => gt.lastAxis[msg.which];
                 // the z axes map to [0,1], others map to [-1,1]
                 if( msg.which != 2 && msg.which != 5 )
                 { msg.axisPosition => gt.axis[msg.which]; }
                 else
                 { 1 - ((msg.axisPosition + 1) / 2) => gt.axis[msg.which]; }
             }
         }
         
         // joystick button down
         else if( msg.isButtonDown() )
         {
             <<< "joystick button", msg.which, "down" >>>;

         }
         
         // joystick button up
         else if( msg.isButtonUp() )
         {
             <<< "joystick button", msg.which, "up" >>>;
         }
      }

     map();

   }
}