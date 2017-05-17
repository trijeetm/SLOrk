//name: nameless-go.ck
//Nathan james Tindall

// print
<<< "-----------------", "" >>>;
<<< "nameless - v0.0", "" >>>;
<<< "-----------------", "" >>>;
// print channels
<<< "* channels:", dac.channels() >>>;

if (me.arg(0) == "")
{
  <<< "You must specify the name of the server" >>>;
  <<< "- for local mode: \"local\"" >>>;
  <<< "- otherwise: the name of the machine running the server code." >>>;
  me.exit();
}

/******************************************************************** Welcome */

<<< 
"Control Information for Players

 - <SPACE>             to begin / enter world
 - ^v<> keys           to navigate world
 - d                   to rearticulate drone (on your current position)
 - 1-0                 to 'tinkle' (clocked by server)
 - j                   to 'jump' (clocked by server)

It is possible that the state of the world could change while you are on it.
The server may change global parameters and notify clients immediately.

By moving to a new cell, you will generate a tone. The envelope of the tone is
tuned by the server. Some envelopes will tend towards more or less movement.

 GESTURES
 - RAIN:     everyone drift downwards
 - ARP:      everyone drift to the right
 - TINKLE:   numbers 1-0 control number of tinkles (can strike successively)
 - JUMP:     percussive effect
 - DRIFT:    find a place sonically pleasing
"
>>>;


/******************************************************************** Globals */

//instantiated by first/subsequent server message
int id;

//global parameter for controlling when client should begin entering sound
//users should press spacebar to 'enter' the grid
int hasEntered;

//if nonzero, server has indicated it is safe to begin.
int canStart;

//r g b MIDI values
int pitch;

int h;
int s;
int v;

//rate limit shreds to prevent clipping
3 => int NUM_TINKLERS_ALLOWED;
0 => int numTinklers;

6 => int NUM_DRONES_ALLOWED;
0 => int numDrones;

//init to something reasonable
20000 => int attackMs;
0     => int decayMs;
1     => float sustainGain;
10000 => int releaseMs;

/*
0.1   => float coolGain;
0     => float warmGain;
*/

Event playerMoved;
Event stateChange;
Event clock;

// create our OSC receiver
OscRecv recv;
// use port 6449
6449 => recv.port;
// start listening (launch thread)
recv.listen();
<<< "OscRecv: listening on 6449" >>>;

// osc handle for server
OscSend xmit;
// server listening port
6451 => int port;

me.arg(0) => string host;
if ((host == "l") || (host == "local")) {
  "localhost" => host;
}

// aim the transmitter at port
xmit.setHost ( host, port );

/************************************************************** SOUND GLOBALS */

Gain globalG => NRev r => dac;
//LPF globalLPF => Gain globalG => NRev r => dac;
// globalLPF.freq(1000);
r.mix(0.1);
globalG.gain(0.8);

Gain redGain, blueGain, greenGain, whiteGain;
0.5 => redGain.gain => blueGain.gain => greenGain.gain;
0.2 => whiteGain.gain;

//tuned by knob from OSC by master
1 => float tinkleGainMultiplier;

redGain => globalG;
blueGain => globalG;
greenGain => globalG;
whiteGain => globalG;

/******************************************************************** Network */

recv.event( "/slork/synch/clock, i i" ) @=> OscEvent ce;

fun void netinit()
{
  //wait for one valid clock to get identifier
  ce => now;

  if (canStart == 0) <<< "[STARTUP INFO] <- CLOCK RECEIVED" >>>;

  if (ce.nextMsg() != 0)
  {
    ce.getInt() => id;
    ce.getInt() => canStart;
    <<< "Identifier is:", id >>>;
  }
}

// receiver
fun void network()
{
  // create an address in the receiver, store in new variable
  //id pitch r g b a d s r
  recv.event( "/slork/synch/synth, i i i i i s i i f i" ) @=> OscEvent oe;

  // count
  0 => int count;

  // infinite event loop
  while ( true )
  {
      // wait for event to arrive
      oe => now;

      // count
      if( count < 5 ) count++;
      if( count < 4 ) <<< ".", "" >>>;
      else if( count == 4 ) <<< "network ready...", "" >>>;

      // grab the next message from the queue. 
      while( oe.nextMsg() != 0 )
      {

        pitch => int old_pitch;

        // get gain
        oe.getInt() => id;
        oe.getInt() => pitch;

        if ((pitch != old_pitch) && (hasEntered)) {
          spork ~drone();
        }

        oe.getInt() => h;
        oe.getInt() => s;
        oe.getInt() => v;

        <<< pitch, h,s,v >>>;

        <<< oe.getString() >>>;
        <<< "[INFO] a:", attackMs, "d:", decayMs, "s:", sustainGain, 
                   "r:", releaseMs, "tink:", numTinklers, "drn:", numDrones >>>;

        oe.getInt()   => attackMs;
        oe.getInt()   => decayMs;
        oe.getFloat() => sustainGain;
        oe.getInt()   => releaseMs;

        //signal that global state change has occured
        stateChange.broadcast();
      }
  }
}

/*************************************************************** TRANSMISSION */

fun void xmitHeartbeat()
{
  while (true)
  {

    if (canStart == 0) <<< "[STARTUP INFO] -> SENDING HEARTBEAT" >>>;
    xmit.startMsg( "/slork/synch/heartbeat", "i");
    id => xmit.addInt;

    100::ms => now;
  }
}


fun void xmitMove(int deltaX, int deltaY)
{
  // a message is kicked as soon as it is complete 
  // - type string is satisfied and bundles are closed
  xmit.startMsg("/slork/synch/move", "i i i");
  id => xmit.addInt;
  deltaX => xmit.addInt;
  deltaY => xmit.addInt;

  playerMoved.broadcast();
}

fun void xmitAction(int actionId)
{
  xmit.startMsg( "/slork/synch/action", "i i i");
  id => xmit.addInt;
  actionId => xmit.addInt;
  -1 => xmit.addInt;
}

// overloaded to accomodate actionParam
fun void xmitAction(int actionId, int actionParam)
{
  xmit.startMsg( "/slork/synch/action", "i i i");
  id => xmit.addInt;
  actionId => xmit.addInt;
  actionParam => xmit.addInt;
}

fun void client()
{

  // the device number to open
  0 => int deviceNum;

  // instantiate a HidIn object
  HidIn hi;
  // structure to hold HID messages
  HidMsg msg;

  // open keyboard
  if( !hi.openKeyboard( deviceNum ) ) me.exit();
  // successful! print name of device
  <<< "keyboard '", hi.name(), "' ready" >>>;

  //wait for server to activate
  while (canStart == 0)
  {
    100::ms => now;
  }

  <<< "[!] SERVER HAS VERIFIED THAT ALL NODES ARE UP!" >>>;

  // infinite event loop
  while( true )
  {
    // wait on event
    hi => now;

    // get one or more messages
    while( hi.recv( msg ) )
    {
      if (msg.isButtonDown())
      {
        //<<< msg.which >>>;

        if ((msg.which == 44) && (hasEntered == false))
        {
          <<< "YOU HAVE ENTERED THE GRID" >>>;
          true => hasEntered;
          xmitAction(ActionEnum.enter());
          xmitMove(0, 0);
          spork ~drone();
        }

        if (hasEntered == true)
        {
          /********************************************* Player Sound Control */

          //escape, allow nodes to leave
          if (msg.which == 41)
          {
            <<< "YOU HAVE DEPARTED THE GRID. PRESS SPACE TO RE-ENTER" >>>;
            false => hasEntered; //reset to allow spacebar for reentry
            xmitMove(0,0);
          }

          //d, rearticulate drone
          /*
          if (msg.which == 7) 
          {
            spork ~drone();
          }
          */

          //j, send jump
          if (msg.which == 13)
          {
            xmitAction(ActionEnum.jump());
            spork ~jumpSound();
          }

          //number pad, send tinkle 0 - 9
          if (msg.which >= 30 && msg.which <= 39)
          {
            xmitAction(ActionEnum.tinkle(), (msg.which - 29));
            spork ~tinkleSound(msg.which - 29);
          }

          /************************************************ ARROW KEY CONTROL */
          //up
          if (msg.which == 82) xmitMove(1, 0);
          //down
          if (msg.which == 81) xmitMove(-1, 0);
          //left
          if (msg.which == 80) xmitMove(0, -1);
          //right
          if (msg.which == 79) xmitMove(0, 1);
        }
      }
    }
  }
}

/********************************************************************** Synch */

fun void stateMonitor()
{
  while (true)
  {
    //the global variables have shifted, update global warmness settings
    stateChange => now;
    // adjustLPF();
    adjustOsc();
  }
}

fun void clockMonitor()
{
  //id, canstart

  while (true)
  {  
      // wait for event to arrive
      ce => now;

      if (ce.nextMsg() != 0)
      {
        ce.getInt() => id;
        ce.getInt() => canStart;
        clock.broadcast();

      }
  }
}

fun void bassMonitor()
{
  recv.event( "/slork/synch/bass, i") @=> OscEvent be;

  while (true)
  {
    be => now;

    if (be.nextMsg() != 0)
    {
      be.getInt() => int note;
      spork ~bass(note);
    }
  }
}

fun void knobMonitor()
{
  recv.event( "/slork/synch/knob, i i") @=> OscEvent ke;

  while (true)
  {
    ke => now;

    if (ke.nextMsg() != 0)
    {
      ke.getInt() => int which;
      ke.getInt() => int value;

      //volume
      if (which == 1)
      {
        (value $ float) / 100 => globalG.gain;
      }

      if (which == 2)
      {
        (value $ float) / 10 => tinkleGainMultiplier;
      }

      if (which == 5)
      {
        (value $ float) / 100 => r.mix;
      }

     // tinkleGain.gain();

      //<<< "KNOB IN FLUX", r.mix(), globalG.gain() >>>;
    }
  }
}

/*********************************************************** SOUND PRODUCTION */

fun void adjustOsc() {
  (h $ float ) / 120 => float oscBalance;
  if (oscBalance <= 1) 
  {
    1 - oscBalance => redGain.gain;
    oscBalance     => greenGain.gain;
    0              => blueGain.gain;
  } else if (oscBalance <= 2) 
  {
    oscBalance - 1 => oscBalance;

    1 - oscBalance => greenGain.gain;
    oscBalance     => blueGain.gain;
    0              => redGain.gain;
  } else 
  {
    //between 2 and 3
    oscBalance - 2 => oscBalance;

    1 - oscBalance => blueGain.gain;
    oscBalance     => redGain.gain;
    0              => greenGain.gain;
  }

  s $ float / 100 => float amountSat;

  redGain.gain()   * amountSat * amountSat => redGain.gain;
  blueGain.gain()  * amountSat * amountSat => blueGain.gain;
  greenGain.gain() * amountSat * amountSat => greenGain.gain;

  1 - amountSat => whiteGain.gain;

  //<<< whiteGain.gain(), redGain.gain(), blueGain.gain(), greenGain.gain() >>>;
}

/*
fun void adjustLPF()
{
  //wolfram alpha query
  //(300, 4000),(0,12000),(60, 8000),(120,3000),(180,1200),(235,525), (270,1200), (360, 12000) function

   0.000886329*h*h*h -0.131224*h*h -67.811*h +12057.1 => globalLPF.freq;
}
*/

fun void jumpSound() {
  ModalBar inst => LPF lpf => NRev rev => globalG;

  Sample kick;
  kick.init("Kick7.wav");
  kick.getBuff() => rev;

  lpf.freq(2000);
  0.05 => rev.mix;

  clock => now;

  kick.playWithJitter(0.3, 1);

  12 => int offset;
  //if (pitch - offset < 36) 0 => offset;
  Std.mtof(pitch - offset) => inst.freq;
  inst.noteOn(1);

  24 => offset;

  40::ms => now;
  //if (pitch - offset < 24) 0 => offset;
  Std.mtof(pitch - offset) => inst.freq;
  inst.noteOn(1);

  0 => offset;

  40::ms => now;
  Std.mtof(pitch - offset) => inst.freq;
  inst.noteOn(1);

  5::second => now;
}

fun void tinkleSound(int amount)
{
  if (numTinklers + 1 > NUM_TINKLERS_ALLOWED) return;
  numTinklers++;

  //blue patch
  Rhodey blueTinkler => HPF blueTinklerHPF;
  blueTinklerHPF => Gain blueTinklerGain => blueGain;
  blueTinklerHPF.freq(8000);

  //red patch
  ModalBar redTinkler => Gain redTinklerGain => redGain;
  redTinkler.stickHardness(0);
  redTinkler.controlChange(16, 2);

  //green patch
  Wurley greenTinkler => HPF greenTinklerHPF;
  greenTinklerHPF => Gain greenTinklerGain => greenGain;
  greenTinklerHPF.freq(4000);

  //ramp gain
  tinkleGainMultiplier * 1 => blueTinklerGain.gain => redTinklerGain.gain;
  tinkleGainMultiplier * 0.25 => greenTinkler.gain;

  //constrain pitch
  pitch => int realpitch;
  while (realpitch < 60 || realpitch > 80)
  {
    if (realpitch < 60) realpitch + 12 => realpitch;
    if (realpitch > 80) realpitch - 36 => realpitch;
  }

  //set pitch
  Std.mtof(realpitch) => blueTinkler.freq => redTinkler.freq => greenTinkler.freq;

  SinOsc lfo => blackhole;
  lfo.freq(0.1);

  //amount bounded between 0 and 9
  for (0 => int i; i < amount; i++)
  {
    //randomize rhythm
    for (int j; j < Math.random2(1,2); j++) clock => now;

   // clock => now; //sync
    blueTinkler.noteOn(lfo.last() + 1);
    greenTinkler.noteOn(lfo.last() + 1);
    redTinkler.noteOn((lfo.last() + 1) / 2);

    clock => now;

    redTinkler.noteOff(1);
    greenTinkler.noteOff(1);
    blueTinkler.noteOff(1);

  }

  //let die
  clock => now;

  numTinklers--;
}

fun void drone()
{
  //rate limit
  if (numDrones + 1 > NUM_DRONES_ALLOWED) return;
  numDrones++;

  ADSR redEnv;
  ADSR blueEnv;
  ADSR greenEnv;
  ADSR whiteEnv;

  redEnv => redGain;
  blueEnv => blueGain;
  greenEnv => greenGain;
  whiteEnv => whiteGain;
  
  //* warm osc */
  BeeThree redOsc;
  redOsc.lfoSpeed(1);
  redOsc.lfoDepth(0.01);
  redOsc.controlOne(0);
  LPF redLPF;
  12000 => redLPF.freq;
  redOsc => redLPF => redEnv;

  // blue osc
  Clarinet blueOsc;
  Math.random2f(0.8, 0.9) => float p;
  p => blueOsc.pressure;
  spork ~modBlueOscVib(blueOsc);
  LPF blueLPF;
  1000 => blueLPF.freq;
  blueOsc => blueLPF => blueEnv;

  // green osc
  HevyMetl greenOsc;
  greenOsc => greenEnv;

  // white osc
  Noise whiteOsc => TwoPole z => whiteEnv;
  1 => z.norm;
  0.995 => z.radius;

  /* Pitch selection */
  Std.mtof(pitch) => redOsc.freq;
  Std.mtof(pitch) / 2 => blueOsc.freq;
  Std.mtof(pitch) => greenOsc.freq;
  Std.mtof(pitch) => z.freq;
  spork ~modWhiteOscFreq(z);

  /* ADSR Tuning (controlled by server) */

  //ephemeral, have to cache
  releaseMs::ms => dur releaseTime;

  redEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);
  blueEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);
  greenEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);
  whiteEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);

    /* Patch */
  1 => redOsc.noteOn;
  1 => blueOsc.noteOn;
  1 => greenOsc.noteOn;

  //sync!
  clock => now;

  redEnv.keyOn();
  blueEnv.keyOn();
  greenEnv.keyOn();
  whiteEnv.keyOn();
  playerMoved => now;
  redEnv.keyOff();
  greenEnv.keyOff();
  blueEnv.keyOff();
  whiteEnv.keyOff();

  //release
  releaseTime => now;

  1 => redOsc.noteOff;
  1 => blueOsc.noteOff;
  1 => greenOsc.noteOff;

  numDrones--;
}

/* modulators */
fun void modBlueOscVib(Clarinet @osc) {
  SinOsc lfo => blackhole;
  0.5 => lfo.freq;

  // does child die when parent die?
  // existentialism
  while (true) {
    (lfo.last() + 1) / 10.0 + 0.1 => osc.vibratoGain;
    1::samp => now;
  }
}

fun void modWhiteOscFreq(TwoPole @ filter)
{
  SinOsc lfo => blackhole;
  0.1 => lfo.freq;

  filter.freq() => float freq;
  while (true) {
    freq * (1 + lfo.last() / 100.0) => filter.freq;
    1::samp => now;
  }

}

fun void slewLPFcutoff(LPF @ lpf)
{
   lpf.freq() => float start;
   8000 => float goal;

   while (lpf.freq() < goal)
   {
    lpf.freq() * 1.03 => lpf.freq;
    100::ms => now;
   }

   while (lpf.freq() > start )
   {
    lpf.freq() / 1.03 => lpf.freq;
    100::ms => now;
   }


}

fun void bass(int note)
{
  <<< "BASS SPORKED BY SERVER... DO NOT BE ALARMED" >>>;
  ADSR env => globalG;

  SawOsc warm => LPF l => env;
  SinOsc cool => env;
  BlitSquare green => env;
  green.harmonics(4);

  l.freq(1000);
  Std.mtof(note) => warm.freq => cool.freq => green.freq;
  0.16 => warm.gain => cool.gain => green.gain; //tone it down

  if (HSV.isWarm(h)) 
  {
    0 => cool.gain;
    0 => green.gain;
  }
  else if (HSV.isGreen(h))
  {
    0 => warm.gain;
    0 => cool.gain;
  }
  else //blue
  {
    0 => green.gain;
    0 => warm.gain;
  }

  if (HSV.isWarm(h)) {
    spork ~slewLPFcutoff(l);
  }

  env.set(6::second, 3::second, 0.5, 3::second);

  env.keyOn();
  10::second => now; 
  env.keyOff();

  env.releaseTime() => now;
}


/******************************************************************** CONTROL */

netinit();
spork ~clockMonitor();
spork ~bassMonitor();
spork ~knobMonitor();
spork ~stateMonitor();
spork ~network();
spork ~xmitHeartbeat();
spork ~client();

recv.event( "/slork/kill") @=> OscEvent killWaiter;
killWaiter => now;
<<< "You have been killed by the server." >>>;
me.exit();
