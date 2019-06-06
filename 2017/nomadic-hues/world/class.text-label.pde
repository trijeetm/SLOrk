class TextLabel\ {
  float alpha = 0;
  String txt = "";


  int xPos = 120;
  int yPos = 920;

  TextLabel() {

  }

  void displayLabel(String t) {
    updateText(t);
    fadeLabelIn();
  }

  void updateText(String t) {
    txt = t;
  }

  void fadeLabelIn() {
    println("fading in");
    Ani.to(this, 1, "alpha", 100, Ani.EXPO_IN_OUT, "onEnd:fadeLabelOut");
  }

  void fadeLabelOut() {
    println("fading out");
    Ani.to(this, 1, 10, "alpha", 0);
  }

  void draw() {
    fill(255, alpha);
    textFont(_fontLabel, 48);
    text(txt, xPos, yPos);
  }
}
