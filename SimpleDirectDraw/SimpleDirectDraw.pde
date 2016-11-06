import de.looksgood.ani.*;
import processing.serial.*;

//import javax.swing.UIManager; 
//import javax.swing.JFileChooser; 


// Really raw axidraw controller (code taken from RobotpaintRT)

// press 'm' to unlock/lock motors
// press 'z' to zero (set home location)
// moveToXY(int, int); to move around
// raiseBrush(); etc.


// User Settings: 
float MotorSpeed = 1500.0;  // Steps per second, 1500 default

int ServoUpPct = 70;    // Brush UP position, %  (higher number lifts higher). 
int ServoPaintPct = 30;    // Brush DOWN position, %  (higher number lifts higher). 
int ServoWashPct = 20;    // Brush DOWN position for washing brush, %  (higher number lifts higher). 

boolean reverseMotorX = false;
boolean reverseMotorY = false;

int delayAfterRaisingBrush = 300; //ms
int delayAfterLoweringBrush = 300; //ms

//int minDist = 4; // Minimum drag distance to record

boolean debugMode = true;


// Offscreen buffer images for holding drawn elements, makes redrawing MUCH faster

PGraphics offScreen;

PImage imgBackground;   // Stores background data image only.
PImage imgMain;         // Primary drawing canvas
PImage imgLocator;      // Cursor crosshairs
PImage imgButtons;      // Text buttons
PImage imgHighlight;
String BackgroundImageName = "background.png"; 
String HelpImageName = "help.png"; 

float ColorDistance;
boolean segmentQueued = false;
int queuePt1 = -1;
int queuePt2 = -1;

//float MotorStepsPerPixel =  16.75;  // For use with 1/16 steps
float MotorStepsPerPixel = 8.36;// Good for 1/8 steps-- standard behavior.
int xMotorPaperOffset =  1400;  // For 1/8 steps  Use 2900 for 1/16?

// Positions of screen items

//float paintSwatchX = 108.8;
//float paintSwatchY0 = 84.5;
//float paintSwatchyD = 54.55;
//int paintSwatchOvalWidth = 64;
//int paintSwatchOvalheight = 47;

//int WaterDishX = 2;
//int WaterDishY0 = 88;
//float WaterDishyD = 161.25;
//int WaterDishDia = 118;

//int MousePaperLeft =  185;
//int MousePaperRight =  769;
//int MousePaperTop =  62;
//int MousePaperBottom =  488;

int xMotorOffsetPixels = 0;  // Corrections to initial motor position w.r.t. lower plate (paints & paper)
int yMotorOffsetPixels = 4 ;


int xBrushRestPositionPixels = 18;     // Brush rest position, in pixels
int yBrushRestPositionPixels =  yMotorOffsetPixels;

int ServoUp;    // Brush UP position, native units
int ServoPaint;    // Brush DOWN position, native units. 
//int ServoWash;    // Brush DOWN position, native units

int MotorMinX;
int MotorMinY;
int MotorMaxX;
int MotorMaxY;

boolean firstPath;
boolean doSerialConnect = true;
boolean SerialOnline;
Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port

boolean BrushDown;
boolean BrushDownAtPause;
boolean DrawingPath = false;

int xLocAtPause;
int yLocAtPause;

int MotorX;  // Position of X motor
int MotorY;  // Position of Y motor
int MotorLocatorX;  // Position of motor locator
int MotorLocatorY; 
int lastPosition; // Record last encoded position for drawing

int selectedColor;
int selectedWater;
int highlightedWater;
int highlightedColor; 


boolean lastBrushDown_DrawingPath;
int lastX_DrawingPath;
int lastY_DrawingPath;


int NextMoveTime;          //Time we are allowed to begin the next movement (i.e., when the current move will be complete).
int SubsequentWaitTime = -1;    //How long the following movement will take.
//int UIMessageExpire;
int raiseBrushStatus;
int lowerBrushStatus;
int moveStatus;
int MoveDestX;
int MoveDestY; 
//int getWaterStatus;
//int WaterDest;
//boolean WaterDestMode;
int PaintDest; 

int CleaningStatus;
int getPaintStatus; 
boolean Paused;


int ToDoList[];  // Queue future events in an integer array; executed when PriorityList is empty.
int indexDone;    // Index in to-do list of last action performed
int indexDrawn;   // Index in to-do list of last to-do element drawn to screen


// Active buttons
PFont font_ML16;
PFont font_CB; // Command button font
PFont font_url;


int TextColor = 75;
int LabelColor = 150;
//color TextHighLight = Black;
int DefocusColor = 175;

//SimpleButton pauseButton;
//SimpleButton brushUpButton;
//SimpleButton brushDownButton;
//SimpleButton cleanButton;
//SimpleButton parkButton;
//SimpleButton motorOffButton;
//SimpleButton motorZeroButton;
//SimpleButton clearButton;
//SimpleButton replayButton;
//SimpleButton urlButton;
//SimpleButton openButton;
//SimpleButton saveButton;


//SimpleButton brushLabel;
//SimpleButton motorLabel;
//SimpleButton UIMessage;

void setup() {
  size(800, 600);

  Ani.init(this); // Initialize animation library
  Ani.setDefaultEasing(Ani.LINEAR);

  MotorMinX = 0;
  MotorMinY = 0;
  MotorMaxX = int(floor(xMotorPaperOffset + width * MotorStepsPerPixel)) ;
  MotorMaxY = int(floor(height * MotorStepsPerPixel)) ;

  //MotorMaxX = int(floor(xMotorPaperOffset + float(MousePaperRight - MousePaperLeft) * MotorStepsPerPixel)) ;
  //MotorMaxY = int(floor(float(MousePaperBottom - MousePaperTop) * MotorStepsPerPixel)) ;

  ServoUp = 7500 + 175 * ServoUpPct;    // Brush UP position, native units
  ServoPaint = 7500 + 175 * ServoPaintPct;   // Brush DOWN position, native units. 

  MotorX = 0;
  MotorY = 0; 

  ToDoList = new int[0];
  ToDoList = append(ToDoList, -35);  // Command code: Go home (0,0)

  indexDone = -1;    // Index in to-do list of last action performed
  indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

  raiseBrushStatus = -1;
   lowerBrushStatus = -1; 
   moveStatus = -1;
   MoveDestX = -1;
   MoveDestY = -1;

int[] pos = getMotorPixelPos();

  Paused = false;
  BrushDownAtPause = false;
  MotorLocatorX = pos[0];
  MotorLocatorY = pos[1];

  NextMoveTime = millis();
}



void draw() {
  if (doSerialConnect)
  {
    // FIRST RUN ONLY:  Connect here, so that 

    doSerialConnect = false;

    scanSerial();

    if (SerialOnline)
    {    
      myPort.write("EM,2\r");  //Configure both steppers to 1/8 step mode

      // Configure brush lift servo endpoints and speed
      myPort.write("SC,4," + str(ServoPaint) + "\r");  // Brush DOWN position, for painting
      myPort.write("SC,5," + str(ServoUp) + "\r");  // Brush UP position 

      //    myPort.write("SC,10,255\r"); // Set brush raising and lowering speed.
      myPort.write("SC,10,65535\r"); // Set brush raising and lowering speed.


      // Ensure that we actually raise the brush:
      BrushDown = true;  
      raiseBrush();    

      println("Now entering interactive painting mode.\n");
      //redrawButtons();
    } else
    { 
      println("Now entering offline simulation mode.\n");

      //UIMessage.label = "WaterColorBot not found.  Entering Simulation Mode. ";
      //UIMessageExpire = millis() + 5000;
      //redrawButtons();
    }
  }
}







boolean brushIsUp = true;
void mousePressed() {
  if (brushIsUp) {
    lowerBrush();
    println("Brush Up");
  
  } else {
    raiseBrush();
    println("Brush Down");
    myPort.write("SP,0\r");
  }
  brushIsUp = !brushIsUp;
}




void mouseReleased() {

   myPort.write("XM," + str(1000) + "," + str(1000) + "," + str(1000) + "\r");
}


void keyReleased()
{

  if (key == CODED) {

    //if (keyCode == UP) keyup = false; 
    //if (keyCode == DOWN) keydown = false; 
    //if (keyCode == LEFT) keyleft = false; 
    //if (keyCode == RIGHT) keyright = false; 

    if (keyCode == SHIFT) { 

      //shiftKeyDown = false;
    }
  }

  if ( key == 'h')  // display help
  {
    //hKeyDown = false;
  }
}



void keyPressed()
{

  int nx = 0;
  int ny = 0;

  if (key == CODED) {

    // Arrow keys are used for nudging, with or without shift key.

    if (keyCode == UP) 
    {
      //keyup = true;
    }
    if (keyCode == DOWN)
    { 
      //keydown = true;
    }
    //if (keyCode == LEFT) keyleft = true; 
    //if (keyCode == RIGHT) keyright = true; 
    //if (keyCode == SHIFT) shiftKeyDown = true;
  } else
  {

    if ( key == 'b')   // Toggle brush up or brush down with 'b' key
    {
      if (BrushDown)
        raiseBrush();
      else
        lowerBrush();
    }

    if ( key == 'z'){  // Zero motor coordinates
      zero();
      println("zero'd");
    }

    if ( key == ' ') { //Space bar: Pause
      pause();
      println("paused");
    }

    if ( key == 'q')  // Move home (0,0)
    {
      raiseBrush();
      moveToXY(0, 0);
    }


    if ( key == 'r')  // go to random
    {
      moveToXY(int(random(8000)), int(random(6000))); 
    }


    if ( key == 'm'){  // Disable motors, to manually move carriage.  
      motorsOff();
      println("motors unlocked");
    }

    if ( key == '1')
      MotorSpeed = 100;  
    if ( key == '2')
      MotorSpeed = 250;        
    if ( key == '3')
      MotorSpeed = 500;        
    if ( key == '4')
      MotorSpeed = 750;        
    if ( key == '5')
      MotorSpeed = 1000;        
    if ( key == '6')
      MotorSpeed = 1250;        
    if ( key == '7')
      MotorSpeed = 1500;        
    if ( key == '8')
      MotorSpeed = 1750;        
    if ( key == '9')
      MotorSpeed = 2000;
  }
}