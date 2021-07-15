object frmWin2048: TfrmWin2048
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Win2048'
  ClientHeight = 316
  ClientWidth = 276
  Color = 10530235
  Constraints.MinWidth = 282
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object grid: TStringGrid
    Left = 0
    Top = 0
    Width = 276
    Height = 276
    Margins.Left = 0
    Margins.Top = 0
    Margins.Right = 0
    Margins.Bottom = 0
    TabStop = False
    BorderStyle = bsNone
    Color = clWhite
    ColCount = 4
    DefaultRowHeight = 64
    DrawingStyle = gdsGradient
    Enabled = False
    FixedCols = 0
    RowCount = 4
    FixedRows = 0
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    GradientEndColor = clGreen
    GridLineWidth = 5
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine]
    ParentFont = False
    ScrollBars = ssNone
    TabOrder = 0
    OnDrawCell = DrawCell
  end
  object pnlScore: TPanel
    Left = 0
    Top = 276
    Width = 276
    Height = 20
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    Color = 10530235
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
  end
  object pnlBest: TPanel
    Left = 0
    Top = 296
    Width = 276
    Height = 20
    Align = alBottom
    Alignment = taLeftJustify
    BevelOuter = bvNone
    Color = 10530235
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 2
  end
  object MainMenu1: TMainMenu
    OwnerDraw = True
    Left = 128
    Top = 160
    object mnuGame: TMenuItem
      Caption = 'Game'
      object mnuNew: TMenuItem
        Caption = '&New'
        ShortCut = 16462
        OnClick = mnuNewClick
      end
      object mnuExit: TMenuItem
        Caption = 'E&xit'
        OnClick = mnuExitClick
      end
    end
    object mnuDifficulty: TMenuItem
      Caption = 'Difficulty'
      object mnuStandard: TMenuItem
        AutoCheck = True
        Caption = '&Standard (4x4 - 2048)'
        Default = True
        RadioItem = True
        OnClick = mnuStandardClick
      end
      object mnuCustom: TMenuItem
        AutoCheck = True
        Caption = 'Custom'
        RadioItem = True
        object mnuSize: TMenuItem
          Caption = 'Size'
        end
        object mnuWinValue: TMenuItem
          Caption = 'Win value'
        end
      end
    end
  end
end
