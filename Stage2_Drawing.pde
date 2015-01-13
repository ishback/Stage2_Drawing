

boolean pointer = true;     // shows cursor
boolean drawing = false;    // mousePressed, drawing
boolean drawn = false;      // drawing finished, waiting to send or redraw
boolean sending = false;    
boolean sent = false;

ArrayList<PVector> points;
ArrayList <ArrayList> strokes;

PImage img;

int displayW = 1024;
int displayH = 768;
int camW = 320;
int camH = 240;

//ArrayList<ArrayList<Float>> bigList = new ArrayList<ArrayList<Float>>();

void setup() {
  size(displayW, displayH);
  background(0);
  noStroke();
  points = new ArrayList<PVector>();
}
 
void draw() {
  //frameRate(30);
  noCursor();
  
  if (pointer){
    background(0);
    stroke(255);
    strokeWeight(30);
    point(mouseX, mouseY);
    // println("pointer");
  } else if (drawing){
    stroke(255);
    strokeWeight(30);
    line(pmouseX, pmouseY, mouseX, mouseY);
    //strokes.get(strokes.size()-1).add(new PVector(mouseX, mouseY));
    points.add(new PVector(mouseX, mouseY));
    // println("drawing");
  } else if (drawn){
    image(img, 0, 0);
    point(mouseX, mouseY);
    // println("drawn");
  }
}

void mousePressed() {
  if (mouseButton == LEFT) {
    if (pointer){
      background(0);
      drawing = true;
      drawn = false;
      pointer = false;
      points.clear();
      points.add(new PVector(mouseX, mouseY));
      point(mouseX, mouseY);
    } else if (drawn){
      background(0);
      image(img, 0, 0);
      drawing = true;
      drawn = false;
    }
  } else if (mouseButton == RIGHT) {
    background(0);
    pointer = true;
    drawn = false;
    drawing = false;
  }
}

void mouseReleased() {
  if (drawing){
    drawing = false;
    drawn = true;
    saveFrame("drawing.png");
    img = loadImage("drawing.png");
  }
}

void keyPressed() {
  if (key == 'S' || key == 's') {
    saveFrame("/Users/ishac/Documents/Processing/nearestNeighbor2/data/sample.jpg");
  } else if (key == 'D' || key == 'd'){
    background(0);
    sent = false;
    pointer = true;
  }
}
