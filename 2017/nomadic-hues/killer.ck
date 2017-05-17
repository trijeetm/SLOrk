Xmitter xmit;
xmit.init(me.arg(0));

10 => int NUM_TRIES;

<<< "Killing all clients" >>>;

for (int iteration; iteration < NUM_TRIES; iteration++)
{
  for (int z; z < xmit.targets(); z++)
  {
    // a message is kicked as soon as it is complete 
    <<< "Attempt", iteration, "... killing", z >>>;
    xmit.at(z).startMsg( "/slork/kill" );
  }
  10::ms => now;
}
<<< "Done (no guarantee they died, though... yay UDP)" >>>;