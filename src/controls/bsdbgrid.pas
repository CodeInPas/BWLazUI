unit bsdbgrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Controls, Graphics, Forms, StdCtrls, LMessages, LCLType, DB,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsGridHeaderStyle = (bghsDefault, bghsPrimary, bghsDark, bghsLight);

  TBsDBGrid = class;

  { TBsGridDataLink }
  TBsGridDataLink = class(TDataLink)
  private
    FGrid: TBsDBGrid;
  protected
    procedure ActiveChanged; override;
    procedure DataSetChanged; override;
    procedure RecordChanged(Field: TField); override;
  public
    constructor Create(AGrid: TBsDBGrid);
  end;

  { TBsDBGrid: DBGrid Bergaya Bootstrap 5 }
  TBsDBGrid = class(TCustomControl)
  private
    FDataLink: TBsGridDataLink;
    FRowHeight: Integer;
    FHeaderHeight: Integer;
    FHeaderStyle: TBsGridHeaderStyle;
    FStriped: Boolean;
    FHoverable: Boolean;
    FBordered: Boolean;
    FCornerType: TBsCornerType;
    FGridLines: Boolean;
    FHoveredRow: Integer;
    FThemeColor: TBsThemeColor;

    function GetDataSource: TDataSource;
    procedure SetDataSource(AValue: TDataSource);
    procedure SetRowHeight(AValue: Integer);
    procedure SetHeaderHeight(AValue: Integer);
    procedure SetHeaderStyle(AValue: TBsGridHeaderStyle);
    procedure SetStriped(AValue: Boolean);
    procedure SetHoverable(AValue: Boolean);
    procedure SetBordered(AValue: Boolean);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetGridLines(AValue: Boolean);

    function GetRowAtY(Y: Integer): Integer;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
    procedure DataChanged;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property RowHeight: Integer read FRowHeight write SetRowHeight default 36;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 40;
    property HeaderStyle: TBsGridHeaderStyle read FHeaderStyle write SetHeaderStyle default bghsDark;
    property Striped: Boolean read FStriped write SetStriped default True;
    property Hoverable: Boolean read FHoverable write SetHoverable default True;
    property Bordered: Boolean read FBordered write SetBordered default True;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property GridLines: Boolean read FGridLines write SetGridLines default True;

    { Properti Standar LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property TabOrder;
    property TabStop default True;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsDBGrid]);
end;

{ TBsGridDataLink }

constructor TBsGridDataLink.Create(AGrid: TBsDBGrid);
begin
  inherited Create;
  FGrid := AGrid;
end;

procedure TBsGridDataLink.ActiveChanged;
begin
  if Assigned(FGrid) then FGrid.DataChanged;
end;

procedure TBsGridDataLink.DataSetChanged;
begin
  if Assigned(FGrid) then FGrid.DataChanged;
end;

procedure TBsGridDataLink.RecordChanged(Field: TField);
begin
  if Assigned(FGrid) then FGrid.DataChanged;
end;

{ TBsDBGrid }

constructor TBsDBGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle - [csOpaque] + [csCaptureMouse];
  DoubleBuffered := True;

  Width := 500;
  Height := 280;
  TabStop := True;

  FDataLink := TBsGridDataLink.Create(Self);
  FRowHeight := 36;
  FHeaderHeight := 40;
  FHeaderStyle := bghsDark;
  FStriped := True;
  FHoverable := True;
  FBordered := True;
  FCornerType := bctSmall;
  FGridLines := True;
  FHoveredRow := -1;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Color := clWindowText;
end;

destructor TBsDBGrid.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

function TBsDBGrid.GetDataSource: TDataSource;
begin
  Result := FDataLink.DataSource;
end;

procedure TBsDBGrid.SetDataSource(AValue: TDataSource);
begin
  FDataLink.DataSource := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetRowHeight(AValue: Integer);
begin
  if (AValue < 20) or (FRowHeight = AValue) then Exit;
  FRowHeight := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetHeaderHeight(AValue: Integer);
begin
  if (AValue < 24) or (FHeaderHeight = AValue) then Exit;
  FHeaderHeight := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetHeaderStyle(AValue: TBsGridHeaderStyle);
begin
  if FHeaderStyle = AValue then Exit;
  FHeaderStyle := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetStriped(AValue: Boolean);
begin
  if FStriped = AValue then Exit;
  FStriped := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetHoverable(AValue: Boolean);
begin
  if FHoverable = AValue then Exit;
  FHoverable := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetBordered(AValue: Boolean);
begin
  if FBordered = AValue then Exit;
  FBordered := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsDBGrid.SetGridLines(AValue: Boolean);
begin
  if FGridLines = AValue then Exit;
  FGridLines := AValue;
  Invalidate;
end;

procedure TBsDBGrid.DataChanged;
begin
  Invalidate;
end;

function TBsDBGrid.GetRowAtY(Y: Integer): Integer;
begin
  if Y < FHeaderHeight then
    Result := -1
  else
  begin
    Result := (Y - FHeaderHeight) div FRowHeight;
  end;
end;

procedure TBsDBGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ClickedRow, ActiveOffset: Integer;
  DS: TDataSet;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Assigned(FDataLink) and FDataLink.Active then
  begin
    DS := FDataLink.DataSet;
    ClickedRow := GetRowAtY(Y);
    if (ClickedRow >= 0) and not DS.IsEmpty then
    begin
      // Mengubah record aktif sesuai baris yang diklik
      ActiveOffset := ClickedRow;
      DS.First;
      if ActiveOffset > 0 then
        DS.MoveBy(ActiveOffset);
      Invalidate;
    end;
  end;
end;

procedure TBsDBGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if FHoverable then
  begin
    NewHover := GetRowAtY(Y);
    if NewHover <> FHoveredRow then
    begin
      FHoveredRow := NewHover;
      Invalidate;
    end;
  end;
end;

procedure TBsDBGrid.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoveredRow <> -1 then
  begin
    FHoveredRow := -1;
    Invalidate;
  end;
end;

procedure TBsDBGrid.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TBsDBGrid.Paint;
var
  Bmp: TBGRABitmap;
  Radius, c, CurX, CurY, CellW, MaxRows, RenderedRows: Integer;
  HdrBg, HdrTextBg, RowBg, GridBorderClr, FocusRingClr: TBGRAPixel;
  CellRect: TRect;
  HdrFont: TFont;
  DS: TDataSet;
  VisibleFields: array of TField;
  FieldCount: Integer;
  SavedBk: TBookmark;
  CellText: string;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height);
  HdrFont := TFont.Create;
  try
    HdrFont.Assign(Font);
    HdrFont.Style := HdrFont.Style + [fsBold];

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);
    GridBorderClr := TBsTheme.GetBorderColor(btcSecondary, bssOutline);

    // 1. Latar Belakang & Border Luar
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, ColorToBGRA(ColorToRGB(clWindow)), GridBorderClr, 1);

    // 2. Tentukan Warna Header
    case FHeaderStyle of
      bghsPrimary:
        begin
          HdrBg := TBsTheme.GetBaseColor(btcPrimary);
          HdrTextBg := BGRA(255, 255, 255, 255);
        end;
      bghsDark:
        begin
          HdrBg := BGRA(33, 37, 41, 255);
          HdrTextBg := BGRA(255, 255, 255, 255);
        end;
      bghsLight:
        begin
          HdrBg := BGRA(248, 249, 250, 255);
          HdrTextBg := BGRA(33, 37, 41, 255);
        end;
    else
      HdrBg := BGRA(233, 236, 239, 255);
      HdrTextBg := BGRA(33, 37, 41, 255);
    end;

    Bmp.FillRect(1, 1, Width - 1, FHeaderHeight, HdrBg, dmSet);

    // 3. Evaluasi Field TDataSet
    FieldCount := 0;
    SetLength(VisibleFields, 0);

    if Assigned(FDataLink) and FDataLink.Active then
    begin
      DS := FDataLink.DataSet;
      for c := 0 to DS.Fields.Count - 1 do
      begin
        if DS.Fields[c].Visible then
        begin
          Inc(FieldCount);
          SetLength(VisibleFields, FieldCount);
          VisibleFields[FieldCount - 1] := DS.Fields[c];
        end;
      end;
    end;

    // Render Judul Kolom Header
    if FieldCount > 0 then
    begin
      CellW := Max(60, (Width - 2) div FieldCount);
      CurX := 1;
      for c := 0 to FieldCount - 1 do
      begin
        CellRect := Rect(CurX + 8, 2, CurX + CellW - 8, FHeaderHeight - 2);
        TBsGraphics.DrawText(Bmp, CellRect, VisibleFields[c].DisplayLabel, HdrFont, HdrTextBg, bsaStart, 0);

        if FGridLines and (c < FieldCount - 1) then
          Bmp.DrawLineAntialias(CurX + CellW, 1, CurX + CellW, FHeaderHeight, BGRA(222, 226, 230, 255), 1.0);

        Inc(CurX, CellW);
      end;
    end;

    Bmp.DrawLineAntialias(1, FHeaderHeight, Width - 1, FHeaderHeight, BGRA(173, 181, 189, 255), 1.0);

    // 4. Render Data Baris TDataSet
    CurY := FHeaderHeight;
    MaxRows := (Height - FHeaderHeight) div FRowHeight;
    RenderedRows := 0;

    if Assigned(FDataLink) and FDataLink.Active and not FDataLink.DataSet.IsEmpty then
    begin
      DS := FDataLink.DataSet;
      DS.DisableControls;
      try
        SavedBk := DS.Bookmark;
        DS.First;

        while not DS.Eof and (RenderedRows < MaxRows) do
        begin
          // Warna Isian Baris
          if DS.Bookmark = SavedBk then
            RowBg := BGRA(13, 110, 253, 45) // Highlight Baris Aktif
          else if (RenderedRows = FHoveredRow) and FHoverable then
            RowBg := BGRA(0, 0, 0, 12)
          else if FStriped and Odd(RenderedRows) then
            RowBg := BGRA(0, 0, 0, 8)
          else
            RowBg := ColorToBGRA(ColorToRGB(clWindow));

          Bmp.FillRect(1, CurY, Width - 1, CurY + FRowHeight, RowBg, dmDrawWithTransparency);

          if FieldCount > 0 then
          begin
            CellW := Max(60, (Width - 2) div FieldCount);
            CurX := 1;
            for c := 0 to FieldCount - 1 do
            begin
              CellRect := Rect(CurX + 8, CurY + 2, CurX + CellW - 8, CurY + FRowHeight - 2);
              CellText := VisibleFields[c].DisplayText;

              TBsGraphics.DrawText(Bmp, CellRect, CellText, Font, ColorToBGRA(ColorToRGB(Font.Color)), bsaStart, 0);

              if FGridLines and (c < FieldCount - 1) then
                Bmp.DrawLineAntialias(CurX + CellW, CurY, CurX + CellW, CurY + FRowHeight, BGRA(222, 226, 230, 180), 1.0);

              Inc(CurX, CellW);
            end;
          end;

          Inc(CurY, FRowHeight);
          if FGridLines then
            Bmp.DrawLineAntialias(1, CurY, Width - 1, CurY, BGRA(222, 226, 230, 180), 1.0);

          Inc(RenderedRows);
          DS.Next;
        end;

        if DS.BookmarkValid(SavedBk) then
          DS.Bookmark := SavedBk;
      finally
        DS.EnableControls;
      end;
    end;

    // Focus Ring
    if Focused then
    begin
      FocusRingClr := TBsTheme.GetFocusRingColor(btcPrimary);
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, FocusRingClr, 2);
    end;

    Bmp.Draw(Canvas, 0, 0, True);
  finally
    SetLength(VisibleFields, 0);
    HdrFont.Free;
    Bmp.Free;
  end;
end;

end.
