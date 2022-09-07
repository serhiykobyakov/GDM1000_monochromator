// GDM1000
// -*- mode: C++ -*-
//
// Copyright (C) 2019 Serhiy Kobyakov
// $Id:  $
#include <AccelStepper.h>

// Stepper motor
#define microstep 2
#define TheSpeed 600*microstep
#define TheAcceleration 220*microstep
const int BackLash = 70*microstep; // Backlash of the stepper gear

// Arduino pins
#define stepper_DIR_PIN 3
#define stepper_STEP_PIN 2
#define L_end 5  // Left endstop
#define R_end 4  // Right endstop
#define Buzzer 6

String gotData = "";

// Define the stepper and the pins it will use
AccelStepper stepper(AccelStepper::DRIVER, stepper_STEP_PIN, stepper_DIR_PIN);


void setup()
{
  digitalWrite(Buzzer, HIGH);
  
  stepper.setMaxSpeed(TheSpeed);
  stepper.setAcceleration(TheAcceleration);
  
  Serial.begin(115200);
  //while (!Serial);
    
  delay(20);
  digitalWrite(Buzzer, LOW); 
  if (digitalRead(R_end) || digitalRead(L_end)) HitEndstop();
//  Serial.println("Ready!");
}

void beepn(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(Buzzer, HIGH);
    delay(100);
    digitalWrite(Buzzer, LOW);
    delay(100);
  }
}

void beepE(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(Buzzer, HIGH);
    delay(400);
    digitalWrite(Buzzer, LOW);
    delay(400);
  }
}

void goTo() {
  if (Serial.available() > 0) {
    gotData = Serial.readStringUntil('\n');
    long pos = gotData.toInt();
    if (pos != stepper.currentPosition()) {
      if (pos <= stepper.currentPosition()) {
      // if we have to go backwards - go BackLash further
        stepper.moveTo(pos - BackLash);
        while (stepper.distanceToGo() != 0) {
          if (digitalRead(R_end) || digitalRead(L_end)) { HitEndstop(); break; }            
          stepper.run(); }
        delay(500);
      }  // end of go backwards
      stepper.moveTo(pos);
      while (stepper.distanceToGo() != 0) {
        if (digitalRead(R_end) || digitalRead(L_end)) { HitEndstop(); break; }
        stepper.run(); }
    } // end of pos != current position
  } // end of Serial.available() > 0
}

void HitEndstop() {
  stepper.stop();
  stepper.setSpeed(0);
  stepper.setCurrentPosition(0);
  stepper.moveTo(0);
  beepE(2);
/*  
  if (Serial.available() > 0) {
    Serial.readStringUntil('\n');
    if (digitalRead(R_end)) Serial.println("R");
    if (digitalRead(L_end)) Serial.println("L");
  }
  */
}

void loop() {
  if (digitalRead(R_end) || digitalRead(L_end)) HitEndstop();

  if (Serial.available() > 0 ) { 
    char data_in = (char) Serial.read();
    switch (data_in) {
      // "?" - identification
      case '?':
        delay(4);
        Serial.println("GDM1000");
        break;

      // "g" - go to position
      case 'g':
        delay(4);      
        goTo();
        Serial.println(stepper.currentPosition());
        break;

      // "p" - get position
      case 'p':
        delay(4);
        Serial.println(stepper.currentPosition());
        break;

      // "j" - jump one step forward
      case 'j':
        delay(4);
        stepper.setMaxSpeed(20000);
        stepper.setAcceleration(10000);
        stepper.move(1);
        while (stepper.distanceToGo() != 0) {
          stepper.runSpeed(); } 
        stepper.setMaxSpeed(TheSpeed);
        stepper.setAcceleration(TheAcceleration);
        Serial.println(stepper.currentPosition());
        break;

      // "s" - set position
      case 's':
        delay(4);
        gotData = Serial.readStringUntil('\n');
        stepper.setCurrentPosition(gotData.toInt());        
        Serial.println(stepper.currentPosition());
        break;

      default:
        break;  
    }
  }
}
