{**
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
*}

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, StdCtrls, jpeg, ExtDlgs, System.ImageList, Vcl.ImgList, Vcl.Buttons, CPort, CPortCtl;

type
  TmainForm = class(TForm)
    btnClear: TButton;
    btnPrint: TButton;
    btnClose: TButton;
    btnSave: TButton;
    SaveDialog: TSaveDialog;
    btnOpen: TButton;
    OpenDialog: TOpenDialog;
    DrawImage: TImage;
    ClearImage: TImage;
    BackgroundImage: TImage;
    ComLed1: TComLed;
    ComLed2: TComLed;
    ComLed3: TComLed;
    ComPort1: TComPort;
    ComTerminal1: TComTerminal;
    procedure FormCreate(Sender: TObject);
    procedure DrawImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure DrawImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DrawImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnCloseClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnPrintClick(Sender: TObject);
    procedure ComLed1Click(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure ComTerminal1StrRecieved(Sender: TObject; var Str: string);
    procedure ComLed3Click(Sender: TObject);
  private
    { Private declarations }
    IsMouseButtonDown: Boolean;
    PrevX, PrevY: Integer;
    ValueList: TStringList;
    IsBusy: boolean;
    procedure MyMoveTo(x, y: Integer);
    procedure NormalizeXY(x, y: integer; var ox, oy: integer);
    procedure DrawValues;
    function ProjectX(x: integer): integer;
    function ProjectY(y: integer): integer;
    procedure TranslateToXY(ACommand: string; var x, y: integer);
    procedure SendCommand(ACommand: string);
    procedure GoHome00;
  public
    { Public declarations }
    current_line: integer;
  end;

const
  ETCH_A_SKETCH_MAX_X = 9550;
  ETCH_A_SKETCH_MAX_Y = 6650;
var
  mainForm: TmainForm;

implementation

{$R *.dfm}
uses
  Math;

procedure TmainForm.FormCreate(Sender: TObject);
begin
  ValueList := TStringList.Create;
  DoubleBuffered := True;
  GoHome00;
  Brush.Bitmap := BackgroundImage.Picture.Bitmap;
  current_line := 0;
end;

procedure TmainForm.FormDestroy(Sender: TObject);
begin
  ValueList.Free;
  ComPort1.Close;
end;

procedure TmainForm.GoHome00;
begin
  DrawImage.Canvas.MoveTo(0, DrawImage.ClientHeight);
  current_line := 0;
  PrevX := 0;
  PrevY := 0;
  // bring cursor home
  SendCommand('G00 X0 Y0;'#13#10);
end;

procedure TmainForm.btnClearClick(Sender: TObject);
begin
  ValueList.Clear;
  DrawImage.Picture.Bitmap := ClearImage.Picture.Bitmap;
  GoHome00;
end;

procedure TmainForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TmainForm.btnOpenClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    ValueList.Clear;
    current_line := 0;
    ValueList.LoadFromFile(OpenDialog.FileName);
    DrawValues;
  end;
end;

procedure TmainForm.SendCommand(ACommand: string);
begin
  if ComPort1.Connected then
  begin
    ComPort1.WriteStr(ACommand);
    IsBusy := true;;
  end;
end;

procedure TmainForm.btnPrintClick(Sender: TObject);
begin
  ComPort1.Open;
  GoHome00;
end;

procedure TmainForm.btnSaveClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    ValueList.SaveToFile(SaveDialog.FileName);
end;

procedure TmainForm.ComLed1Click(Sender: TObject);
begin
  ComPort1.ShowSetupDialog;
end;

procedure TmainForm.ComLed3Click(Sender: TObject);
begin
  ComTerminal1.Visible := not ComTerminal1.Visible;
end;

procedure TmainForm.ComTerminal1StrRecieved(Sender: TObject; var Str: string);
var
  NextCommand: string;
  lx, ly: integer;
begin
  if str.Contains('>') then
  begin
    begin
      if (current_line < ValueList.Count) then
      begin
        //sleep(10);
        TranslateToXY(ValueList[current_line], lx, ly);
        NextCommand := string.Join(' ', ['G00', 'X'+ProjectX(lx).ToString, 'Y'+ProjectY(ly).ToString]) + ';'#13#10;
        SendCommand(NextCommand);
        Inc(current_line);
      end
    end;
  end;
end;

procedure TmainForm.DrawImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not IsMouseButtonDown then
  begin
    if (x <> PrevX) or (y <> PrevY) then
      MyMoveTo(x, y);
    IsMouseButtonDown := true;
  end;
end;

procedure TmainForm.DrawImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  caption := 'x:' + x.ToString + ',y:' + (ClientHeight - y).ToString;
  if IsMouseButtonDown then
  begin
    if (x <> PrevX) or (y <> PrevY) then
      MyMoveTo(x, y);
  end;
end;

procedure TmainForm.DrawImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  IsMouseButtonDown := false;
  if (x <> PrevX) or (y <> PrevY) then
    MyMoveTo(x, y);
end;

procedure TmainForm.DrawValues;
var
  I: Integer;
  lx, ly: integer;
begin
  for I := 0 to ValueList.Count - 1 do
  begin
    TranslateToXY(ValueList[I], lx, ly);
    ly := DrawImage.ClientHeight - ly;
    if I = 0 then
      DrawImage.Canvas.MoveTo(lx, ly)
    else
    begin
      DrawImage.Canvas.LineTo(lx, ly);
      DrawImage.Canvas.MoveTo(lx, ly);
    end;
  end;
end;

procedure TmainForm.MyMoveTo(x, y: Integer);
begin
  NormalizeXY(x, y, PrevX, PrevY);
  DrawImage.Canvas.LineTo(PrevX, PrevY);
  DrawImage.Canvas.MoveTo(PrevX, PrevY);
  // Here save the values of x, y to be sent to the cnc
  ValueList.Add('X' + PrevX.ToString + ',Y' + (DrawImage.ClientHeight - PrevY).ToString + ';');
end;

procedure TmainForm.NormalizeXY(x, y: integer; var ox, oy: integer);
begin
  ox := ifthen(x < 5, 5, x);
  oy := ifthen(y < 5, 5, y);
  ox := ifthen(ox > DrawImage.ClientWidth - 5, DrawImage.ClientWidth - 5, ox);
  oy := ifthen(oy > DrawImage.ClientHeight - 5, DrawImage.ClientHeight - 5, oy);
end;

function TmainForm.ProjectX(x: integer): integer;
begin
  result := Round((ETCH_A_SKETCH_MAX_X / DrawImage.ClientWidth) * x);
end;

function TmainForm.ProjectY(y: integer): integer;
begin
  result := Round((ETCH_A_SKETCH_MAX_Y / DrawImage.ClientHeight) * y);
end;

procedure TmainForm.TranslateToXY(ACommand: string; var x, y: integer);
var
  Splitted: TArray<String>;
begin
  Splitted := ACommand.Split([',', ';']);
  x := Splitted[0].TrimLeft(['X']).ToInteger;
  y := Splitted[1].TrimLeft(['Y']).ToInteger;
end;

end.

