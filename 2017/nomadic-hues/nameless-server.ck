// ASNI COLORS
"\033[0m" => string RESET;
"\033[1;32m" => string GREEN;
"\033[0;36m" => string CYAN;
"\033[1;31m" => string RED;
"\033[1;33m" => string YELLOW;


//init keyboard
<<< GREEN,"running nameless-server.ck",RESET >>>;

// value of clock
100::ms => dur T;

// dimensions
10 => int height;
10 => int width;

//if nonzero, server has indicated it is safe to begin.
0 => int pieceIsActive;

// movement number tracker (for gfx)
0 => int movementNumber;

100 => int globalSaturation;

[10000, 5,    400,  50 ] @=> int attackMs[];
[10000, 1000, 1000, 100 ] @=> int decayMs[];
[0.05 , 0.05, 0.05, 0.05] @=> float sustainGain[];
[5000 , 100 , 1000, 100 ] @=> int releaseMs[];

/********************************************************************* Scales */
11 => int HIRAJOSHI;
int hirajoshi[width];

19 => int PENTATONIC;
int pentatonic[width];

4 => int AMINOR; //sus2
int aminor[width];

7 => int DMINOR;
int dminor[width];

28 => int YO;
int yo[width];

29 => int ASCENDING;
int ascending[width];

fun void initscales()
{
  60 => int C;
  61 => int Db;
  62 => int D;
  63 => int Eb;
  64 => int E;
  65 => int F;
  66 => int Gb;
  67 => int G;
  68 => int Ab;
  69 => int A;
  70 => int Bb;
  71 => int B;

  [C-24, E-24, Gb-24, G-24, B-24, C-12, E-12, Gb-12, G-12,
         E-12, C-12, B-24] @=> hirajoshi;

  [C-24, D-24, E-24, G-24, A-24, C-12, D-12, E-12, G-12,
         E-12, D-12, C-24] @=> pentatonic;

  [A-36, C-24, E-24, A-24, C-12, D-12, E-12, A-12, E-12,
         C-12, B-24, A-24] @=> aminor;

  [D-36, A-36, C-24, D-24, F-24, A-12, D-12, A-12, F-12,
         D-12, A-24, D-24] @=> dminor;

  [D-24, E-24, G-24, A-24, C-12, D-12, E-12, G-12, E-12,
         D-12, B-24, A-24] @=> yo;

  [G-36, A-36, B-36, D-24, E-24, F-24, G-24, A-24, B-24,
         D-12, E-12, F-12, G-12] @=> ascending;
}

/************************************************* Global Grid Initialization */

16 => int MAX_PLAYERS;

//zero initialized, heap memory
new GridCell[height*width] @=> GridCell @ grid[];

//The location of each target
PlayerState positions[MAX_PLAYERS];

class PlayerState {
    int x;
    int y;
    int whichEnv; //which index of the global envelope arrays to look in to
                  //send envelopes to clients
    HSV color;
    time lastMsg;
    int serverReceivedAtLeastOneMessage;
}

/***************************************************** Network Initialization */
// graphics OSC object
OscSend graphicsXmit;
// port
4242 => int graphicsPort;

// aim the transmitter at port
graphicsXmit.setHost("localhost", graphicsPort);

//create Xmitter
Xmitter xmit;

// create our OSC receiver
OscRecv recv;
// use port 6449
6451 => recv.port;

/************************************************************************ MIDI */

0 => int device;
// the midi event
MidiIn min;
// the message for retrieving data
MidiMsg msg;

// open the device
if( !min.open( device ) ) me.exit();

// print out device that was opened
<<< YELLOW, "MIDI device:", min.num(), " -> ", min.name(), RESET >>>;


/***************************************************************** HEARTBEATS */

recv.event( "/slork/synch/heartbeat, i" ) @=> OscEvent he;

//wait for heartbeats from everyone before beginning anything else
fun void waitForHeartbeats()
{

  int isAlive[xmit.targets()];

  while ( true )
  {
    //alive check
    true => int allAlive;

    <<< "." >>>;
    for (int i; i < isAlive.cap(); i++)
    {
      if (isAlive[i] < 5)
      {
        <<< RED, "Client with id", i, "is not responding.", RESET >>>;
        false => allAlive;
      }
    }

    if (allAlive) break;

    //read the next message
    he => now;

    while (he.nextMsg() != 0)
    {
      he.getInt() => int id;
      isAlive[id]++;
    }
  }

  <<< GREEN, "All clients up...", RESET >>>;
  1 => pieceIsActive;
}


fun void heartbeatMonitor()
{
  while ( true )
  {
    //read the next message
    he => now;

    if (he.nextMsg() != 0)
    {
      he.getInt() => int id;
      now => positions[id].lastMsg;
    }
  }

}

fun void timeout()
{
  500::ms => dur TIMEOUT_THRESH;

  while (true)
  {
    for (int id; id < xmit.targets(); id++)
    {
      //no communication in past THRESHOLD and they are ACTIVE on the grid
      if (positions[id].lastMsg + TIMEOUT_THRESH < now
                         && grid[idToIdx(id)].who[id] != 0)
      {
        spork ~timeoutHandler(id);
      }
    }
    10::ms => now;
  }
}

fun void timeoutHandler(int id)
{
  <<< id, "has timed out" >>>;

  0 => grid[idToIdx(id)].who[id];

  //do graphics update.
  g_hidePlayer(id);
  g_cellFadeOut(id, positions[id].x, positions[id].y, positions[id].whichEnv);
}

/*********************************************************** Driver Functions */

fun int idToIdx(int id)
{
  return positions[id].y*width+positions[id].x;
}

fun void printGridCell(GridCell @ var)
{
  <<< "p:", var.pitch, " o: ", var.isOccupied() >>>;
}

fun void printPlayerState(int id, PlayerState @ pos) {
    <<< "ID: ", id, " at x: ", pos.x, " y: ", pos.y, pos.color.toString() >>>;
}

fun void gridinit(int which) {
  int scale[];

  if (which == HIRAJOSHI)
  {
    hirajoshi @=> scale;
    <<< "Scale: HIRAJOSHI" >>>;
  }

  if (which == PENTATONIC)
  {
    pentatonic @=> scale;
    <<< "Scale: PENTATONIC" >>>;
  }

  if (which == AMINOR)
  {
    aminor @=> scale;
    <<< "Scale: AMINOR" >>>;
  }

  if (which == DMINOR)
  {
    dminor @=> scale;
    <<< "Scale: DMINOR" >>>;
  }

  if (which == YO)
  {
    yo @=> scale;
    <<< "Scale: YO" >>>;
  }

  if (which == ASCENDING)
  {
    ascending @=> scale;
    <<< "Scale: ASCENDING" >>>;
  }

  g_updateWorld(which);

  for( 0 => int y; y < height; y++ )
  {
    for( 0 => int x; x < width; x++ )
    {
      //calculate index
      y*width + x => int idx;
      if (y > height / 2)
      {
        // here, 12 represents one octave, not the number of players - NT 2017
        scale[x] + (height - y) * 12 => grid[idx].pitch;
      }
      else
      {
        scale[x] + y * 12 => grid[idx].pitch;
      }
    }
  }
}

fun void targetinit() {
  for (int i; i < xmit.targets(); i++)
  {
    // Math.random2(0,width - 1) => positions[i].x;
    // Math.random2(0,height - 1) => positions[i].y;
    0 => positions[i].x;
    0 => positions[i].y;

    positions[i].color.getWarm() => positions[i].color.h;
    globalSaturation => positions[i].color.s;
    100 => positions[i].color.v;

    //time automatically zero initialized
  }
}

fun void mutateSaturation(int delta) {
  if (delta < 0)
  {
    globalSaturation - 5 => globalSaturation;
    if (globalSaturation < 0) 0 => globalSaturation;
  } else
  {
    globalSaturation + 5 => globalSaturation;
    if (globalSaturation > 100) 100 => globalSaturation;
  }

  <<< "[!][!][!][!] GLOBAL SATURATION:", globalSaturation >>>;

  for (int i; i < xmit.targets(); i++)
  {
    globalSaturation => positions[i].color.s;
    g_updateColor(i);
  }
}

fun string printGrid(int id, int targetIdx) {

  "----------------------------\n" => string result;
  for( height - 1 => int y; y >= 0; y--)
  {
    for( 0 => int x; x < width; x++ )
    {
      //calculate index
      y*width + x => int idx;

      if (grid[idx].isOccupied())
      {
        if (targetIdx == idx && (grid[idx].who[id] != 0))
        {
          //todo, be smarter about commandline feedback to give clients
          //information about state
          "█  " +=> result;

        } else {
          "o  " +=> result;
        }
      } else {
        ".  " +=> result;
      }
    }
    "\n" +=> result;
  }

  return result;
}

fun void updateClient(int z) {
  positions[z] @=> PlayerState curPlayer;
 // printPlayerState(z, curPlayer);

  // start the message...
  //id midi h s v grid a d s r
  xmit.at(z).startMsg( "/slork/synch/synth", "i i i i i s i i f i" );

  // a message is kicked as soon as it is complete
  // - type string is satisfied and bundles are closed
  z                                            => xmit.at(z).addInt;
  grid[curPlayer.y*width+curPlayer.x].pitch    => xmit.at(z).addInt;
  curPlayer.color.h                            => xmit.at(z).addInt;
  curPlayer.color.s                            => xmit.at(z).addInt;
  curPlayer.color.v                            => xmit.at(z).addInt;

  printGrid(z, curPlayer.y*width+curPlayer.x) => xmit.at(z).addString;


  attackMs[curPlayer.whichEnv]    => xmit.at(z).addInt;
  decayMs[curPlayer.whichEnv]     => xmit.at(z).addInt;
  sustainGain[curPlayer.whichEnv] => xmit.at(z).addFloat;
  releaseMs[curPlayer.whichEnv]   => xmit.at(z).addInt;
}

fun void sendBass(int midiNote) {

  //only send to whoever has a bass
  for (int z; z < xmit.basses().cap(); z++)
  {
    xmit.basses()[z] => int subwoofer_idx;

    //hack to make local work
    if (subwoofer_idx >= 0)
    {
      xmit.at(subwoofer_idx).startMsg( "/slork/synch/bass", "i" );
      midiNote => xmit.at(subwoofer_idx).addInt;
    }

  }
}

fun void sendKnob(int whichKnob, int value)
{
  if (value > 100) 100 => value;

  for (int z; z < xmit.targets(); z++)
  {
    xmit.at(z).startMsg( "/slork/synch/knob", "i i");
    whichKnob => xmit.at(z).addInt;
    value     => xmit.at(z).addInt;
  }
}


fun void updateClients() {
  for( 0 => int z; z < xmit.targets(); z++ )
  {
    updateClient(z); //no need to spork
  }
}

fun void sendClock() {
  while (true)
  {
    for (int z; z < xmit.targets(); z++)
    {
      // a message is kicked as soon as it is complete
      xmit.at(z).startMsg( "/slork/synch/clock", "i i");
      z => xmit.at(z).addInt;

      //if non-zero, indicates to client that piece is active
      pieceIsActive => xmit.at(z).addInt;
    }

    //clock speed tunable by T
    T => now;
  }
}

fun void handleClient() {
  // create an address in the receiver, store in new variable
  //id x y
  recv.event( "/slork/synch/move, i i i" ) @=> OscEvent oe;

  while ( true )
  {
    oe => now;

    while ( oe.nextMsg() != 0 )
    {
      oe.getInt() => int id;
      oe.getInt() => int dY;
      oe.getInt() => int dX;

      //they are leaving the grid, send a fade out message
      if (dY == 0 && dX == 0
                  && grid[idToIdx(id)].who[id] == 1)
      {
        <<< "hiding player" >>>;
        //unset occupied for old position
        0 => grid[idToIdx(id)].who[id];
        g_hidePlayer(id);
        g_cellFadeOut(id, positions[id].x, positions[id].y, positions[id].whichEnv);
        continue;
      }

      //unset occupied for old position
      0 => grid[idToIdx(id)].who[id];

      // If we have seen the player before, fade out the previous grid cell
      // occupied by the player.
      if (positions[id].serverReceivedAtLeastOneMessage != 0) {
        g_cellFadeOut(id, positions[id].x, positions[id].y, positions[id].whichEnv);
      } else {
        1 => positions[id].serverReceivedAtLeastOneMessage;
      }


      0 => int didTeleport;  // to track graphics teleport

      //get x
      positions[id].x + dX => positions[id].x;

      //x bounds
      if (positions[id].x > width - 1) {
        0 => positions[id].x;
        1 => didTeleport;
      }
      if (positions[id].x < 0) {
        width - 1 => positions[id].x;
        1 => didTeleport;
      }

      //get y
      positions[id].y + dY => positions[id].y;

      //y bounds
      if (positions[id].y > height - 1) {
        0 => positions[id].y;
        2 => didTeleport;
      }
      if (positions[id].y < 0) {
        height - 1 => positions[id].y;
        2 => didTeleport;
      }

      //write last communiation time into positions array
      now => positions[id].lastMsg;

      1 => grid[idToIdx(id)].who[id];

      // update player graphics
      if (didTeleport == 0) {
        g_showPlayer(id);
      }
      g_updatePlayer(id, didTeleport);

      // toggle new gridcell to fade in
      g_cellFadeIn(id, positions[id].x, positions[id].y, positions[id].whichEnv);

      // update clients
      updateClients();
    }
  }
}

fun void handleAction() {
  //create an address to store action events
  //id actionID
  recv.event( "/slork/synch/action, i i i") @=> OscEvent acte;

  while (true)
  {
    acte => now;

    while ( acte.nextMsg() != 0)
    {
      acte.getInt() => int id;
      acte.getInt() => int actionId;
      acte.getInt() => int actionParam;

      //if only there were enums
      if (actionId == ActionEnum.jump())
      {
        //update graphics
        //<<< "Jump received!!! from ", id >>>;
        spork ~g_playerJump(id);
      }

      if (actionId == ActionEnum.tinkle())
      {
        //update graphics
        //<<< "Tinkle received!!! from ", id >>>;
        spork ~g_playerTinkle(id, actionParam);
      }

      if (actionId == ActionEnum.enter())
      {
        //update graphics
        <<< "Player ", id + " entered grid!" >>>;
        spork ~g_showPlayer(id);
      }
    }
  }

}

fun void slewIdxColor(int z, int hue)
{
  positions[z].color @=> HSV color;
  hue - color.h       => int hueDelta;

  //complicated math
  if (Math.abs(hueDelta) >= 180)
  {
    if (hueDelta < 0)
    {
      (hueDelta + 360) => hueDelta;
    } else if (hueDelta > 0)
    {
    -(360 - hueDelta) => hueDelta;
    }
  }

  20                  => int numSteps;

  (hueDelta $ float )/ numSteps   => float stepSize;

  //keep accurate sum in sum, but cast down to appropriate hue
  color.h $ float                 => float sum;

  for (int i; i < numSteps; i++)
  {
    sum + stepSize => sum;
    if (sum >= 360) 0 => sum;
    if (sum < 0) 359 => sum;

    //in case step size is small, just end.
    if (sum $ int == color.h) break;

    //cast down
    sum $ int => color.h;

    //let everyone know some slewing has occured!
    spork ~updateClient(z);

    // update graphics with player color
    g_updatePlayer(z);

    //expected time to completion is 10 seconds
    Math.random2(1,1000)::ms => now;
  }

  //make sure we didn't mess up
  hue => color.h;
  updateClient(z);
}


fun void slewColors(int hue) {
  for( 0 => int z; z < xmit.targets(); z++ )
  {
    //calculate index
    if (HSV.isWarm(hue))
    {
      spork ~slewIdxColor(z, HSV.getWarm());
    }
    else if (HSV.isCool(hue))
    {
      spork ~slewIdxColor(z, HSV.getCool());
    }
    else if (HSV.isGreen(hue))
    {
      spork ~slewIdxColor(z, HSV.getGreen());
    }
  }

  20::second => now; //wait
}


/************************************************************************* Graphics */

false => int GRAPHICS_VERBOSE;

fun void g_init() {
  if (GRAPHICS_VERBOSE) <<< "g_init: " + width + " " + height >>>;

  graphicsXmit.startMsg("/nameless/graphics/init", "i i i");
  xmit.targets() => graphicsXmit.addInt;
  width => graphicsXmit.addInt;
  height => graphicsXmit.addInt;
}

fun void g_showPlayer(int id) {
  if (GRAPHICS_VERBOSE) <<< "g_showPlayer:" + id >>>;
  graphicsXmit.startMsg("/nameless/graphics/player/enter", "i");
  id => graphicsXmit.addInt;
}

fun void g_hidePlayer(int id) {
  if (GRAPHICS_VERBOSE)  <<< "g_hidePlayer:" + id >>>;
  graphicsXmit.startMsg("/nameless/graphics/player/exit", "i");
  id => graphicsXmit.addInt;
}

fun void g_updatePlayer(int id) {
  if (GRAPHICS_VERBOSE) <<< "g_updatePlayer:" + id >>>;

  graphicsXmit.startMsg("/nameless/graphics/player/move", "i i i i i i i");
  id => graphicsXmit.addInt;
  positions[id].x => graphicsXmit.addInt;
  positions[id].y => graphicsXmit.addInt;
  positions[id].color.h => graphicsXmit.addInt;
  positions[id].color.s => graphicsXmit.addInt;
  positions[id].color.v => graphicsXmit.addInt;
  0 => graphicsXmit.addInt;
}

fun void g_updatePlayer(int id, int didTeleport) {
  if (GRAPHICS_VERBOSE) <<< "g_updatePlayer:" + id >>>;
  graphicsXmit.startMsg("/nameless/graphics/player/move", "i i i i i i i");
  id => graphicsXmit.addInt;
  positions[id].x => graphicsXmit.addInt;
  positions[id].y => graphicsXmit.addInt;
  positions[id].color.h => graphicsXmit.addInt;
  positions[id].color.s => graphicsXmit.addInt;
  positions[id].color.v => graphicsXmit.addInt;
  didTeleport => graphicsXmit.addInt;
}

fun void g_cellFadeIn(int id, int x, int y, int env) {
  if (GRAPHICS_VERBOSE) <<< "g_cellFadeIn:" + id + " " + x + " " + y + " " + env >>>;

  graphicsXmit.startMsg("/nameless/graphics/cell/fadeIn", "i i i i");

  id                  => graphicsXmit.addInt;
  x                   => graphicsXmit.addInt;
  y                   => graphicsXmit.addInt;
  attackMs[env]       => graphicsXmit.addInt;
}

fun void g_cellFadeOut(int id, int x, int y, int env) {
  if (GRAPHICS_VERBOSE) <<< "g_cellFadeOut:" + id + " " + x + " " + y + " " + env >>>;

  graphicsXmit.startMsg("/nameless/graphics/cell/fadeOut", "i i i i");

  id                  => graphicsXmit.addInt;
  x                   => graphicsXmit.addInt;
  y                   => graphicsXmit.addInt;
  releaseMs[env] * 2  => graphicsXmit.addInt;
}

fun void g_playerTinkle(int id, int tinkles) {
  if (GRAPHICS_VERBOSE)  <<< "g_playerTinkle:" + id + " " + tinkles >>>;

  graphicsXmit.startMsg("/nameless/graphics/player/tinkle", "i i");
  id => graphicsXmit.addInt;
  tinkles => graphicsXmit.addInt;
}

fun void g_playerJump(int id) {
  if (GRAPHICS_VERBOSE)  <<< "g_playerJump:" + id >>>;

  graphicsXmit.startMsg("/nameless/graphics/player/jump", "i");
  id => graphicsXmit.addInt;
}

fun void g_updateColor(int id) {
  if (GRAPHICS_VERBOSE)  <<< "g_updateColor:" + id >>>;

  graphicsXmit.startMsg("/nameless/graphics/player/color", "i i i i i i");
  id => graphicsXmit.addInt;
  positions[id].x => graphicsXmit.addInt;
  positions[id].y => graphicsXmit.addInt;
  positions[id].color.h => graphicsXmit.addInt;
  positions[id].color.s => graphicsXmit.addInt;
  positions[id].color.v => graphicsXmit.addInt;
}

fun void g_updateWorld(int which) {
  int h, s, b;

  if (which == HIRAJOSHI)
  {
    0 => h;
    10 => s;
    100 => b;
  }

  if (which == PENTATONIC)
  {
    0 => h;
    61 => s;
    100 => b;
  }

  if (which == AMINOR)
  {
    50 => h;
    75 => s;
    100 => b;
  }

  if (which == DMINOR)
  {
    180 => h;
    70 => s;
    100 => b;
  }

  if (which == YO)
  {
    202 => h;
    61 => s;
    100 => b;
  }

  if (which == ASCENDING)
  {
    320 => h;
    70 => s;
    100 => b;
  }

  graphicsXmit.startMsg("/nameless/graphics/world/color", "i i i");
  h => graphicsXmit.addInt;
  s => graphicsXmit.addInt;
  b => graphicsXmit.addInt;
}

/************************************************************************* IO */
fun void keyboard()
{
  // the device number to open
  1 => int deviceNum;

  // instantiate a HidIn object
  HidIn hi;
  // structure to hold HID messages
  HidMsg msg;

  // open keyboard
  if( !hi.openKeyboard( deviceNum ) ) me.exit();
  // successful! print name of device
  <<< "keyboard '", hi.name(), "' ready" >>>;
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
        /* <<< msg.which >>>; */

        // -
        if (msg.which == 45) {
          movementNumber--;
          graphicsXmit.startMsg("/nameless/graphics/movement", "i");
          movementNumber => graphicsXmit.addInt;
        }

        // =
        if (msg.which == 46) {
          movementNumber++;
          graphicsXmit.startMsg("/nameless/graphics/movement", "i");
          movementNumber => graphicsXmit.addInt;
        }

        //r
        if (msg.which == 21)
        {
          <<< RED, "RED", RESET >>>;
          spork ~slewColors(HSV.getWarm());
        }

        //g
        if (msg.which == 10)
        {
          <<< GREEN, "GREEN", RESET >>>;
          spork ~slewColors(HSV.getGreen());
        }

        //b
        if (msg.which == 5)
        {
          <<< CYAN, "BLUE", RESET >>>;
          spork ~slewColors(HSV.getCool());
        }

        //y
        if (msg.which == 28)
        {

        }

        // SCALE SHIFTING
        //p
        if (msg.which == PENTATONIC)
        {
          //shift to pentatonic scale
          spork ~gridinit(PENTATONIC);
        }

        //h
        if (msg.which == HIRAJOSHI)
        {
          //shift to hirajoshi scale
          spork ~gridinit(HIRAJOSHI);
        }

        //a
        if (msg.which == AMINOR)
        {
          //shift to aminor scale
          spork ~gridinit(AMINOR);
        }

        //d
        if (msg.which == DMINOR)
        {
          //shift to dminor scale
          spork ~gridinit(DMINOR);
        }

        //y
        if (msg.which == YO)
        {
          spork ~gridinit(YO);
        }

        //z
        if (msg.which == ASCENDING)
        {
          spork ~gridinit(ASCENDING);
        }

        // bass sending

        //sectin changes
        if (msg.which >= 30 && msg.which <= 39)
        {
          //constrain input to 1-0
          spork ~changeSection(msg.which - 29);
        }

        //up arrow, increase saturation
        if (msg.which == 82)
        {
          spork ~mutateSaturation(1);
        }

        //down arrow, decrease saturation
        if (msg.which == 81)
        {
          spork ~mutateSaturation(-1);
        }

        // escape force hide all players.
        if (msg.which == 41)
        {
          <<< RED, "FORCE HIDING ALL NODES", RESET >>>;
          for (int z; z < xmit.targets(); z++)
          {
            spork ~g_hidePlayer(z);
            spork ~g_cellFadeOut(z, positions[z].x, positions[z].y, positions[z].whichEnv);
          }
        }
      }
    }
  }
}


fun void midi()
{
  // the message
  MidiMsg msg;

  // infinite event loop
  while( true )
  {
    // wait on event
    min => now;

    // print message
    while( min.recv( msg ) )
    {
      // print out midi message with id
      <<< "device", device, ":", msg.data1, msg.data2, msg.data3 >>>;

      //key down
      if (msg.data1 == 128)
      {
        //data 2 contains MIDI number
        spork ~sendBass(msg.data2);
      }

      //knob
      if (msg.data1 == 176)
      {
        spork ~sendKnob(msg.data2, msg.data3);
      }
    }
  }
}

/******************************************************************* Sections */

fun void changeSection(int WHICH)
{

  //set front row to envelope 1
  if (WHICH == 1)
  {
    <<< "[ENV] SETTING FRONT ROW TO 1" >>>;
    for (int z; z < xmit.front(); z++)
    {
      0 => positions[z].whichEnv;
    }
  }

  //set front row to envelope 2
  if (WHICH == 2)
  {
    <<< "[ENV] SETTING FRONT ROW TO 2" >>>;
    for (int z; z < xmit.front(); z++)
    {
      1 => positions[z].whichEnv;
    }
  }

  //set front row to envelope 3
  if (WHICH == 3)
  {
    <<< "[ENV] SETTING FRONT ROW TO 3" >>>;
    for (int z; z < xmit.front(); z++)
    {
      2 => positions[z].whichEnv;
    }
  }

  //set front row to envelope 4
  if (WHICH == 4)
  {
    <<< "[ENV] SETTING FRONT ROW TO 4" >>>;
    for (int z; z < xmit.front(); z++)
    {
      3 => positions[z].whichEnv;
    }
  }

  //set back row to envelope 1
  if (WHICH == 7)
  {
    <<< "[ENV] SETTING BACK ROW TO 1" >>>;
    for (xmit.front() => int z; z < xmit.targets(); z++)
    {
      0 => positions[z].whichEnv;
    }
  }

  //set back row to envelope 2
  if (WHICH == 8)
  {
    <<< "[ENV] SETTING BACK ROW TO 2" >>>;
    for (xmit.front() => int z; z < xmit.targets(); z++)
    {
      1 => positions[z].whichEnv;
    }
  }

  //set back row to envelope 3
  if (WHICH == 9)
  {
    <<< "[ENV] SETTING BACK ROW TO 3" >>>;
    for (xmit.front() => int z; z < xmit.targets(); z++)
    {
      2 => positions[z].whichEnv;
    }
  }

  //set back row to envelope 4
  if (WHICH == 10)
  {
    <<< "[ENV] SETTING BACK ROW TO 4" >>>;
    for (xmit.front() => int z; z < xmit.targets(); z++)
    {
      3 => positions[z].whichEnv;
    }
  }
}

/******************************************************************** Control */

//initialize the xmit
xmit.init(me.arg(0));

//init other globals
initscales();
gridinit(HIRAJOSHI);
targetinit();

//graphics.
<<< CYAN, "IMPORTANT NOTE", RESET >>>;
<<< CYAN, "initializing graphics...", RESET >>>;
<<< RED, "processing must already be running to avoid race condition...", RESET >>>;
<<< RED, "please wait until all of the \"OscPlug plugging class world\" messages have completed", RESET >>>;
g_init();
g_init(); // send a second message, just in case the first one is lost.

// start listening (launch thread)
recv.listen();

//begin sending the clock
spork ~sendClock();

//init keyboard
spork ~keyboard();

//init midi
spork ~midi();

//wait for heartbeats from everyone
waitForHeartbeats();
//after all heartbeats are received... the piece is considered active

//aliveness handlers (for real time failsafe)
spork ~heartbeatMonitor();
spork ~timeout();

//run
spork ~handleClient();

//listen
<<< GREEN, "ready...", RESET >>>;
handleAction();
