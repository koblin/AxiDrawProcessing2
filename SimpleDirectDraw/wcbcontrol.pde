/**
 * RoboPaint RT - watercolorbot control functions
 */



void raiseBrush() 
{  
  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    raiseBrushStatus = 1; // Flag to raise brush when no longer busy.
  }
  else
  {
    if (BrushDown == true) {
      if (SerialOnline) {
        myPort.write("SP,0\r");           
        BrushDown = false;
        NextMoveTime = millis() + delayAfterRaisingBrush;
      }
      //      if (debugMode) println("Raise Brush.");
    }
    raiseBrushStatus = -1; // Clear flag.
  }
}



void ConfigBrushDownHeight(int state) 
{ 
  // State 0: Wash      ConfigBrushDownHeight(0);// Set Brush to WASH height
  // State 1: Paint     ConfigBrushDownHeight(1);// Set Brush to PAINT height

  int position;

  //if (state == 0)
  //  position = ServoWash;
  //else
    position = ServoPaint;

  if (SerialOnline) {
    myPort.write("SC,4," + str(position) + "\r");  // Brush DOWN position
  }
}




void lowerBrush() 
{
  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    lowerBrushStatus = 1;  // Flag to lower brush when no longer busy.
    // delay (waitTime);  // Wait for prior move to finish:
  }
  else
  { 
    if  (BrushDown == false)
    {      
      if (SerialOnline) {
        myPort.write("SP,1\r");           // Lower Brush
        BrushDown = true;
        NextMoveTime = millis() + delayAfterLoweringBrush;
        lastPosition = -1;
      }
      //      if (debugMode) println("Lower Brush.");
    }
    lowerBrushStatus = -1; // Clear flag.
  }
}


void MoveRelativeXY(int xD, int yD)
{
  // Change carriage position by (xDelta, yDelta), with XY limit checking, time management, etc.

  int xTemp = MotorX + xD;
  int yTemp = MotorY + yD;

  moveToXY(xTemp, yTemp);
}


void moveToXY(int xLoc, int yLoc)
{
  MoveDestX = xLoc;
  MoveDestY = yLoc;

  moveToXY();
}

void moveToXY()
{
  int traveltime_ms;

  // Absolute move in motor coordinates, with XY limit checking, time management, etc.
  // Use moveToXY(int xLoc, int yLoc) to set destinations.

  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    moveStatus = 1;  // Flag this move as not yet completed.
  }
  else
  {
    if ((MoveDestX < 0) || (MoveDestY < 0))
    { 
      // Destination has not been set up correctly.
      // Re-initialize varaibles and prepare for next move.  
      MoveDestX = -1;
      MoveDestY = -1;
    }
    else {

      moveStatus = -1;
      if (MoveDestX > MotorMaxX) 
        MoveDestX = MotorMaxX; 
      else if (MoveDestX < MotorMinX) 
        MoveDestX = MotorMinX; 

      if (MoveDestY > MotorMaxY) 
        MoveDestY = MotorMaxY; 
      else if (MoveDestY < MotorMinY) 
        MoveDestY = MotorMinY; 

      int xD = MoveDestX - MotorX;
      int yD = MoveDestY - MotorY;

      if ((xD != 0) || (yD != 0))
      {   

        MotorX = MoveDestX;
        MotorY = MoveDestY;

        int MaxTravel = max(abs(xD), abs(yD)); 
        traveltime_ms = int(floor( float(1000 * MaxTravel)/MotorSpeed));


        NextMoveTime = millis() + traveltime_ms -   ceil(1000 / frameRate);
        // Important correction-- Start next segment sooner than you might expect,
        // because of the relatively low framerate that the program runs at.
      
        

        if (SerialOnline) {
          if (reverseMotorX)
            xD *= -1;
          if (reverseMotorY)
            yD *= -1; 

          myPort.write("XM," + str(traveltime_ms) + "," + str(xD) + "," + str(yD) + "\r");

          //myPort.write("SM," + str(traveltime_ms) + "," + str(xD) + "," + str(yD) + "\r");
          //General command "SM,<duration>,<penmotor steps>,<eggmotor steps><CR>"
        }

        // Calculate and animate position location cursor
        int[] pos = getMotorPixelPos();
        float sec = traveltime_ms/1000.0;

        Ani.to(this, sec, "MotorLocatorX", pos[0]);
        Ani.to(this, sec, "MotorLocatorY", pos[1]);

        //        if (debugMode) println("Motor X: " + MotorX + "  Motor Y: " + MotorY);
      }
    }
  }
}

void motorsOff()
{
  if (SerialOnline)
  {    
    myPort.write("EM,0,0\r");  //Disable both motors

    //    if (debugMode) println("Motors disabled.");
  }
}

void zero()
{
  // Mark current location as (0,0) in motor coordinates.  
  // Manually move the motor carriage to the left-rear (upper left) corner before executing this command.

  MotorX = 0;
  MotorY = 0;

  moveStatus = -1;
  MoveDestX = -1;
  MoveDestY = -1;


  //  if (debugMode) println("Motor X: " + MotorX + "  Motor Y: " + MotorY);
}