unit u2048;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Math, System.IniFiles, System.Types, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Menus;

type
  TTile = class
  strict private
    FMerged: boolean;
    FValue: cardinal;
  public
    constructor Create;
    procedure Merge;
    property Merged: boolean read FMerged write FMerged;
    property Value: cardinal read FValue;
  end;

  TTileRow = array of TTile;
  TTileArray = array of TTileRow;

  TDirectionX = (dxLeft, dxRight);
  TDirectionY = (dyUp, dyDown);

  ECorruptSavegame = class(Exception);

type
  TfrmWin2048 = class(TForm)
    grid: TStringGrid;
    pnlScore: TPanel;
    pnlBest: TPanel;
    MainMenu1: TMainMenu;
    mnuGame: TMenuItem;
    mnuExit: TMenuItem;
    mnuNew: TMenuItem;
    mnuDifficulty: TMenuItem;
    mnuCustom: TMenuItem;
    mnuSize: TMenuItem;
    mnuWinValue: TMenuItem;
    mnuStandard: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
    procedure mnuNewClick(Sender: TObject);
    procedure mnuSetSquareSize(Sender: TObject);
    procedure mnuSetWinValue(Sender: TObject);
    procedure mnuStandardClick(Sender: TObject);
  private
    FScore,
    FBest: cardinal;
    FKeepPlaying,
    FMoved_Or_Merged,
    FNewGame: boolean;
    FSquareCount: byte;
    FTileArray: TTileArray;
    FWinValue: cardinal;
    procedure AddTile;
    function CheckPlayerHasWon: boolean;
    function CheckTurnsLeft: boolean;
    procedure ClearTileArray;
    procedure InitTileArray;
    function LoadGame: boolean;
    procedure MoveAndMerge(x1, y1, x2, y2: integer);
    procedure MoveX(DirectionX: TDirectionX);
    procedure MoveY(DirectionY: TDirectionY);
    procedure ResetGame;
    procedure SaveGame;
    procedure SetFormCaption;
    procedure SetGridSize;
    procedure ShowTileArray;
    procedure ShuffleFreeTiles<T>(list: TList<T>);
  public
    { Public-Deklarationen }
  end;

var
  frmWin2048: TfrmWin2048;

implementation

{$R *.dfm}

const
  APP_NAME = 'Win2048';
  INI_FILENAME = APP_NAME + '.ini';
  SAVEGAME_FILENAME = APP_NAME + '.save';
  MIN_SQUARECOUNT = 2;
  MIN_WINVALUE = 4;

function GetApplicationDir: string;
begin
  result := ExtractFilePath(ParamStr(0));
end;

function IsMultibleOfTwo(Value: cardinal): boolean;
var
  bit_is_set: boolean;
begin
  result := false;
  bit_is_set := false;

  while Value > 0 do
  begin
    if Value and 1 = 1 then
    begin
      if not bit_is_set then
        bit_is_set := true
      else
        exit;
    end;

    Value := Value shr 1;
  end;

  result := true;
end;

{ TTile }

constructor TTile.Create;
begin
  FValue := 2;
  FMerged := false;
end;

procedure TTile.Merge;
begin
  Inc(FValue, FValue);
  FMerged := true;
end;

{ TfrmWin2048 }

procedure TfrmWin2048.AddTile;
var
  i, x, y: integer;
  FFreeTilesList: TList<TPoint>;
begin
  Randomize;
  FFreeTilesList := TList<TPoint>.Create;

  try
    for x := Low(FTileArray) to High(FTileArray) do
    begin
      for y := Low(FTileArray[x]) to High(FTileArray[x]) do
      begin
        if not Assigned(FTileArray[x, y]) then
          FFreeTilesList.Add(TPoint.Create(x, y));
      end;
    end;

    if FFreeTilesList.Count > 0 then
    begin
      if FFreeTilesList.Count > 1 then
      begin
        i := Random(FFreeTilesList.Count);
        ShuffleFreeTiles<TPoint>(FFreeTilesList);
      end
      else
        i := 0;

      FTileArray[FFreeTilesList[i].X, FFreeTilesList[i].Y] := TTile.Create;

      // zufällig eine 4er-Kachel erzeugen
      if CompareValue(Random, 0.9) = GreaterThanValue then
      begin
        FTileArray[FFreeTilesList[i].X, FFreeTilesList[i].Y].Merge;
        FTileArray[FFreeTilesList[i].X, FFreeTilesList[i].Y].Merged := false;
      end;
    end;
  finally
    FFreeTilesList.Free;
  end;
end;

function TfrmWin2048.CheckPlayerHasWon: boolean;
var
  tile: TTile;
  tilerow: TTileRow;
begin
  result := false;

  for tilerow in FTileArray do
  begin
    for tile in tilerow do
    begin
      result := Assigned(tile) and (tile.Value >= FWinValue);

      if result then
        exit;
    end;
  end;
end;

function TfrmWin2048.CheckTurnsLeft: boolean;
var
  x, y: integer;
  tile: TTile;
  tilerow: TTileRow;
begin
  result := false;

  // look for free tiles
  for tilerow in FTileArray do
  begin
    for tile in tilerow do
    begin
      if not Assigned(tile) then
      begin
        result := true;
        exit;
      end;
    end;
  end;

  // look for possible merges
  for x := Low(FTileArray) to High(FTileArray) - 1 do
  begin
    for y := Low(FTileArray[x]) to High(FTileArray[x]) do
    begin
      if Assigned(FTileArray[x, y])
        and Assigned(FTileArray[x + 1, y])
        and (FTileArray[x, y].Value = FTileArray[x + 1, y].Value)
      then
      begin
        result := true;
        exit;
      end;
    end;
  end;

  for x := Low(FTileArray) to High(FTileArray) do
  begin
    for y := Low(FTileArray[x]) to High(FTileArray[x]) - 1 do
    begin
      if Assigned(FTileArray[x, y])
        and Assigned(FTileArray[x, y + 1])
        and (FTileArray[x, y].Value = FTileArray[x, y + 1].Value)
      then
      begin
        result := true;
        exit;
      end;
    end;
  end;
end;

procedure TfrmWin2048.ClearTileArray;
var
  x, y: integer;
begin
  for x := Low(FTileArray) to High(FTileArray) do
    for y := Low(FTileArray[x]) to High(FTileArray[x]) do
      FreeAndNil(FTileArray[x, y]);
end;

procedure TfrmWin2048.FormCreate(Sender: TObject);
  procedure AddMenuItemDrawEvent(MenuItem: TMenuItem);
  var
    ChildMenuItem: TMenuItem;
  begin
    for ChildMenuItem in MenuItem do
      AddMenuItemDrawEvent(ChildMenuItem);

    MenuItem.OnDrawItem := mnuDrawItem;
  end;
var
  GridRect: TGridRect;
  savegame_loaded: boolean;
  MenuItem: TMenuItem;
  i: integer;
begin
  savegame_loaded := LoadGame;

  if not savegame_loaded then
  begin
    FBest := 0;

    with TIniFile.Create(GetApplicationDir + INI_FILENAME) do
    begin
      try
        FSquareCount := ReadInteger('Game', 'SquareCount', 4);
        FWinValue := ReadInteger('Game', 'WinValue', 2048);
      finally
        Free;
      end;
    end;

    InitTileArray;
  end
  else
  begin
    if CheckPlayerHasWon then
      FKeepPlaying := true;

    FNewGame := false;
  end;

  // GUI vorbereiten
  mnuStandard.Checked := (FSquareCount = 4) and (FWinValue = 2048);

  // Menüeinträge erstellen zur Auswahl des Spielziels
  for i := 3 to 17 do
  begin
    MenuItem := TMenuItem.Create(MainMenu1);
    MenuItem.AutoCheck := true;
    MenuItem.RadioItem := true;
    MenuItem.Tag := Trunc(IntPower(2, i));
    MenuItem.Name := 'mnuWinValue_' + IntToStr(MenuItem.Tag);
    MenuItem.Caption := IntToStr(MenuItem.Tag);

    if MenuItem.Tag = 2048 then
      MenuItem.Default := true;

    if not mnuStandard.Checked
      and (MenuItem.Tag = FWinValue)
    then
    begin
      MenuItem.Checked := true;
      mnuCustom.Checked := true;
    end;

    mnuWinValue.Add(MenuItem);
  end;

  for MenuItem in mnuWinValue do
    MenuItem.OnClick := mnuSetWinValue;

  // Menüeinträge erstellen zur Auswahl der Spielfeldgröße
  for i := 2 to 10 do
  begin
    MenuItem := TMenuItem.Create(MainMenu1);
    MenuItem.AutoCheck := true;
    MenuItem.RadioItem := true;
    MenuItem.Tag := i;
    MenuItem.Name := 'mnuSize_' + IntToStr(MenuItem.Tag);
    MenuItem.Caption := IntToStr(MenuItem.Tag) + 'x' + IntToStr(MenuItem.Tag);

    if MenuItem.Tag = 4 then
      MenuItem.Default := true;

    if not mnuStandard.Checked
      and (MenuItem.Tag = FSquareCount)
    then
    begin
      MenuItem.Checked := true;
      mnuCustom.Checked := true;
    end;

    mnuSize.Add(MenuItem);
  end;


  AddMenuItemDrawEvent(MainMenu1.Items);

  for MenuItem in mnuSize do
    MenuItem.OnClick := mnuSetSquareSize;

  SetFormCaption;
  SetGridSize;

  // keine Zelle selektieren
  GridRect.Left := -1;
  GridRect.Top := -1;
  GridRect.Right := -1;
  GridRect.Bottom := -1;
  grid.Selection := GridRect;

  Randomize;

  if savegame_loaded then
    ShowTileArray
  else
    ResetGame;
end;

procedure TfrmWin2048.FormDestroy(Sender: TObject);
begin
  if not FNewGame then
    SaveGame;

  ClearTileArray;
end;

procedure TfrmWin2048.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  tile: TTile;
  tilerow: TTileRow;
begin
  FMoved_Or_Merged := false;

  case Key of
    VK_LEFT:  MoveX(dxLeft);
    VK_RIGHT: MoveX(dxRight);

    VK_UP:   MoveY(dyUp);
    VK_DOWN: MoveY(dyDown);
  end;

  if Key in [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN] then
  begin
    if FMoved_Or_Merged then
    begin
      if FNewGame then
        FNewGame := false;

      ShowTileArray;
      Self.OnKeyDown := nil;
      Sleep(20);
      Self.OnKeyDown := FormKeyDown;

      for tilerow in FTileArray do
      begin
        for tile in tilerow do
        begin
          if Assigned(tile) then
            tile.Merged := false;
        end;
      end;

      if CheckPlayerHasWon then
      begin
        if not FKeepPlaying then
        begin
          MessageDlg('You win!', mtInformation, [mbOK], 0);

          if MessageDlg('Keep playing?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
          begin
            ResetGame;
            exit;
          end
          else
            FKeepPlaying := true;
        end;
      end;


      AddTile;
      ShowTileArray;

      if not CheckTurnsLeft then
      begin
        MessageDlg('You lost!', mtError, [mbOK], 0);
        ResetGame;
      end;
    end;
  end;
end;

procedure TfrmWin2048.InitTileArray;
var
  x: integer;
begin
  SetLength(FTileArray, FSquareCount);

  for x := Low(FTileArray) to High(FTileArray) do
    SetLength(FTileArray[x], FSquareCount);
end;

function TfrmWin2048.LoadGame: boolean;
var
  stream: TFileStream;
  reader: TReader;
  s: string;
  x, y: integer;
  value: cardinal;
begin
  result := false;

  if FileExists(GetApplicationDir + SAVEGAME_FILENAME) then
  begin
    try
      stream := TFileStream.Create(GetApplicationDir + SAVEGAME_FILENAME, fmOpenRead or fmShareExclusive);
      reader := TReader.Create(stream, 2048);

      try
        s := reader.ReadString;

        if s <> APP_NAME then
          raise ECorruptSavegame.Create('program identifier wrong or not found in the savegame');

        FSquareCount := reader.ReadInteger;

        if FSquareCount < MIN_SQUARECOUNT then
          raise ECorruptSavegame.Create('square count must be equal or greater than ' + IntToStr(MIN_SQUARECOUNT));

        InitTileArray;

        FWinValue := reader.ReadInt64;

        if FWinValue < MIN_WINVALUE then
          raise ECorruptSavegame.Create('win value must be equal oder greater than ' + IntToStr(MIN_WINVALUE))
        else
        begin
          if not IsMultibleOfTwo(FWinValue) then
            raise ECorruptSavegame.Create('invalid win value: ' + IntToStr(FWinValue) + ' is not a multible of 2');
        end;


        FScore := reader.ReadInt64;
        FBest := reader.ReadInt64;

        reader.ReadListBegin;

        while not reader.EndOfList do
        begin
          x := reader.ReadInteger;
          y := reader.ReadInteger;
          value := reader.ReadInt64;

          if not IsMultibleOfTwo(Value) then
            raise ECorruptSavegame.Create('invalid tile value: ' + IntToStr(Value) + ' is not a multible of 2');

          if (x >= Low(FTileArray)) and (x <= High(FTileArray))
            and (y >= Low(FTileArray[x])) and (y <= High(FTileArray[x]))
          then
          begin
            if not Assigned(FTileArray[x, y]) then
            begin
              FTileArray[x, y] := TTile.Create;

              while FTileArray[x, y].Value < value do
              begin
                FTileArray[x, y].Merge;
                FTileArray[x, y].Merged := false;
              end;
            end
            else
              raise ECorruptSavegame.Create('duplicate tile coodinates (x ' + IntToStr(x) + '; y ' + IntToStr(y) + ')');
          end
          else
            raise ECorruptSavegame.Create('invalid tile coordinates (square count ' + IntToStr(FSquareCount) + '; x ' + IntToStr(x) + '; y ' + IntToStr(y) + ')');
        end;

        result := true;
      finally
        reader.Free;
        stream.Free;
        DeleteFile(GetApplicationDir + SAVEGAME_FILENAME);
      end;
    except
      on e:EFOpenError do
        MessageDlg('Could not open savegame! :(' + sLineBreak + '(' + e.Message + ')', mtError, [mbOK], 0);

      on e:ECorruptSavegame do
        MessageDlg('Savegame is corrupt! Starting new game...' + sLineBreak + '(' + e.Message + ')', mtError, [mbOK], 0);
    else
      raise;
    end;
  end;
end;

procedure TfrmWin2048.DrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
const
  PenWidth = 6;
var
  TextWidth, TextHeight: integer;
  tmpRect: TRect;

  procedure DrawCellWithFrame;
  begin
    TStringGrid(Sender).Canvas.Rectangle(Rect);
    TStringGrid(Sender).Canvas.FillRect(tmpRect);
  end;
begin
  if not (Sender is TStringGrid) then
    exit;

  if (ACol >= 0) and (ARow >= 0) then
  begin
    with TStringGrid(Sender) do
    begin
      Inc(Rect.Left, -4);
      Inc(Rect.Right, GridLineWidth);
      Inc(Rect.Bottom, GridLineWidth);

      tmpRect := Rect;
      Inc(tmpRect.Left, PenWidth);
      Inc(tmpRect.Top, PenWidth);
      Inc(tmpRect.Bottom, -PenWidth);
      Inc(tmpRect.Right, -PenWidth);

      Canvas.Pen.Color := $a0adbb;
      Canvas.Pen.Width := PenWidth;
      Canvas.Pen.Style := psSolid;

      if (not (gdSelected in State)) then
      begin
        if Assigned(FTileArray[ACol, ARow]) then
        begin
          case FTileArray[ACol, ARow].Value of
               //1: Canvas.Brush.Color := $dbf0f9;
               2: Canvas.Brush.Color := $dae4ee;
               4: Canvas.Brush.Color := $c8e0ed;
               8: Canvas.Brush.Color := $79b1f2;
              16: Canvas.Brush.Color := $6395f5;
              32: Canvas.Brush.Color := $5f7cf6;
              64: Canvas.Brush.Color := $3b5ef6;
             128: Canvas.Brush.Color := $72cfed;
             256: Canvas.Brush.Color := $61cced;
             512: Canvas.Brush.Color := $50c8ed;
            1024: Canvas.Brush.Color := $3fc5ed;
            2048: Canvas.Brush.Color := $2ec2ed;
          else
            Canvas.Brush.Color := $2ec2ed;
          end;

          DrawCellWithFrame;

          case FTileArray[ACol, ARow].Value of
            1, 2, 4:   Canvas.Font.Color := $656e77;
            8..512: Canvas.Font.Color := $f2f6f9;
            1024:   Canvas.Font.Color := $5f7cf6;
          else
            Canvas.Font.Color := $3b5ef6;
          end;

          if FTileArray[ACol, ARow].Value > 8192 then
          begin
            Canvas.Font.Size := Canvas.Font.Size - 3;
            Canvas.Font.Style := Canvas.Font.Style - [fsBold];
          end;

          TextWidth := Canvas.TextWidth(Cells[ACol, ARow]);
          TextHeight := Canvas.TextHeight(Cells[ACol, ARow]);

          Canvas.TextOut(Rect.Left + Rect.Width div 2 - TextWidth div 2, Rect.Top + Rect.Height div 2 - TextHeight div 2, Cells[ACol, ARow]); // den Text in der Zelle ausgeben
        end
        else
        begin
          Canvas.Brush.Color := $b4c0cd;
          DrawCellWithFrame;
        end;
      end;
    end;
  end;
end;

procedure TfrmWin2048.mnuStandardClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  for MenuItem in mnuWinValue do
  begin
    if MenuItem.Tag = 2048 then
    begin
      MenuItem.Click;
      break;
    end;
  end;

  for MenuItem in mnuSize do
  begin
    if MenuItem.Tag = 4 then
    begin
      MenuItem.Click;
      break;
    end;
  end;

  mnuStandard.Checked := true;
  mnuCustom.Caption := 'Custom';
end;

procedure TfrmWin2048.mnuDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
var
  txt: string;
begin
  if not (Sender is TMenuItem) then
    exit;

  txt := TMenuItem(Sender).Caption;

  if TMenuItem(Sender).shortcut > 0 then
    txt := txt + '     ' + shortcuttotext((Sender as TMenuItem).shortcut);

  with ACanvas do
  begin
    Brush.Color := $a0adbb;
    FillRect(ARect);

    if (TMenuItem(Sender).parent = MainMenu1.Items) then
      Inc(ARect.left, 4)
    else
      Inc(ARect.left, 20);

    if TMenuItem(Sender).Checked then
      Font.Style := Font.Style + [fsBold];

    DrawText(handle, PChar(txt), -1, Arect, DT_SingleLine or DT_VCenter);

    if TMenuItem(Sender).Checked then
    begin
      Pen.Color := clWhite;
      Rectangle(ARect.Left - 18, ARect.Top + 4, ARect.Left - 3, ARect.Top + 18);

      Brush.Color := clBlack;
      Pen.Color := Brush.Color;
      Ellipse(ARect.Left - 13, ARect.Top + 8, ARect.Left - 6, ARect.Top + 15);

//      if TMenuItem(Sender).RadioItem then
        Brush.Color := clWhite; //$dbf0f9
//      else
//        Brush.Color := $50c8ed;

      Pen.Color := Brush.Color;
      Ellipse(ARect.Left - 14, ARect.Top + 7, ARect.Left - 7, ARect.Top + 14);
    end;
  end;
end;

procedure TfrmWin2048.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmWin2048.mnuNewClick(Sender: TObject);
begin
  ResetGame;
end;

procedure TfrmWin2048.mnuSetSquareSize(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  if not (Sender is TMenuItem) then
    exit;

  if FSquareCount <> TMenuItem(Sender).Tag then
  begin
    FSquareCount := TMenuItem(Sender).Tag;
    mnuCustom.Caption := 'Custom (' + IntToStr(FSquareCount) + 'x' + IntToStr(FSquareCount) + ' - ' + IntToStr(FWinValue) + ')';

    for MenuItem in mnuWinValue do
    begin
      if (MenuItem.Tag = FWinValue)
        and not MenuItem.Checked
      then
        MenuItem.Checked := true;
    end;

    SetFormCaption;
    ClearTileArray;
    InitTileArray;
    SetGridSize;
    ResetGame;
  end;
end;

procedure TfrmWin2048.mnuSetWinValue(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  if not (Sender is TMenuItem) then
    exit;

  if FWinValue <> TMenuItem(Sender).Tag then
  begin
    FWinValue := TMenuItem(Sender).Tag;
    mnuCustom.Caption := 'Custom (' + IntToStr(FSquareCount) + 'x' + IntToStr(FSquareCount) + ' - ' + IntToStr(FWinValue) + ')';

    for MenuItem in mnuSize do
    begin
      if (MenuItem.Tag = FSquareCount)
        and not MenuItem.Checked
      then
        MenuItem.Checked := true;
    end;

    SetFormCaption;
    ResetGame;
  end;
end;

procedure TfrmWin2048.MoveAndMerge(x1, y1, x2, y2: integer);
begin
  if not Assigned(FTileArray[x2, y2]) then
  begin
    FTileArray[x2, y2] := FTileArray[x1, y1];
    FTileArray[x1, y1] := nil;
    FMoved_Or_Merged := true; // Tiles moved or merged
  end
  else
  begin
    if (FTileArray[x2, y2].Value = FTileArray[x1, y1].Value)
      and not FTileArray[x2, y2].Merged
      and not FTileArray[x1, y1].Merged
    then
    begin
      FTileArray[x2, y2].Merge;
      FreeAndNil(FTileArray[x1, y1]);
      Inc(FScore, FTileArray[x2, y2].Value);

      if FScore > FBest then
        FBest := FScore;

      FMoved_Or_Merged := true; // Tiles moved or merged
    end;
  end;
end;

procedure TfrmWin2048.MoveX(DirectionX: TDirectionX);
var
  x, x1, y: integer;
begin
  case DirectionX of
    dxLeft:
      begin
        for x := Low(FTileArray) + 1 to High(FTileArray) do
        begin
          for y := Low(FTileArray[x]) to High(FTileArray[x]) do
          begin
            if Assigned(FTileArray[x, y]) then
            begin
              for x1 := x downto Low(FTileArray[x]) + 1 do
              begin
                MoveAndMerge(x1, y, x1 - 1, y);

                if not FMoved_Or_Merged then
                  break;
              end;
            end;
          end;
        end;
      end;

    dxRight:
      begin
        for x := High(FTileArray) - 1 downto Low(FTileArray) do
        begin
          for y := Low(FTileArray[x]) to High(FTileArray[x]) do
          begin
            if Assigned(FTileArray[x, y]) then
            begin
              for x1 := x to High(FTileArray[x]) - 1 do
              begin
                MoveAndMerge(x1, y, x1 + 1, y);

                if not FMoved_Or_Merged then
                  break;
              end;
            end;
          end;
        end;
      end;
  end;
end;

procedure TfrmWin2048.MoveY(DirectionY: TDirectionY);
var
  x, y, y1: integer;
begin
  case DirectionY of
    dyUp:
      begin
        for x := Low(FTileArray) to High(FTileArray) do
        begin
          for y := Low(FTileArray[x]) + 1 to High(FTileArray[x]) do
          begin
            if Assigned(FTileArray[x, y]) then
            begin
              for y1 := y downto Low(FTileArray[x]) + 1 do
              begin
                MoveAndMerge(x, y1, x, y1 - 1);

                if not FMoved_Or_Merged then
                  break;
              end;
            end;
          end;
        end;
      end;

    dyDown:
      begin
        for x := Low(FTileArray) to High(FTileArray) do
        begin
          for y := High(FTileArray[x]) - 1 downto Low(FTileArray[x]) do
          begin
            if Assigned(FTileArray[x, y]) then
            begin
              for y1 := y to High(FTileArray[x]) - 1 do
              begin
                MoveAndMerge(x, y1, x, y1 + 1);

                if not FMoved_Or_Merged then
                  break;
              end;
            end;
          end;
        end;
      end;
  end;
end;

procedure TfrmWin2048.ResetGame;
begin
  FScore := 0;
  FKeepPlaying := false;
  FNewGame := true;
  ClearTileArray;
  AddTile;
  ShowTileArray;
end;

procedure TfrmWin2048.SaveGame;
var
  stream: TFileStream;
  writer: TWriter;
  x, y: byte;
begin
  try
    stream := TFileStream.Create(GetApplicationDir + SAVEGAME_FILENAME, fmCreate or fmShareExclusive);
    writer := TWriter.Create(stream, 2048);

    try
      //Programmname in Datei schreiben
      writer.WriteString(APP_NAME);

      //Programmeinstellungen speichern
      writer.WriteInteger(FSquareCount);
      writer.WriteInteger(FWinValue);

      //aktuelle Spieldaten speichern
      writer.WriteInteger(FScore);
      writer.WriteInteger(FBest);

      writer.WriteListBegin;

      for x := Low(FTileArray) to High(FTileArray) do
      begin
        for y := Low(FTileArray[x]) to High(FTileArray[x]) do
        begin
          if Assigned(FTileArray[x, y]) then
          begin
            writer.WriteInteger(x);
            writer.WriteInteger(y);
            writer.WriteInteger(FTileArray[x, y].Value);
          end;
        end;
      end;

      writer.WriteListEnd;
    finally
      writer.Free;
      stream.Free;
    end;
  except
    on e:EFCreateError do
    begin
      MessageDlg('Could not save the game! :(' + sLineBreak + '(' + e.Message + ')', mtError, [mbOK], 0);
    end;
  else
    raise;
  end;
end;

procedure TfrmWin2048.SetFormCaption;
begin
  Self.Caption := APP_NAME + ' ' + IntToStr(FSquareCount) + 'x' + IntToStr(FSquareCount) + ' (get to the ' + IntToStr(FWinValue) + ' tile)';
end;

procedure TfrmWin2048.SetGridSize;
begin
  Self.AutoSize := false;

  grid.Height := (grid.DefaultRowHeight + grid.GridLineWidth) * FSquareCount;
  grid.Width := (grid.DefaultColWidth + grid.GridLineWidth) * FSquareCount;
  grid.ColCount := FSquareCount;
  grid.RowCount := FSquareCount;

//  pnlScore.Width := grid.Width;
//  pnlBest.Width := grid.Width;

  Self.ClientHeight := grid.Height + pnlScore.Height + pnlBest.Height;
  Self.ClientWidth := grid.Width;
  Self.AutoSize := true;
end;

procedure TfrmWin2048.ShowTileArray;
var
  x, y: integer;
begin
  for x := Low(FTileArray) to High(FTileArray) do
  begin
    for y := Low(FTileArray[x]) to High(FTileArray[x]) do
    begin
      if Assigned(FTileArray[x, y]) then
        grid.Cells[x, y] := IntToStr(FTileArray[x, y].Value) //IntToHex(FTileArray[x, y].Value, 1)
      else
        grid.Cells[x, y] := '';
    end;
  end;

  pnlScore.Caption := ' Score : ' + IntToStr(FScore);
  pnlBest.Caption := '   Best : ' + IntToStr(FBest);
  Application.ProcessMessages;
end;

procedure TfrmWin2048.ShuffleFreeTiles<T>(list: TList<T>);
var
  randIndex: integer;
  i, j: integer;
begin
  if list.Count <= 1 then
    exit;

  Randomize;

  for j := 1 to list.Count div 2 do
  begin
    for i := 0 to list.Count - 1 do
    begin
      randIndex := i;

      while randIndex = i do
        randIndex := Random(list.Count) ;

      list.Exchange(i, randIndex) ;
    end;
  end;
end;

end.
