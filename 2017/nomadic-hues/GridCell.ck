public class GridCell {

  16 => int MAX_OCCUPANTS; 
  int pitch; //MIDI
  int who[MAX_OCCUPANTS]; //hard coded number of max occupants

  fun int isOccupied() 
  {
    for (int i; i < MAX_OCCUPANTS; i++)
    {
      if (who[i] == 1) return true;
    }

    return false;
  }
}