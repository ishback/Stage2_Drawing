import com.jonwohl.*;
import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import processing.serial.*;
import cc.arduino.*;

int displayW = 1024;
int displayH = 768;

int camW = 320;
int camH = 240;

boolean pointer = true;     // shows pointer
boolean drawing = false;    // mousePressed, drawing
boolean drawn = false;      // drawing finished, waiting to send or redraw
boolean sending = false;
boolean waiting = false;
boolean sent = false;

ArrayList<PVector> points;
ArrayList <ArrayList> strokes;

PImage img;

Arduino arduino;
int buttonPin = 4;
int potPin = 0;

Capture cam;
PImage out;
Attention attention;
PImage src, dst;
OpenCV opencv;
ArrayList<Contour> contours;

int cursorMaxArea = 20000;
int cursorMinArea = 1000;
PVector cursorExpectedCentroid = new PVector(camW/2, camH/2);
int cursorCentroidVariability = 50;
boolean cursorIsShowing = false;
int cursorWaitTime = 2000;
int cursorCountStartTime = 0;

int counterCursor = 0;
int counterCursorMax = 20;
// wait with a cursor until a rectangle blob 'image sent' is detected
boolean cursorON = true;

boolean debugView;

//ArrayList<ArrayList<Float>> bigList = new ArrayList<ArrayList<Float>>();

void setup() {
  size(displayW, displayH);
  background(0);
  frameRate(30);
  String[] ards = Arduino.list();
  // for Mac
  arduino = new Arduino(this, ards[ards.length - 1], 57600);
  // for Odroid
//  arduino = new Arduino(this, ards[ards.length - 1], 57600);
  arduino.pinMode(4, Arduino.INPUT);
  
  cam = new Capture(this, camW, camH);

  cam.start();
  
  // instantiate focus passing an initial input image
  attention = new Attention(this, cam);
  out = attention.focus(cam, cam.width, cam.height);
  
  // this opencv object is for contour (i.e. paddle) detection
  opencv = new OpenCV(this, out);
  
  // initialize points list for drawing
  noStroke();
  points = new ArrayList<PVector>();
}
 
void draw() {
  if (cam.available()) { 
    // Reads the new frame
    cam.read();
  }
  
  // show attention view on buttonpress
//  if (arduino.digitalRead(buttonPin) == Arduino.HIGH){
//    buttonDown = true; 
//  } else {
//    buttonDown = false;
//  }
  
  // warp the selected region on the input image (cam) to an output image of width x height
  out = attention.focus(cam, cam.width, cam.height);
  
  // threshold using only the red pixels
  float thresh = map(arduino.analogRead(potPin), 0, 1024, 0, 255);
  redThreshold(out, thresh);
  
  opencv.loadImage(out);
  
  // draw the warped and thresholded image
  dst = opencv.getOutput();
  
  // use the first contour, assume it's the only/biggest one.
  contours = opencv.findContours();
  if (contours.size() > 0) {
    Contour contour = contours.get(0);
    
    // find and draw the centroid, justforthehellavit.
    ArrayList<PVector> points = contour.getPolygonApproximation().getPoints();
    PVector centroid = calculateCentroid(points);

    Rectangle bb = contour.getBoundingBox();
//    bb.setBounds((int) (bb.x * resizeRatio.x), (int)(bb.y * resizeRatio.y), (int)(bb.width * resizeRatio.x), (int)(bb.height * resizeRatio.y));
//    if (buttonDown) {
//      stroke(0, 255, 0);
//      rect(bb.x, bb.y, bb.width, bb.height);
//    }
    noStroke();
    // resize bb
    // println("rectArea: " + getArea(bb));
    int area = getArea(bb);
    if (area < cursorMaxArea && area > cursorMinArea && PVector.dist(centroid, cursorExpectedCentroid) < cursorCentroidVariability) {
      // this is a cursor
      cursorCountStartTime = millis();
      
      if (!cursorIsShowing) {
        cursorIsShowing = true;
        waiting = false;
      }
    }
    
    // show the cursor if cursorWaitTime has ellapsed since last seeing a cursor and the person isn't drawing
    if ((millis() - cursorCountStartTime) > cursorWaitTime && !drawing) {
      cursorIsShowing = false;
      waiting = true;
      pointer = true;
      drawn = false;
    }
    
  }
  
  // do drawing stuff
  if (pointer){
    println("POINTER");
    background(0);
    stroke(255);
    strokeWeight(30);
    point(mouseX, mouseY);
    // println("pointer");
  } else if (drawing){
    println("DRAWING");
    stroke(255);
    strokeWeight(30);
    line(pmouseX, pmouseY, mouseX, mouseY);
    //strokes.get(strokes.size()-1).add(new PVector(mouseX, mouseY));
    points.add(new PVector(mouseX, mouseY));
    // println("drawing");
  } else if (drawn){
    println("DRAWN");
    image(img, 0, 0);
    point(mouseX, mouseY);
    // println("drawn");
  } 
  
  if (waiting){
    println("WAITING");
    background(0);
    if (counterCursor == counterCursorMax){
      cursorON = !cursorON;
      counterCursor = 0;
    }
    if (cursorON){
      fill(255);
      rectMode(CENTER);
      rect(width/2, height/2, 40, 40);
      rectMode(CORNER);
    }
    counterCursor++;
  }
  
  if (debugView){
    image(dst, 0, 0);
  }
}

PVector calculateCentroid(ArrayList<PVector> points) {
  ArrayList<Float> x = new ArrayList<Float>();
  ArrayList<Float> y = new ArrayList<Float>();
  for(PVector point : points) {
    x.add(point.x);
    y.add(point.y); 
  }
  float xTemp = findAverage(x);
  float yTemp = findAverage(y);
  PVector cen = new PVector(xTemp,yTemp);
  return cen;
   
}

float findAverage(ArrayList<Float> vals) {
  float numElements = vals.size();
  float sum = 0;
  for (int i=0; i< numElements; i++) {
    sum += vals.get(i);
  }
  return sum/numElements;
}

void redThreshold(PImage img, float thresh){
  img.loadPixels();
  int numPix = 0;
  for (int i=0; i < img.pixels.length; i++){
    if (red(img.pixels[i]) > thresh){
      img.pixels[i] = color(255, 255, 255);
      numPix++;
    } else {
      img.pixels[i] = color(0, 0, 0);
    }
  } 
  img.updatePixels();
}

int getArea(Rectangle r){
  int area = r.width*r.height;
  return area;
}

void mousePressed() {
  if (mouseButton == LEFT) {
    if (pointer){
//      println("MOUSEUP - POINTER");
      background(0);
      waiting = false;
      cursorCountStartTime = millis();
      drawing = true;
      drawn = false;
      pointer = false;
      points.clear();
      points.add(new PVector(mouseX, mouseY));
      point(mouseX, mouseY);
    } else if (drawn){
//      println("DRAWN");
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
    cursorCountStartTime = millis();
    drawing = false;
    drawn = true;
    saveFrame("drawing.png");
    img = loadImage("drawing.png");
  }
}

void keyPressed() {
  if (key == 'S' || key == 's') {
    saveFrame("/Users/ishac/Documents/Processing/nearestNeighbor2/data/sample.jpg");
  } else if (key == 'D' || key == 'd') {
    debugView = !debugView;  
  }
}
