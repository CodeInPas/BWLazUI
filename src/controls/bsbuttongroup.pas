unit bsbuttongroup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsButtonGroupItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  { TBsButtonGroup: Komponen grup tombol terpadu bergaya Bootstrap }
  TBsButtonGroup = class(TCustomControl)
  private
    FItems: TStringList;
    FThemeColor: TBsThemeColor;
    FStyle: TBsStyle;
    FCornerType: TBsCornerType;
    FItemIndex: Integer;

    FHoverIndex: Integer;
    FDownIndex: Integer;

    FOnItemClick: TBsButtonGroupItemEvent;

    procedure SetItems(AValue: TStringList);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetStyle(AValue: TBsStyle);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetItemIndex(AValue: Integer);

    procedure ItemsChanged(Sender: TObject);
    function GetIndexAt(X: Integer): Integer;

    { LCL Messages }
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
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
    destructor Destroy; override;
  published
    property Items: TStringList read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property Style: TBsStyle read FStyle write SetStyle default bssSolid;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctNormal;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Events }
    property OnItemClick: TBsButtonGroupItemEvent read FOnItemClick write FOnItemClick;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsButtonGroup]);
end;

{ TBsButtonGroup }

constructor TBsButtonGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csDoubleClicks];

  Width := 200;
  Height := 38;
  TabStop := True;

  FThemeColor := btcPrimary;
  FStyle := bssSolid;
  FCornerType := bctNormal;
  FItemIndex := -1;
  FHoverIndex := -1;
  FDownIndex := -1;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;
  FItems.Add('Left');
  FItems.Add('Middle');
  FItems.Add('Right');
end;

destructor TBsButtonGroup.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TBsButtonGroup.SetItems(AValue: TStringList);
begin
  FItems.Assign(AValue);
end;

procedure TBsButtonGroup.ItemsChanged(Sender: TObject);
begin
  if FItemIndex >= FItems.Count then FItemIndex := FItems.Count - 1;
  Invalidate;
end;

procedure TBsButtonGroup.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsButtonGroup.SetStyle(AValue: TBsStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TBsButtonGroup.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsButtonGroup.SetItemIndex(AValue: Integer);
begin
  if FItemIndex = AValue then Exit;
  FItemIndex := AValue;
  if FItemIndex >= FItems.Count then FItemIndex := FItems.Count - 1;
  Invalidate;
end;

function TBsButtonGroup.GetIndexAt(X: Integer): Integer;
var
  ItemW: Single;
begin
  if FItems.Count = 0 then Exit(-1);
  ItemW := Width / FItems.Count;
  Result := Trunc(X / ItemW);
  if Result < 0 then Result := 0;
  if Result >= FItems.Count then Result := FItems.Count - 1;
end;

procedure TBsButtonGroup.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TBsButtonGroup.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  FHoverIndex := -1;
  FDownIndex := -1;
  Invalidate;
end;

procedure TBsButtonGroup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIndex: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;

  NewIndex := GetIndexAt(X);
  if FHoverIndex <> NewIndex then
  begin
    FHoverIndex := NewIndex;
    Invalidate;
  end;
end;

procedure TBsButtonGroup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownIndex := GetIndexAt(X);
    if CanFocus then SetFocus;
    Invalidate;
  end;
end;

procedure TBsButtonGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (FDownIndex <> -1) then
  begin
    UpIndex := GetIndexAt(X);
    if (UpIndex = FDownIndex) and PtInRect(ClientRect, Point(X, Y)) then
    begin
      FItemIndex := UpIndex;
      if Assigned(FOnItemClick) then FOnItemClick(Self, UpIndex);
    end;
    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBsButtonGroup.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TBsButtonGroup.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TBsButtonGroup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_LEFT) and (FItemIndex > 0) then
  begin
    SetItemIndex(FItemIndex - 1);
    if Assigned(FOnItemClick) then FOnItemClick(Self, FItemIndex);
  end
  else if (Key = VK_RIGHT) and (FItemIndex < FItems.Count - 1) then
  begin
    SetItemIndex(FItemIndex + 1);
    if Assigned(FOnItemClick) then FOnItemClick(Self, FItemIndex);
  end;
end;

procedure TBsButtonGroup.Paint;
var
  Bmp, ContentBmp, MaskBmp: TBGRABitmap;
  BgColor, BdColor, FillColor, TxtColor: TBGRAPixel;
  ItemW: Single;
  Radius, i, x, y: Integer;
  ItemRect: TRect;
  pC, pM: PBGRAPixel;
  IsActive, IsHover: Boolean;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    if FItems.Count = 0 then
    begin
      Bmp.Draw(Canvas, 0, 0, False);
      Exit;
    end;

    ItemW := Width / FItems.Count;
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // 1. Buat kanvas untuk menggambar item (Background & Text)
    ContentBmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
    try
      for i := 0 to FItems.Count - 1 do
      begin
        ItemRect := Rect(Round(i * ItemW), 0, Round((i + 1) * ItemW), Height);

        IsActive := (i = FItemIndex) or (i = FDownIndex);
        IsHover := (i = FHoverIndex) and not IsActive;

        if not Enabled then
        begin
          if FStyle = bssSolid then FillColor := TBsTheme.GetDisabledColor
          else FillColor := BGRA(0,0,0,0);
          TxtColor := TBsTheme.GetDisabledTextColor;
        end
        else
        begin
          case FStyle of
            bssSolid:
              begin
                if IsActive then FillColor := TBsTheme.GetActiveColor(FThemeColor)
                else if IsHover then FillColor := TBsTheme.GetHoverColor(FThemeColor)
                else FillColor := TBsTheme.GetBaseColor(FThemeColor);
                TxtColor := BS_TEXT_COLOR[FThemeColor];
              end;
            bssOutline:
              begin
                if IsActive then
                begin
                  FillColor := TBsTheme.GetActiveColor(FThemeColor);
                  TxtColor := BS_TEXT_COLOR[FThemeColor];
                end
                else if IsHover then
                begin
                  FillColor := TBsTheme.GetBaseColor(FThemeColor);
                  TxtColor := BS_TEXT_COLOR[FThemeColor];
                end
                else
                begin
                  FillColor := BGRA(0,0,0,0);
                  TxtColor := TBsTheme.GetTextColor(FThemeColor, FStyle);
                end;
              end;
          end;
        end;

        if FillColor.alpha > 0 then
          ContentBmp.FillRectAntialias(ItemRect.Left, ItemRect.Top, ItemRect.Right, ItemRect.Bottom, FillColor);

        TBsGraphics.DrawText(ContentBmp, ItemRect, FItems[i], Font, TxtColor, bsaCenter, 0);
      end;

      // 2. Buat Mask untuk efek Rounded Corners pada keseluruhan grup
      MaskBmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
      try
        MaskBmp.FillRoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, BGRA(255,255,255,255));

        // Aplikasikan Alpha Mask (O(N) Pixel Iteration)
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

      // 3. Salin konten yang sudah dipotong (masked) ke Bmp utama
      Bmp.PutImage(0, 0, ContentBmp, dmDrawWithTransparency);
    finally
      ContentBmp.Free;
    end;

    // 4. Gambar Separator Internal
    if Enabled then
      BdColor := TBsTheme.GetBorderColor(FThemeColor, FStyle)
    else
      BdColor := TBsTheme.GetDisabledColor;

    if (FStyle = bssSolid) and Enabled then
    begin
      if FThemeColor = btcLight then
        BdColor := TBsTheme.GetBorderColor(btcLight, bssSolid)
      else
        BdColor := TBsTheme.GetActiveColor(FThemeColor); // Separator lebih gelap
    end;

    for i := 1 to FItems.Count - 1 do
      Bmp.DrawLineAntialias(Round(i * ItemW), 0, Round(i * ItemW), Height, BdColor, 1);

    // 5. Gambar Outline Luar
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, BGRA(0,0,0,0), BdColor, 1);

    // 6. Focus Ring
    if Focused then
      TBsGraphics.DrawFocusRing(Bmp, ClientRect, Radius, TBsTheme.GetFocusRingColor(FThemeColor), 3);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
