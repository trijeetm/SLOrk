class TextLabel {
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
    yPos = 940;
    Ani.to(this, 1, "alpha", 100, Ani.EXPO_IN_OUT, "onEnd:fadeLabelOut");
    Ani.to(this, 1, "yPos", 920);
  }

  void fadeLabelOut() {
    Ani.to(this, 1, 5, "alpha", 0);
    Ani.to(this, 1, 5, "yPos", 900);
  }

  void draw() {
    fill(255, alpha);
    textFont(_fontLabel, 48);
    text(txt, xPos, yPos);
  }
}
