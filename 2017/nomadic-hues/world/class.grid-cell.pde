class GridCell {
  PShape cell;
  // colors
  int h, s, b;
  float a;
  int state = 0;
  float aIn, aOut;

  GridCell(float _x, float _y, float size) {
    // h = 360;
    // s = 100;
    // b = 100;
    // a = 50;

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

  void draw() {
    float _a;
    if (state == 1)
      _a = aIn;
    else if (state == -1)
      _a = aOut;
    else
      _a = 0;

    // if (_a != 0)
      // println("_a: "+_a);

    cell.setFill(color(h, s, b, _a));
    shape(cell);
  }
}