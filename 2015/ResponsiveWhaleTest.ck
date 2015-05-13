//=========== pad setup ==========//
//Voices
2 => int VOICES;

SawOsc sharpy[VOICES];
LPF filty[VOICES];
Chorus choir[VOICES];
NRev wetrev[VOICES]; 
Gain gain1[VOICES];
SinOsc sinny[VOICES];

//Sawtooth Settings
for (int i; i < VOICES; i++) 
{
    sharpy[i] => filty[i] => choir[i] => wetrev[i] => gain1[i] => dac.chan(i);
    sinny[i] => filty[i] => choir[i] => wetrev[i] => gain1[i] => dac.chan(i);
    //Chorus settings
    0.5 => choir[i].mix;
    4 => choir[i].modDepth;
    //70 => Std.mtof => choir.modFreq;
    
    //Reverb Settings
    0.5 => wetrev[i].mix;
    
    //Final Gain settings
    0.003 => sharpy[i].gain;
    0.003 => sinny[i].gain;
    0.1 => gain1[i].gain;
}



//Plays note
playNote();



//Play a note
fun void playNote()
{
    [ 81, 83, 84, 86, 88, 89, 91, 93 ] @=> int aminor[];
    aminor[Math.random2(0, 7)] => int freq;
    for( int i; i < VOICES; i++ )
    {
        <<< aminor[0] >>>;
        freq => Std.mtof  => sharpy[i].freq;
        freq - 12 => Std.mtof => sinny[i].freq;    
    }
    10::ms => now;
}




