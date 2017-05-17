public class HSV {
  0 => int h;
  0 => int s;
  0 => int v;

  fun static int isCool(int h)
  {
    return (h >= 180 && h < 300);
  }

  fun static int isWarm(int h)
  {
    return (h >= 0 && h < 60 || h >= 300);
  }

  fun static int isGreen(int h)
  {
    return (h >= 60 && h < 180);
  }

  fun static int getCool()
  { 
    //return 210
    //okay random... but focus on centre of 'blue'
    return Math.random2(190, 230);
  }

  fun static int getWarm()
  {
    //return 0

    //0 is center of warm
    if (Math.random2(0,1) == 1)
    {
      return Math.random2(0,20);
    } else
    {
      return Math.random2(340, 359);
    }
  }

  fun static int getGreen()
  {
    //return 120
    //120 is center of green
    return Math.random2(100,140);
  }

  fun string toString()
  {
    return "h " +  h + "s " + s + "v" + v; 
  }

}