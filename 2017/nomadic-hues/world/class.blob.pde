class Blob {
  float x, y, radius;
  float xGoal, yGoal;
  float startX, startY, stepSize;
  int id;
  // Colors colors = new Colors();
  color col;
  float alpha = 0;
  float halo = 0;
  int tinklesRemaining = 0;

  boolean alive = false;

  Blob(int _id, float _x, float _y, float _size) {
    stepSize = _size;
    float offset = stepSize / 2;
    startX = _x + offset;
    startY = _y - offset;
    radius = 20;
    halo = 0.5;
    x = startX;
    y = startY;
    xGoal = x;
    yGoal = y;
    id = _id;
  }

  void setX(float x, int teleport) {
    float _x = startX + (stepSize * x);
    xGoal = _x;
    if (teleport == 1) {
      Ani.to(this, 0, 0.1, "x", _x);
      Ani.to(this, 0.1, "alpha", 0, Ani.SINE_IN, "onEnd:appear");
    }
    else
      Ani.to(this, 0.75, "x", _x);
  }

  void setY(float y, int teleport) {
    float _y = startY - (stepSize * y);
    yGoal = _y;
    if (teleport == 2) {
      Ani.to(this, 0, 0.1, "y", _y);
      Ani.to(this, 0.1, "alpha", 0, Ani.SINE_IN, "onEnd:appear");
    }
    else
      Ani.to(this, 0.75, "y", _y);
  }

  void appear() {
    Ani.to(this, 0.1, "alpha", 40, Ani.SINE_OUT);
  }

  void setColor(int h, int s, int b) {
    col = color(h, s, b);
  }

  void hide() {
    Ani.to(this, 2, "alpha", 0);
  }

  void show() {
    Ani.to(this, 2, "alpha", 40);
  }

  void tinkle(int amount) {
    tinklesRemaining = amount;

    tinkleDown();
    // Ani.to(this, 5, "x", xGoal + stepSize / 2, Ani.BOUNCE_IN_OUT);
  }

  void tinkleDown() {
    if (tinklesRemaining > 0) {
      Ani.to(this, 0.2, "alpha", 100, Ani.SINE_IN, "onEnd:tinkleUp");
      Ani.to(this, 0.2, "radius", 15, Ani.SINE_IN);
    }
  }

  void tinkleUp() {
    Ani.to(this, 0.2, "alpha", 40, Ani.SINE_OUT, "onEnd:tinkleDown");
    Ani.to(this, 0.2, "radius", 20, Ani.SINE_OUT);

    tinklesRemaining--;
  }

  void jump() {
    jumpUp();
  }

  void jumpUp() {
    Ani.to(this, 0.1, "alpha", 100, Ani.SINE_IN, "onEnd:jumpDown");
    Ani.to(this, 0.1, "radius", 25, Ani.SINE_IN);
  }

  void jumpDown() {
    Ani.to(this, 1, "alpha", 40, Ani.SINE_OUT);
    Ani.to(this, 1, "radius", 20, Ani.SINE_OUT);
  }

  void worldAlive(boolean b) {
    alive = b;
  }

  void draw() {
    if (!alive)
      return;

    // println(x);

    fill(color(0, 0, 100, 20 * (alpha / 100)));
    ellipse(x, y, radius * (1 + halo), radius * (1 + halo));
    fill(col, alpha);
    ellipse(x, y, radius, radius);
  }
}
