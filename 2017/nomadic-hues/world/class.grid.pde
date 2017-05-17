class Grid {
  // world
  int n;
  float worldSize, cellSize;
  float startX, startY;
  int players;

  boolean alive = false;

  // cells
  ArrayList<GridCell> cells;

  Grid(int _n, int _p, float _worldSize, float _cellSize, float _x, float _y) {
    n = _n;
    players = _p;
    worldSize = _worldSize;
    cellSize = _cellSize;
    startX = _x;
    startY = _y;

    initCells();
  }

  void initCells() {
    int nCells = players * n * n;
    cells = new ArrayList<GridCell>();

    for (int p = 0; p < players; p++) {
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          GridCell cell = new GridCell(startX + (cellSize * i), startY - (cellSize * j), cellSize);
          cells.add(cell);
        }
      }
    }
  }

  void updateCell(int id, int x, int y, int h, int s, int b) {
    int idx = (id * n * n) + (x * n) + y;

    cells.get(idx).setColor(h, s, b);
  }

  void cellFadeIn(int id, int x, int y, int time) {
    println("fading in: " + id + " " + x + " " + y + " " + (time / 1000.0));

    int idx = (id * n * n) + (x * n) + y;

    cells.get(idx).fadeIn(time / 1000.0); // convert to seconds    
  }

  void cellFadeOut(int id, int x, int y, int time) {
    println("fading out: " + id + " " + x + " " + y + " " + (time / 1000.0));

    int idx = (id * n * n) + (x * n) + y;

    cells.get(idx).fadeOut(time / 1000.0); // convert to seconds    
  }

  void worldAlive(boolean b) {
    alive = b;
  }

  void draw(float h, float s, float b) {
    if (alive)
      for (GridCell cell : cells)
        cell.draw();

    stroke(h, s, b, 10);
    strokeWeight(3);

    for (int i = 0; i <= n; ++i) {
      line(startX + (cellSize * i), startY, startX + (cellSize * i), startY - worldSize);
      line(startX, startY - (cellSize * i), startX + worldSize, startY - (cellSize * i));
    }

    noStroke();
  }
}