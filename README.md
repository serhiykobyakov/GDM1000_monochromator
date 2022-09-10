# Carl Zeiss GDM1000 monochromator automatization

![Alt Text](https://github.com/serhiykobyakov/GDM1000_monochromator/blob/main/GDM1000.jpg)

## What is it

Long story short: I attached a stepper motor to monochromator and now it can be positioned using PC instead of old-fashion manual control.

Here I have only the software without all the other stuff (circuitry and mechanic stuff). Arduino sketch and Free Pascal unit for GDM1000 monochromator.

The software has been tested for errors, stability and speed.

## Install

### Arduino

1. Make directory "GDM1000" in the sketchbook directory on your PC (it is "Arduino" by default, check the preferences in Arduino IDE).
2. Put the GDM1000.ino into "GDM1000" directory.
3. Open Arduino IDE and set your Arduino board
4. Check the sketch for errors and upload the sketch to the board.

### Free Pascal

1. Download GDM1000.pas and GDM1000.ini
2. Get ArduinoDevice.pas from [my Arduino device repository](https://github.com/serhiykobyakov/Arduino_device_FPC) 
3. Use repository info and and see the comments in files to get it work

## Contact
For reporting [bugs, suggestions, patches](https://github.com/serhiykobyakov/GDM1000_monochromator_automatization/issues)

## License
The project is licensed under the [MIT license](https://github.com/serhiykobyakov/GDM1000_monochromator_automatization/blob/main/LICENSE)
