public class Xmitter
{
  // send objects
  OscSend backing[16];
  // number of targets (initialized by init)
  int num_targets;
  // port
  6449 => int port;

  5 => int NUM_BASS;
  int bassIndexes[NUM_BASS];

  5 => int NUM_IN_FRONT;
  6 => int NUM_IN_BACK;

  fun void init(string arg)
  {
    if (arg == "local" || arg == "l" || arg == "localhost")
    {
      <<< "Initializing Xmitter for local" >>>;
      1 => num_targets;

      1 => NUM_BASS;

      //write into the bassIndexes array negative numbers if you want less than
      //NUM_BASS basses (handled as special case by the sendBass function)
      [0] @=> bassIndexes;
      backing[0].setHost ( "localhost", port );
    } else
    {
      <<< "Initializing Xmitter for non-local" >>>;

      10 => NUM_BASS;
      10 => num_targets;
      [0,1,2,3,4,5,6,7,8,9] @=> bassIndexes;

      5 => NUM_IN_FRONT;
      5 => NUM_IN_BACK;

      // left
      backing[0].setHost ( "lasagna.local", port );
      backing[1].setHost ( "omelet.local", port );
      backing[2].setHost ( "pho.local", port );
      backing[3].setHost ( "empanada.local", port );
      backing[4].setHost ( "meatloaf.local", port );

      // right
      backing[5].setHost ( "quinoa.local", port );
      backing[6].setHost ( "nachos.local", port );
      backing[7].setHost ( "foiegras.local", port );
      backing[8].setHost ( "udon.local", port );
      backing[9].setHost ( "chowder.local", port );
    }
  }

  fun int targets()
  {
    return num_targets;
  }

  fun OscSend @ at(int i)
  {
    return backing[i];
  }

  fun int[] basses()
  {
    return bassIndexes;
  }

  fun int front()
  {
    return NUM_IN_FRONT;
  }

  fun int back()
  {
    return NUM_IN_BACK;
  }
}
