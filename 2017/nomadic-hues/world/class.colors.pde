class Colors {
  static final int N_COLORS = 11;
  color[] colors = {
    color(255, 45, 85),
    color(246, 178, 34),
    color(21, 158, 239),
    color(21, 158, 2),
    color(21, 1, 239),
    color(21, 1, 100),
    color(215, 158, 239),
    color(212, 58, 239),
    color(211, 158, 9),
    color(211, 100, 29),
    color(169, 208, 5)
  };

  Colors() {
  }

  color getById(int id) {
    return colors[id % N_COLORS];
  }
}