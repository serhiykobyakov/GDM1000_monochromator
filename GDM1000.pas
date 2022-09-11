unit GDM1000;
{
Carl Zeiss GDM1000 monochromator unit
Version 11.09.2022

(c) Serhiy Kobyakov
}

interface

uses
  Classes, SysUtils, dialogs, StdCtrls, Controls, Forms,
//  strutils,
  Math,
  IniFiles,
  addfunc,
  ArduinoDevice;


type
// change it!

  { GDM_device }

  GDM_device = Object (_ArduinoDevice)
    private
      fOrder: byte;
      fPos, fMaxPos: longint;
      fMinPoscm1, fMinPoscm2, fMaxPoscm1, fMaxPoscm2: Real;

      function GetOrder: byte;
      procedure SetOrder(AValue: byte);
      function GetPos: longint;
      function GetPosCm: Real;
      function GetPosNm: Real;
      procedure SetPos(pos: longint);
      procedure GoToPos(pos: longint);
      function Pos2Cm(pos: Integer): Real;
      function Pos2Nm(pos: Integer): Real;
      function Cm2Pos(posCm: Real): Integer;
      function Nm2Pos(posNm: Real): Integer;
      function InRange(pos: Longint): boolean;
      function SendAndGet(str: string): string;
      function GetMaxPos: longint;

    public
      constructor Init(_ComPort: string);
      destructor Done;

      function GetStepRangeCm(steps: Integer): Real;
      procedure GoStepsForward(steps: Integer);
      procedure GoToCm(posCm: Real);
      procedure JumpForward;
      procedure ManualSetPos;
      function InRangeCm(posCm: Real): boolean;

      property Order: byte Read GetOrder Write SetOrder;
      property PositionCm: Real Read GetPosCm;

// preliminary nanometers mode
// it is not tested nor finished yet
      procedure GoToNm(posNm: Real);
      function InRangeNm(posNm: Real): boolean;
      property PositionNm: Real Read GetPosNm;

  end;


implementation

function GDM_device.GetOrder: byte;
begin
  Result := fOrder;
end;

procedure GDM_device.SetOrder(AValue: byte);
// set the reflection order
begin
  if (AValue = 1) or (AValue = 2) then fOrder := AValue
  else showmessage(theDeviceID + ':' + LineEnding +
                   'Wrong order: ' + IntTostr(AValue) + LineEnding +
                   'Must be 1 or 2');
end;

constructor GDM_device.Init(_ComPort: string);
var
  MyForm: TForm;
  MyLabel: TLabel;
  UpperInitStr, iniFile: string;
  AppIni: TIniFile;
begin
// -----------------------------------------------------------------------------
// first things first
// the device ID string with which it responds to '?'
  theDeviceID := 'GDM1000';
// -----------------------------------------------------------------------------

  iniFile := Application.Location + theDeviceID + '.ini';
  If not FileExists(iniFile) then
    begin
      showmessage(theDeviceID + ':' + LineEnding +
          'procedure ''' + {$I %CURRENTROUTINE%} + ''' failed!' + LineEnding +
          'File ' + iniFile + 'has not been found!' + LineEnding +
          'Please fix it');
      halt(0);
    end;

// make a splash screen
// which shows initialization process
  MyForm := TForm.Create(nil);
  with MyForm do begin
     Caption := theDeviceID + ' initialization...';
     SetBounds(0, 0, 450, 90); Position:=poDesktopCenter; BorderStyle := bsNone;
     MyForm.Color := $00EEEEEE; end;

  MyLabel := TLabel.Create(MyForm);
  with MyLabel do begin
     Autosize := True; Align := alNone; Alignment := taCenter; Parent := MyForm;
     Visible := True; AnchorVerticalCenterTo(MyForm);
     AnchorHorizontalCenterTo(MyForm); end;
  UpperInitStr := 'Initializing ' + theDeviceID + ':' + LineEnding;

  MyForm.Show; MyForm.BringToFront;
  UpperInitStr := 'Initializing ' + theDeviceID + ':' + LineEnding;

  MyLabel.Caption:= UpperInitStr + 'Reading ' + theDeviceID + '.ini...';
  sleepFor(50); // refresh the Label to see the change

// -----------------------------------------------------------------------------
// Read the device variables from ini file:
  AppIni := TInifile.Create(iniFile);
{
  theComPortSpeed := AppIni.ReadInteger(theDeviceID, 'ComPortSpeed', 115200);

// max time in ms the device may take for its internal initialization
  theInitTimeout := AppIni.ReadInteger(theDeviceID, 'InitTimeout', 3000);

// max time in ms the device may take before answer
// it is good idea to measure the longest run
// before assign the value
  theLongReadTimeout := AppIni.ReadInteger(theDeviceID, 'LongReadTimeout', 3000);

// max time in ms the device may take before answer
// in the case of simple and fast queries
  theReadTimeout := AppIni.ReadInteger(theDeviceID, 'ReadTimeout', 1000);
}
// device-specific paremeters:

  fMaxPos := StrToInt(AppIni.ReadString(theDeviceID, 'MaxPos', '0'));
  fMinPoscm1 := AppIni.ReadFloat(theDeviceID, 'MinPoscm1', 0);
  fMinPoscm2 := AppIni.ReadFloat(theDeviceID, 'MinPoscm2', 0);
  fMaxPoscm1 := AppIni.ReadFloat(theDeviceID, 'MaxPoscm1', 0);
  fMaxPoscm2 := AppIni.ReadFloat(theDeviceID, 'MaxPoscm2', 0);
  AppIni.Free;

// check if we managed to read the data from ini file:
  if fMinPoscm1 = 0 then
    begin
      showmessage(theDeviceID + ':' + LineEnding +
                  'Error reading ' + LineEnding + iniFile + LineEnding +
                  'Please fix it');
      halt(0);
    end;
// -----------------------------------------------------------------------------

  fOrder := 1;

// Use basic device initialization
  MyLabel.Caption:= UpperInitStr + 'Connecting to ' + _ComPort + '...';
  sleepFor(200); // refresh the Label to see the change
  Inherited Init(_ComPort);

  MyLabel.Caption:= UpperInitStr + 'Done!';
  sleepFor(300); // refresh the Label just to see "Done"
  MyForm.Close;
  FreeAndNil(MyForm);
end;

destructor GDM_device.Done;
begin
  Inherited Done;
end;

procedure GDM_device.GoStepsForward(steps: Integer);
// jump forward for certain number of steps
begin
  GoToPos(fPos + steps);
end;


procedure GDM_device.GoToPos(pos: longint);
// go to exact position (motor positions)
var
  answer: Longint;
begin
  if (pos <= fMaxPos) then
    begin
      answer := StrToInt(Trim(SendAndGetAnswer('g' + IntToStr(pos))));
      if answer <> pos then
              showmessage(theDeviceID + ':' + LineEnding +
                          'sent: ' + 'g' + InttoStr(pos)+ LineEnding +
                          'got answer: ' + IntToStr(answer))
      else fPos := answer;
    end;
end;

procedure GDM_device.GoToCm(posCm: Real);
// go to exact position (cm-1)
begin
  if InRangeCm(posCm) then
      GoToPos(Cm2Pos(posCm))
  else
    showmessage(theDeviceID + ':' + LineEnding +
                'procedure: GoToCm' + LineEnding +
                'argument out of range: ' + FloatToStr(posCm)+ ' cm-1');
end;

procedure GDM_device.GoToNm(posNm: Real);
// go to exact position (nm)
begin
  if InRangeNm(posNm) then
      GoToPos(Nm2Pos(posNm))
  else
    showmessage(theDeviceID + ':' + LineEnding +
                'procedure: GoToNm' + LineEnding +
                'argument out of range: ' + FloatToStr(posNm)+ ' nm');
end;


procedure GDM_device.SetPos(pos: longint);
// set GDM1000 position (motor positions)
// no motor motion, just set current position
var
  answer: string;
begin
  if (pos <= fMaxPos) then
    begin
      fPos := pos;
      answer := Trim(SendAndGetAnswer('s' + InttoStr(pos)));
      if StrToInt(answer) <> pos then
        showmessage(theDeviceID + ':' + LineEnding +
                    'sent: ' + 's' + InttoStr(pos)+ LineEnding +
                    'got answer: ' + answer);
    end;
end;

procedure GDM_device.JumpForward;
// jump one step forward
// it is inevitable to set the device position precisely
begin
  fPos := StrToInt(Trim(SendCharAndGetAnswer('j')));
end;

procedure GDM_device.ManualSetPos;
// Initialization of the device!
// set position manually
// also very useful in changing the device position,
// allow to skip manual crank rotation when setting the device!!!
var
  posNow, posTogo: Integer;
  posCmNow, posCmTogo: Real;
begin
  repeat
    posCmNow := Str2Float(InputBox(theDeviceID,
      'Type in actual monochromator position from first scale',
      IntToStr(Round(GetPosCm))));
  until (posCmNow >= fMinPoscm1) and (posCmNow <= fMaxPoscm1);
  Application.ProcessMessages;

  posNow := Cm2Pos(posCmNow);
  if posNow <> fPos then SetPos(posNow);

  repeat
    posCmTogo := Str2Float(InputBox(theDeviceID,
      'Type the destination position', '7500'));
  until (posCmTogo >= fMinPoscm1) and (posCmTogo <= fMaxPoscm1);
  Application.ProcessMessages;

  posTogo := Cm2Pos(posCmTogo);
  if posTogo <> posNow then GoToPos(posTogo);
end;

function GDM_device.Pos2Cm(pos: Integer): Real;
// convert stepper position to cm-1
// (17550 - 7500)/208307 = 0.048246098306826
begin
  if fOrder = 1 then
    Result := 7500 + pos*0.048246098306826
  else if fOrder = 2 then
  Result := 2*(7500 + pos*0.048246098306826)
  else Result := 0;
end;

function GDM_device.Pos2Nm(pos: Integer): Real;
begin
  Result := 1e7 / Pos2Cm(pos);
end;

function GDM_device.Cm2Pos(posCm: Real): Integer;
// convert stepper position in cm-1
begin
  if posCm > 0 then
    if fOrder = 1 then
      Result := Round((posCm - 7500) / 0.048246098306826)
    else if fOrder = 2 then
      Result := Round((posCm - 15000) / ( 2 * 0.048246098306826))
  else Result := 1;
end;

function GDM_device.Nm2Pos(posNm: Real): Integer;
// convert stepper position in nm
begin
  if posNm > 0 then
    if fOrder = 1 then
      Result := Round((1e7 / posNm - 7500) / 0.048246098306826)
    else if fOrder = 2 then
      Result := Round((1e7 / posNm - 15000) / ( 2 * 0.048246098306826))
    else Result := 1
  else Result := 1;
end;

function GDM_device.GetPos: longint;
// Return actual position in stepper steps
begin
  Result := fPos;
end;

function GDM_device.GetPosCm: Real;
// Return actual position in cm-1
begin
  Result := RoundTo(Pos2Cm(fPos), -2);
end;


function GDM_device.GetPosNm: Real;
// Return actual position in nm
begin
  Result := RoundTo(1e7 / Pos2Cm(fPos), -3);
end;

function GDM_device.GetMaxPos: longint;
begin
  Result := fMaxPos;
end;

function GDM_device.InRange(pos: Longint): boolean;
// check if the pos value in the range
begin
  if (pos >= 0) and (pos <= fMaxPos) then Result := True
  else Result := False;
end;

function GDM_device.InRangeCm(posCm: Real): boolean;
// check if the posCm value in the range
begin
  if fOrder = 1 then
    if (posCm >= fMinPoscm1) and (posCm <= fMaxPoscm1) then Result := True
    else Result := False
  else
    if (posCm >= fMinPoscm2) and (posCm <= fMaxPoscm2) then Result := True
    else Result := False;
end;

function GDM_device.InRangeNm(posNm: Real): boolean;
// check if the posNm value in the range
begin
  if fOrder = 1 then
    if (posNm <= 1e7 / fMinPoscm1) and (posNm >= 1e7 / fMaxPoscm1) then Result := True
    else Result := False
  else
    if (posNm <= 1e7 / fMinPoscm2) and (posNm >= 1e7 / fMaxPoscm2) then Result := True
    else Result := False;
end;

function GDM_device.GetStepRangeCm(steps: Integer): Real;
begin
  if steps > 0 then
    Result := RoundTo(Pos2Cm(steps) - Pos2Cm(0), -2)
  else Result := 0;
end;

function GDM_device.SendAndGet(str: string): string;
begin
  Result := SendAndGetAnswer(str);
end;

end.


