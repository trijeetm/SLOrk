class GridCell {
  PShape cell;
  // colors
  int h, s, b;
  float a;
  int state;
  float aIn, aOut;

  GridCell(float _x, float _y, float size) {
    // initialize the grid cell HSB values - for some reason if we do not
    // do things do not work.
    h = 360;
    s = 100;
    b = 100;
    a = 0;
    state = 0;

    cell = createShape(RECT, _x, _y, size, -size);
    cell.setStroke(false);
    cell.setFill(color(h, s, b, a));
  }

  void setColor(int _h, int _s, int _b) {
    h = _h;
    s = _s;
    b = _b;
  }

  PShape getCell() {
    return cell;
  }

  void fadeIn(float t) {
    if (state == 0)
      aIn = a;
    else
      aIn = aOut;

    println("a: " + a + " " + aIn + " " + aOut);

    float dur = t * ((33 - aIn) / 33);
    println("dur: "+dur);

    state = 1;
    Ani.to(this, dur, "aIn", 33, Ani.QUART_OUT);
  }

  void fadeOut(float t) {
    if (state == 1)
      aOut = aIn;
    // else
    //   aOut = a;

    println("a: " + a + " " + aIn + " " + aOut);

    // float dur = t * (aOut / 100);
    float dur = t;
    println("dur: "+dur);

    state = -1;
    Ani.to(this, dur, "aOut", 0, Ani.CUBIC_IN_OUT);
  }

  float getA() {
    return a;
  }

  void draw() {
    if (state == 1)
      a = aIn;
    else if (state == -1)
      a = aOut;
    else
      a = 0;

    cell.setFill(color(h, s, b, a));
    shape(cell);
  }
}
