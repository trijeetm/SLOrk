<<< me.arg(0) >>>;

SinOsc s => ADSR e => Chorus c => dac;

440 => s.freq;

e.set(300::ms, 0::ms, 1, 500::ms);

0.1 => c.modFreq;
0 => c.mix;
1 => c.modDepth;


fun void play() {
  <<< c.mix(), c.modFreq(), c.modDepth() >>>;
  Math.random2f(440.0, 880.0) => s.freq;
  e.keyOn();
  300::ms => now;
  e.keyOff();
  500::ms => now;
}

while (true) {
    spork ~ play();
    300::ms => now;
}