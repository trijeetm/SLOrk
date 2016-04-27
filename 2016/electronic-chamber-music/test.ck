SinOsc s => ADSR e => Chorus c => dac;

440 => s.freq;

e.set(300::ms, 300::ms, 1, 500::ms);

0.1 => c.modFreq;
0.5 => c.mix;
1 => c.modDepth;


while (true) {
  <<< c.mix(), c.modFreq(), c.modDepth() >>>;
  e.keyOn();
  300::ms => now;
  e.keyOff();
  500::ms => now;
}