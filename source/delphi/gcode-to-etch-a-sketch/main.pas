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
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, CPortCtl, CPort, Vcl.StdCtrls,
  Vcl.ExtDlgs, Vcl.ExtCtrls;

const
  ETCH_A_SKETCH_MAX_X = 9050;
  ETCH_A_SKETCH_MAX_Y = 6150;
  CRAZY_VALUE         = -1234567890;

type
  TmainForm = class(TForm)
    Memo1: TMemo;
    ComPort1: TComPort;
    ComTerminal1: TComTerminal;
    Button1: TButton;
    OpenTextFileDialog1: TOpenTextFileDialog;
    Button2: TButton;
    MaxXEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    MaxYEdit: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    ImagePreview: TImage;
    ButtonPreview: TButton;
    CheckBoxEtchASketch: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure ComTerminal1StrRecieved(Sender: TObject; var Str: string);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonPreviewClick(Sender: TObject);
  private
    { Private declarations }
    max_x, max_y: double;
    prev_x, prev_y: integer;
  public
    { Public declarations }
    current_line: integer;
    procedure SendCommand(ACommand: string);
    function ReadXYZ(s: string; c: char): double;
    function ProjectX(x: double; maxprintx: integer = ETCH_A_SKETCH_MAX_X): integer;
    function ProjectY(y: double; maxprinty: integer = ETCH_A_SKETCH_MAX_Y): integer;
  end;

var
  mainForm: TmainForm;

implementation

{$R *.dfm}

procedure TmainForm.Button1Click(Sender: TObject);
begin
  ComPort1.ShowSetupDialog;
  max_x := string(MaxXEdit.Text).ToInteger();
  max_y := string(MaxYEdit.Text).ToInteger();
  ComPort1.Open;
  SendCommand('G00 X0 Y0;'#13#10);
end;

procedure TmainForm.Button2Click(Sender: TObject);
var
  I: Integer;
  x, y: double;
begin
  max_x := 0;
  max_y := 0;
  if OpenTextFileDialog1.Execute then
    Memo1.Lines.LoadFromFile(OpenTextFileDialog1.FileName);
  for I := 0 to Memo1.Lines.Count - 1 do
  begin
    x := ReadXYZ(Memo1.Lines[i], 'X');
    y := ReadXYZ(Memo1.Lines[i], 'Y');
    if x > max_x then
      max_x := x;
    if y > max_y then
      max_y := y;
  end;
  MaxXEdit.Text := Round(max_x).ToString;
  MaxYEdit.Text := Round(max_y).ToString;
end;

procedure TmainForm.ButtonPreviewClick(Sender: TObject);
var
  x, y, z: double;
  I: Integer;
  Z_in_material: boolean;
begin
  ImagePreview.Canvas.Pen.Color := clBlack;
  Z_in_material := false;
  max_x := string(MaxXEdit.Text).ToInteger();
  max_y := string(MaxYEdit.Text).ToInteger();
  ImagePreview.Canvas.FillRect(Rect(0,0,ImagePreview.Width,ImagePreview.Height));
  for I := 0 to memo1.Lines.Count - 1 do
  begin
    if (not Memo1.Lines[i].StartsWith('G0')) and (not Memo1.Lines[i].StartsWith('G1')) then
      continue;

    x := ReadXYZ(memo1.Lines[i], 'X');
    y := ReadXYZ(memo1.Lines[i], 'Y');

    if x > CRAZY_VALUE then
      prev_x := ProjectX(x, ImagePreview.Width);
    if y > CRAZY_VALUE then
      prev_y := ProjectY(y, ImagePreview.Height);

    z := ReadXYZ(memo1.Lines[i], 'Z');
    if z > CRAZY_VALUE then
      Z_in_material := z < 0;

    if Z_in_material or CheckBoxEtchASketch.Checked then
    begin
      ImagePreview.Canvas.LineTo(prev_x, ImagePreview.ClientHeight - prev_y);
      ImagePreview.Canvas.MoveTo(prev_x, ImagePreview.ClientHeight - prev_y);
    end
    else
      ImagePreview.Canvas.MoveTo(prev_x, ImagePreview.ClientHeight - prev_y);
  end;
end;

procedure TmainForm.ComTerminal1StrRecieved(Sender: TObject; var Str: string);
var
  x, y: double;
  command: string;
begin
  ImagePreview.Canvas.Pen.Color := clRed;
  if str.Contains('>') then
  begin
    begin
      if (current_line < memo1.Lines.Count) then
      begin
        while (not Memo1.Lines[current_line].StartsWith('G0')) and
              (not Memo1.Lines[current_line].StartsWith('G1')) and
              (current_line < memo1.Lines.Count-1) do
          inc(current_line);

        x := ReadXYZ(memo1.Lines[current_line], 'X');
        y := ReadXYZ(memo1.Lines[current_line], 'Y');

        // -- start preview
        if x > CRAZY_VALUE then
          prev_x := ProjectX(x, ImagePreview.Width);
        if y > CRAZY_VALUE then
          prev_y := ProjectY(y, ImagePreview.Height);

        ImagePreview.Canvas.LineTo(prev_x, ImagePreview.ClientHeight - prev_y);
        ImagePreview.Canvas.MoveTo(prev_x, ImagePreview.ClientHeight - prev_y);
        // -- end preview

        command := 'G00';
        if x > CRAZY_VALUE then
          command := command + ' X' + ProjectX(x).ToString;
        if y > CRAZY_VALUE then
          command := command + ' Y' + ProjectY(y).ToString;
        command := command + ';';

        SendCommand(command + #13#10);
        Inc(current_line);
      end
    end;
  end;
  SendMessage(Memo1.Handle, WM_VSCROLL, SB_LINEDOWN, current_line);
  Caption := 'Current: ' + current_line.ToString() + ', of total: ' + Memo1.Lines.Count.ToString;
end;

procedure TmainForm.FormCreate(Sender: TObject);
begin
  caption := ReadXYZ('G1 X84.552536 Y200.890578 Z-0.500013', 'Z').ToString;
end;

procedure TmainForm.FormDestroy(Sender: TObject);
begin
  try
    ComPort1.Close;
  except
  end;
end;

function TmainForm.ReadXYZ(s: string; c: char): double;
var
  Splitted: TArray<String>;
  I: integer;
begin
  result := CRAZY_VALUE;
  if s.Contains(' ' + c) then
  begin
    Splitted := s.Split([' ', ';']);
    for I := 0 to Length(Splitted) - 1  do
    begin
      if Splitted[I].Contains(c) then
        result := Round(Splitted[I].TrimLeft([c]).ToDouble);
    end;
  end
end;

procedure TmainForm.SendCommand(ACommand: string);
begin
  if ComPort1.Connected then
  begin
    ComPort1.WriteStr(ACommand);
  end;
end;

function TmainForm.ProjectX(x: double; maxprintx: integer): integer;
begin
  result := Round((maxprintx / max_x) * x);
end;

function TmainForm.ProjectY(y: double; maxprinty: integer): integer;
begin
  result := Round((maxprinty / max_y) * y);
end;

end.
