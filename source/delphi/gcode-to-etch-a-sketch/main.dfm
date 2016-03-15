object mainForm: TmainForm
  Left = 0
  Top = 0
  Caption = 'mainForm'
  ClientHeight = 810
  ClientWidth = 938
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 176
    Width = 29
    Height = 13
    Caption = 'Max X'
  end
  object Label2: TLabel
    Left = 136
    Top = 176
    Width = 29
    Height = 13
    Caption = 'Max Y'
  end
  object Label3: TLabel
    Left = 463
    Top = 9
    Width = 11
    Height = 16
    Caption = '<'
    Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object Label4: TLabel
    Left = 9
    Top = 9
    Width = 11
    Height = 16
    Caption = '>'
    Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object ImagePreview: TImage
    Left = 23
    Top = 204
    Width = 900
    Height = 600
  end
  object Memo1: TMemo
    Left = 24
    Top = 6
    Width = 433
    Height = 161
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
    WordWrap = False
  end
  object ComTerminal1: TComTerminal
    Left = 482
    Top = 6
    Width = 441
    Height = 161
    Color = clBlack
    ComPort = ComPort1
    Emulation = teNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Fixedsys'
    Font.Style = []
    Rows = 9
    ScrollBars = ssBoth
    TabOrder = 1
    OnStrRecieved = ComTerminal1StrRecieved
  end
  object Button1: TButton
    Left = 848
    Top = 173
    Width = 75
    Height = 25
    Caption = 'Print'
    TabOrder = 2
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 382
    Top = 173
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 3
    OnClick = Button2Click
  end
  object MaxXEdit: TEdit
    Left = 56
    Top = 173
    Width = 57
    Height = 21
    NumbersOnly = True
    TabOrder = 4
    Text = '0'
  end
  object MaxYEdit: TEdit
    Left = 168
    Top = 173
    Width = 57
    Height = 21
    NumbersOnly = True
    TabOrder = 5
    Text = '0'
  end
  object ButtonPreview: TButton
    Left = 720
    Top = 173
    Width = 75
    Height = 25
    Caption = 'Peview'
    TabOrder = 6
    OnClick = ButtonPreviewClick
  end
  object CheckBoxEtchASketch: TCheckBox
    Left = 248
    Top = 175
    Width = 97
    Height = 17
    Caption = 'Etch-A-Sketch'
    Checked = True
    State = cbChecked
    TabOrder = 7
  end
  object ComPort1: TComPort
    BaudRate = br57600
    Port = 'COM6'
    Parity.Bits = prNone
    StopBits = sbOneStopBit
    DataBits = dbEight
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full]
    FlowControl.OutCTSFlow = False
    FlowControl.OutDSRFlow = False
    FlowControl.ControlDTR = dtrDisable
    FlowControl.ControlRTS = rtsDisable
    FlowControl.XonXoffOut = False
    FlowControl.XonXoffIn = False
    StoredProps = [spBasic]
    TriggersOnRxChar = False
    Left = 288
    Top = 46
  end
  object OpenTextFileDialog1: TOpenTextFileDialog
    Left = 384
    Top = 46
  end
end
