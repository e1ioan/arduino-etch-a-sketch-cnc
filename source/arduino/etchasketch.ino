/**
* Copyright 2016, Ioan Ghip <ioanghip (at) gmail (dot) com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
* 02110-1301, USA.
*/

#include <Stepper.h>

#define SERIAL_SPEED           (57600)  // How fast is the Arduino talking?
#define STEPS_PER_MOTOR_REVOLUTION 32
#define STEPS_PER_OUTPUT_REVOLUTION 32 * 64

Stepper my(STEPS_PER_MOTOR_REVOLUTION, 8, 10, 9, 11);
Stepper mx(STEPS_PER_MOTOR_REVOLUTION, 4, 6, 5, 7);

String rec_gcode_string;  // the gcode command

float x_location, y_location;  // curent coordinates

void newPosition(float new_x_location,float new_y_location) 
{
  x_location = new_x_location;
  y_location = new_y_location;
}

void bresenham(float newx,float newy) 
{
  long dx=newx-x_location;
  long dy=newy-y_location;
  int dirx=dx>0?1:-1;
  int diry=dy>0?-1:1; 
  dx=abs(dx);
  dy=abs(dy);

  long i;
  long over=0;

  if(dx>dy) 
  {
    for(i=0;i<dx;++i) 
    {
      mx.step(dirx);
      over+=dy;
      if(over>=dx) 
      {
        over-=dx;
        my.step(-diry);
      }
    }
  } 
  else 
  {
    for(i=0;i<dy;++i) 
    {
      my.step(-diry);
      over+=dx;
      if(over>=dy) 
      {
        over-=dy;
        mx.step(dirx);
      }
    }
  }
  newPosition(newx, newy);
}

float parseGcode(String s, char code, float default_val)
{
  char *ptr;
  char b[255]; // that should be enough for g-code 
  s.toCharArray(b,s.length());
  for (ptr = strtok(b," "); ptr != NULL; ptr = strtok(NULL, " "))
  {
    if (ptr[0] == code)
    {
      return atof(ptr+1);
    }
  } 
  return default_val;
}

void listCommands() 
{
  Serial.println(F("Commands:"));
  Serial.println(F("G00 [X(steps)] [Y(steps)]; - draw line"));
  Serial.println(F("G92 [X(steps)] [Y(steps)]; - change logical position"));
  Serial.println(F("M100; - help message"));
  Serial.println(F("M114; - report position"));
  Serial.println(F("All commands must end with a newline."));
}


void processCommand() {
  int cmd = parseGcode(rec_gcode_string,'G',-1);
  switch(cmd) 
  {
    case  0:
    case  1: // line 
    case  2:
    case  3:
    { 
      bresenham(parseGcode(rec_gcode_string,'X',x_location), parseGcode(rec_gcode_string,'Y',y_location));
      break;
    }
    case 92:
    {
      newPosition(parseGcode(rec_gcode_string,'X',0), parseGcode(rec_gcode_string,'Y',0));
      break;
    }
    default:  
      break;
  }

  cmd = parseGcode(rec_gcode_string,'M',-1);
  switch(cmd) 
  {
    case 100:
    {  
      listCommands();  
      break;
    }
    case 114:
    { 
      Serial.print("X");
      Serial.println(x_location); 
      Serial.print("Y");
      Serial.println(y_location); 
      break;
    }
    default:  
      break;
  }
}

void setup() 
{
  Serial.begin(SERIAL_SPEED);
  mx.setSpeed(600);
  my.setSpeed(600); 
  newPosition(0,0);
  listCommands();
  Serial.print(F(">"));
}

void loop() 
{
  // read serial gcode
  if (Serial.available() > 0) 
  {
    rec_gcode_string = Serial.readStringUntil('\n');
    Serial.print(rec_gcode_string);
    Serial.print(F("\r\n"));
    processCommand();
    Serial.print(F(">"));
  }
}
