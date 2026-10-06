unit bspagination;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types, Math,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsPaginationChangeEvent = procedure(Sender: TObject; PageNumber: Integer) of object;

  { TBsPagination: Komponen navigasi halaman (Pagination) bergaya Bootstrap }
  TBsPagination = class(TCustomControl)
  private
    FThemeColor: TBsThemeColor;
    FSize: TBsSize;
    FCornerType: TBsCornerType;
    FAlignment: TAlignment;

    FTotalPages: Integer;
    FCurrentPage: Integer;
    FVisiblePages: Integer; // Jumlah tombol angka maksimal yang tampil

    FItemRects: array of TRect;
    FItemTypes: array of Integer; // 0=Prev, 1..N=PageNum, -1=Next, -2=Ellipsis
    FItemValues: array of Integer; // Nilai halaman asli untuk setiap item
    FItemCount: Integer;

    FHoverIndex: Integer;
    FDownIndex: Integer;

    FOnChange: TBsPaginationChangeEvent;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetSize(AValue: TBsSize);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetAlignment(AValue: TAlignment);
    procedure SetTotalPages(AValue: Integer);
    procedure SetCurrentPage(AValue: Integer);
    procedure SetVisiblePages(AValue: Integer);

    procedure ApplySize;
    procedure UpdateLayout;
    function GetIndexAt(X, Y: Integer): Integer;

    { LCL Messages }
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property SizeMode: TBsSize read FSize write SetSize default bszDefault;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property Alignment: TAlignment read FAlignment write SetAlignment default taLeftJustify;

    property TotalPages: Integer read FTotalPages write SetTotalPages default 10;
    property CurrentPage: Integer read FCurrentPage write SetCurrentPage default 1;
    property VisiblePages: Integer read FVisiblePages write SetVisiblePages default 5;

    { Properti Bawaan }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Events }
    property OnChange: TBsPaginationChangeEvent read FOnChange write FOnChange;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsPagination]);
end;

{ TBsPagination }

constructor TBsPagination.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  Width := 300;
  Height := 38;
  Color := clWindow;
  TabStop := True;

  FThemeColor := btcPrimary;
  FSize := bszDefault;
  FCornerType := bctSmall;
  FAlignment := taLeftJustify;

  FTotalPages := 10;
  FCurrentPage := 1;
  FVisiblePages := 5;

  FHoverIndex := -1;
  FDownIndex := -1;
  FItemCount := 0;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  ApplySize;
end;

procedure TBsPagination.ApplySize;
begin
  case FSize of
    bszSmall:
      begin
        Height := 31;
        Font.Size := 9;
      end;
    bszDefault:
      begin
        Height := 38;
        Font.Size := 10;
      end;
    bszLarge:
      begin
        Height := 48;
        Font.Size := 12;
      end;
  end;
  UpdateLayout;
  Invalidate;
end;

procedure TBsPagination.UpdateLayout;
var
  i, StartPage, EndPage, TotalItems, ItemW, CurrentX, StartX, TotalWidth: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  ItemW := Height; // Default tombol kotak (lebar = tinggi)
  if FSize = bszSmall then ItemW := 28;
  if FSize = bszLarge then ItemW := 48;

  // Hitung jumlah item total
  TotalItems := 2; // Prev & Next

  if FTotalPages <= FVisiblePages then
  begin
    StartPage := 1;
    EndPage := FTotalPages;
    Inc(TotalItems, FTotalPages);
  end
  else
  begin
    // Logika perhitungan posisi halaman untuk menampilkan ellipsis (...)
    StartPage := Max(1, FCurrentPage - (FVisiblePages div 2));
    EndPage := StartPage + FVisiblePages - 1;

    if EndPage > FTotalPages then
    begin
      EndPage := FTotalPages;
      StartPage := Max(1, EndPage - FVisiblePages + 1);
    end;

    Inc(TotalItems, EndPage - StartPage + 1);
    if StartPage > 1 then Inc(TotalItems, 2); // 1, ...
    if EndPage < FTotalPages then Inc(TotalItems, 2); // ..., Total
  end;

  FItemCount := TotalItems;
  SetLength(FItemRects, TotalItems);
  SetLength(FItemTypes, TotalItems);
  SetLength(FItemValues, TotalItems);

  TotalWidth := TotalItems * ItemW;

  // Penentuan posisi awal X berdasarkan Alignment
  case FAlignment of
    taLeftJustify: StartX := 0;
    taCenter: StartX := (Width - TotalWidth) div 2;
    taRightJustify: StartX := Width - TotalWidth;
  end;
  if StartX < 0 then StartX := 0;

  CurrentX := StartX;
  i := 0;

  // 1. Tombol Prev
  FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
  FItemTypes[i] := 0;
  FItemValues[i] := Max(1, FCurrentPage - 1);
  Inc(CurrentX, ItemW);
  Inc(i);

  // 2. Hal 1 & Ellipsis Kiri
  if StartPage > 1 then
  begin
    FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
    FItemTypes[i] := 1;
    FItemValues[i] := 1;
    Inc(CurrentX, ItemW);
    Inc(i);

    FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
    FItemTypes[i] := -2; // Ellipsis
    FItemValues[i] := 0;
    Inc(CurrentX, ItemW);
    Inc(i);
  end;

  // 3. Halaman Tengah
  while StartPage <= EndPage do
  begin
    FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
    FItemTypes[i] := 1;
    FItemValues[i] := StartPage;
    Inc(CurrentX, ItemW);
    Inc(i);
    Inc(StartPage);
  end;

  // 4. Ellipsis Kanan & Halaman Terakhir
  if EndPage < FTotalPages then
  begin
    FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
    FItemTypes[i] := -2; // Ellipsis
    FItemValues[i] := 0;
    Inc(CurrentX, ItemW);
    Inc(i);

    FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
    FItemTypes[i] := 1;
    FItemValues[i] := FTotalPages;
    Inc(CurrentX, ItemW);
    Inc(i);
  end;

  // 5. Tombol Next
  FItemRects[i] := Rect(CurrentX, 0, CurrentX + ItemW, Height);
  FItemTypes[i] := -1;
  FItemValues[i] := Min(FTotalPages, FCurrentPage + 1);
end;

procedure TBsPagination.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsPagination.SetSize(AValue: TBsSize);
begin
  if FSize = AValue then Exit;
  FSize := AValue;
  ApplySize;
end;

procedure TBsPagination.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsPagination.SetAlignment(AValue: TAlignment);
begin
  if FAlignment = AValue then Exit;
  FAlignment := AValue;
  UpdateLayout;
  Invalidate;
end;

procedure TBsPagination.SetTotalPages(AValue: Integer);
begin
  if FTotalPages = AValue then Exit;
  FTotalPages := Max(1, AValue);
  if FCurrentPage > FTotalPages then FCurrentPage := FTotalPages;
  UpdateLayout;
  Invalidate;
end;

procedure TBsPagination.SetCurrentPage(AValue: Integer);
begin
  if FCurrentPage = AValue then Exit;
  FCurrentPage := EnsureRange(AValue, 1, FTotalPages);
  UpdateLayout;
  Invalidate;
end;

procedure TBsPagination.SetVisiblePages(AValue: Integer);
begin
  if FVisiblePages = AValue then Exit;
  FVisiblePages := Max(3, AValue); // Minimal 3
  UpdateLayout;
  Invalidate;
end;

function TBsPagination.GetIndexAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FItemCount - 1 do
  begin
    if PtInRect(FItemRects[i], Point(X, Y)) then
    begin
      // Cek apakah item bisa di-klik
      if FItemTypes[i] = -2 then Exit; // Ellipsis
      if (FItemTypes[i] = 0) and (FCurrentPage = 1) then Exit; // Prev mati
      if (FItemTypes[i] = -1) and (FCurrentPage = FTotalPages) then Exit; // Next mati

      Result := i;
      Break;
    end;
  end;
end;

procedure TBsPagination.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateLayout;
end;

procedure TBsPagination.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  ApplySize;
end;

procedure TBsPagination.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TBsPagination.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIndex: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;

  NewIndex := GetIndexAt(X, Y);
  if FHoverIndex <> NewIndex then
  begin
    FHoverIndex := NewIndex;
    if FHoverIndex <> -1 then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsPagination.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownIndex := GetIndexAt(X, Y);
    if FDownIndex <> -1 then
    begin
      if CanFocus then SetFocus;
      Invalidate;
    end;
  end;
end;

procedure TBsPagination.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex, NewPage: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (FDownIndex <> -1) then
  begin
    UpIndex := GetIndexAt(X, Y);
    if UpIndex = FDownIndex then
    begin
      NewPage := FItemValues[UpIndex];
      if NewPage <> FCurrentPage then
      begin
        SetCurrentPage(NewPage);
        if Assigned(FOnChange) then FOnChange(Self, FCurrentPage);
      end;
    end;
    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBsPagination.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TBsPagination.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TBsPagination.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewPage: Integer;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled then Exit;

  NewPage := FCurrentPage;
  if Key = VK_LEFT then Dec(NewPage)
  else if Key = VK_RIGHT then Inc(NewPage);

  if (NewPage <> FCurrentPage) and (NewPage >= 1) and (NewPage <= FTotalPages) then
  begin
    SetCurrentPage(NewPage);
    if Assigned(FOnChange) then FOnChange(Self, FCurrentPage);
  end;
end;

procedure TBsPagination.Paint;
var
  Bmp, ContentBmp, MaskBmp: TBGRABitmap;
  BgColor, FillColor, BdColor, TxtColor: TBGRAPixel;
  i, Radius, x, y: Integer;
  IsActive, IsDisabled, IsHover: Boolean;
  TextStr: string;
  pC, pM: PBGRAPixel;
begin
  if (Width <= 0) or (Height <= 0) or (FItemCount = 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // 1. Gambar Konten
    ContentBmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(ColorToRGB(Color)));
    try
      for i := 0 to FItemCount - 1 do
      begin
        IsDisabled := not Enabled;
        if not IsDisabled then
        begin
          if (FItemTypes[i] = 0) and (FCurrentPage = 1) then IsDisabled := True;
          if (FItemTypes[i] = -1) and (FCurrentPage = FTotalPages) then IsDisabled := True;
          if FItemTypes[i] = -2 then IsDisabled := True; // Ellipsis tidak interaktif
        end;

        IsActive := (FItemTypes[i] = 1) and (FItemValues[i] = FCurrentPage);
        IsHover := (i = FHoverIndex) or (i = FDownIndex);

        // Penentuan Warna Item Bootstrap Pagination
        if IsDisabled then
        begin
          FillColor := ColorToBGRA(ColorToRGB(Color));
          TxtColor := TBsTheme.GetDisabledTextColor;
          BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline); // #dee2e6
        end
        else if IsActive then
        begin
          FillColor := TBsTheme.GetBaseColor(FThemeColor);
          TxtColor := BS_TEXT_COLOR[FThemeColor];
          BdColor := FillColor;
        end
        else if IsHover then
        begin
          FillColor := TBsTheme.GetBaseColor(btcLight); // #e9ecef
          TxtColor := TBsTheme.GetTextColor(btcPrimary, bssOutline);
          BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
        end
        else
        begin
          FillColor := ColorToBGRA(ColorToRGB(Color)); // Putih
          TxtColor := TBsTheme.GetTextColor(btcPrimary, bssOutline);
          BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
        end;

        // Render Background & Border tiap Item
        ContentBmp.FillRectAntialias(FItemRects[i].Left, FItemRects[i].Top, FItemRects[i].Right, FItemRects[i].Bottom, FillColor);

        // Border Atas & Bawah
        ContentBmp.DrawLineAntialias(FItemRects[i].Left, 0, FItemRects[i].Right, 0, BdColor, 1);
        ContentBmp.DrawLineAntialias(FItemRects[i].Left, Height - 1, FItemRects[i].Right, Height - 1, BdColor, 1);

        // Border Kiri (Hanya item pertama atau jika bukan overlap)
        if i = 0 then
          ContentBmp.DrawLineAntialias(FItemRects[i].Left, 0, FItemRects[i].Left, Height, BdColor, 1)
        else
          ContentBmp.DrawLineAntialias(FItemRects[i].Left, 0, FItemRects[i].Left, Height, BdColor, 1); // Garis pemisah

        // Border Kanan (Hanya item terakhir)
        if i = FItemCount - 1 then
          ContentBmp.DrawLineAntialias(FItemRects[i].Right - 1, 0, FItemRects[i].Right - 1, Height, BdColor, 1);

        // Penentuan String Teks
        case FItemTypes[i] of
          0: TextStr := '«'; // Previous
         -1: TextStr := '»'; // Next
         -2: TextStr := '...'; // Ellipsis
        else
          TextStr := IntToStr(FItemValues[i]);
        end;

        TBsGraphics.DrawText(ContentBmp, FItemRects[i], TextStr, Font, TxtColor, bsaCenter, 0);
      end;

      // 2. Alpha Masking untuk Corner Radius Kiri dan Kanan pada seluruh grup
      MaskBmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
      try
        // Gambar kotak putih dengan rounded corner pada area grup
        MaskBmp.FillRoundRectAntialias(FItemRects[0].Left, 0, FItemRects[FItemCount - 1].Right - 1, Height - 1, Radius, Radius, BGRA(255,255,255,255));

        // Terapkan Mask O(N)
        for y := 0 to Height - 1 do
        begin
          pC := ContentBmp.Scanline[y];
          pM := MaskBmp.Scanline[y];
          for x := 0 to Width - 1 do
          begin
            pC^.alpha := (pC^.alpha * pM^.alpha) div 255;
            Inc(pC); Inc(pM);
          end;
        end;
      finally
        MaskBmp.Free;
      end;

      Bmp.PutImage(0, 0, ContentBmp, dmDrawWithTransparency);
    finally
      ContentBmp.Free;
    end;

    // 3. Render Focus Ring
    if Focused then
    begin
      TBsGraphics.DrawFocusRing(Bmp, Rect(FItemRects[0].Left, 0, FItemRects[FItemCount - 1].Right, Height), Radius, TBsTheme.GetFocusRingColor(FThemeColor), 3);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.

