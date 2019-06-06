import oscP5.*;
import de.looksgood.ani.*;

// globals
boolean serverReady = false;

// osc
OscP5 oscP5;

// data
Colors colors = new Colors();

// update variables as per world
int N_PLAYERS = 10;
int WIDTH = 10;
int HEIGHT = 10;

float WORLD_SIZE = 960;
float CELL_SIZE = WORLD_SIZE / WIDTH;

float worldH = 0;
float worldS = 0;
float worldB = 0;

// geometry
Blob[] blobs = new Blob[N_PLAYERS];
Grid grid;

// text labels
// STEP 1 Declare PFont variable
PFont _fontLabel;
TextLabel movementLabel = new TextLabel();

void setup() {
  //size(1280, 720, P2D);
  smooth(8);
  noStroke();
  noCursor();
  fullScreen(2);
  colorMode(HSB, 360, 100, 100, 100);
  frameRate(60);

  _fontLabel = createFont("Calluna", 48, true);

  Ani.init(this);

  oscP5 = new OscP5(this, 4242);

  initWorld();

  /* osc plug service
   * osc messages with a specific address pattern can be automatically
   * forwarded to a specific method of an object. in this example
   * a message with address pattern /test will be forwarded to a method
   * test(). below the method test takes 2 arguments - 2 ints. therefore each
   * message with address pattern /test and typetag ii will be forwarded to
   * the method test(int theA, int theB)
   */
  oscP5.plug(this, "resetWorld", "/nameless/graphics/init");
  oscP5.plug(this, "updateWorld", "/nameless/graphics/world/color");
  oscP5.plug(this, "updatePlayer", "/nameless/graphics/player/move");
  oscP5.plug(this, "updatePlayerColor", "/nameless/graphics/player/color");
  oscP5.plug(this, "jumpPlayer", "/nameless/graphics/player/jump");
  oscP5.plug(this, "tinklePlayer", "/nameless/graphics/player/tinkle");
  oscP5.plug(this, "showPlayer", "/nameless/graphics/player/enter");
  oscP5.plug(this, "hidePlayer", "/nameless/graphics/player/exit");
  oscP5.plug(this, "cellFadeIn", "/nameless/graphics/cell/fadeIn");
  oscP5.plug(this, "cellFadeOut", "/nameless/graphics/cell/fadeOut");
  oscP5.plug(this, "showMovementLabel", "/nameless/graphics/movement");
}

void draw() {
  background(0);

  if (grid != null)
    grid.draw(worldH, worldS, worldB);

  if (blobs != null)
    for (int i = 0; i < N_PLAYERS; i++) {
      Blob blob = blobs[i];
      if (blob != null)
        blob.draw();
    }

  movementLabel.draw();
}

void initWorld() {
  float _x = (width / 2) - (WORLD_SIZE / 2);
  float _y = (height / 2) + (WORLD_SIZE / 2);

  blobs = new Blob[N_PLAYERS];

  for (int id = 0; id < N_PLAYERS; ++id) {
    blobs[id] = new Blob(id, _x, _y, CELL_SIZE);
    blobs[id].hide();
    blobs[id].worldAlive(true);
  }

  grid = new Grid(WIDTH, N_PLAYERS, WORLD_SIZE, CELL_SIZE, _x, _y);
  grid.worldAlive(true);

  println("players: "+N_PLAYERS);
}

void resetWorld(int n, int width, int height) {
  if (n != N_PLAYERS)
    N_PLAYERS = n;

  if (height != HEIGHT)
    HEIGHT = height;

  if (width != WIDTH)
    WIDTH = width;

  serverReady = true;

  initWorld();
}

void updateWorld(int h, int s, int b) {
  // worldH = h;
  // worldS = s;
  // worldB = b;

  Ani.to(this, 5, "worldH", h * 1.0, Ani.SINE_IN_OUT);
  Ani.to(this, 5, "worldS", s * 1.0, Ani.SINE_IN_OUT);
  Ani.to(this, 5, "worldB", b * 1.0, Ani.SINE_IN_OUT);
}

void showPlayer(int id) {
  blobs[id].show();
}

void hidePlayer(int id) {
  blobs[id].hide();
}

void tinklePlayer(int id, int amount) {
  blobs[id].tinkle(amount);
}

void jumpPlayer(int id) {
  blobs[id].jump();
}

void updatePlayer(int id, int x, int y, int h, int s, int b, int teleport) {
  blobs[id].setX(x, teleport);
  blobs[id].setY(y, teleport);
  blobs[id].setColor(h, s, b);
  grid.updateCell(id, x, y, h, s, b);
}

void updatePlayerColor(int id, int x, int y, int h, int s, int b) {
  blobs[id].setColor(h, s, b);
  grid.updateCell(id, x, y, h, s, b);
}

void cellFadeIn(int id, int x, int y, int time) {
  println("cell fade in: " + id + " " + x + " " + y + " " + time);
  grid.cellFadeIn(id, x, y, time);
}

void cellFadeOut(int id, int x, int y, int time) {
  println("cell fade out: " + id + x + y + time);
  grid.cellFadeOut(id, x, y, time);
}

void showMovementLabel(int mvt) {
  if ((mvt > 0) && (mvt <= 12)) {
    println("Displaying label for movement:", mvt);

    String mvtLabel = "";

    switch(mvt) {
      case 1:
        mvtLabel = "I. discovery";
        break;
      case 2:
        mvtLabel = "II. settle";
        break;
      case 3:
        mvtLabel = "III. strangers";
        break;
      case 4:
        mvtLabel = "IV. kinship";
        break;
      case 5:
        mvtLabel = "V. opportunism";
        break;
      case 6:
        mvtLabel = "VI. chaos";
        break;
      case 7:
        mvtLabel = "VII. glitch";
        break;
      case 8:
        mvtLabel = "VIII. rebirth";
        break;
      case 9:
        mvtLabel = "IX. bustle";
        break;
      case 10:
        mvtLabel = "X. rain";
        break;
      case 11:
        mvtLabel = "XI. civilization";
        break;
      case 12:
        mvtLabel = "XII. dust";
        break;
    }

    movementLabel.displayLabel(mvtLabel);
  }
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage oscMsg) {
  /* with theOscMessage.isPlugged() you check if the osc message has already been
   * forwarded to a plugged method. if theOscMessage.isPlugged()==true, it has already
   * been forwared to another method in your sketch. theOscMessage.isPlugged() can
   * be used for double posting but is not required.
  */
  if (oscMsg.isPlugged() == false) {
    /* print the address pattern and the typetag of the received OscMessage */
    println("### received an osc message.");
    println("### addrpattern\t" + oscMsg.addrPattern());
    println("### typetag\t"+ oscMsg.typetag());
  }
}

//trap escape key
void keyPressed(){
  if(key==27)
    key=0;
}
