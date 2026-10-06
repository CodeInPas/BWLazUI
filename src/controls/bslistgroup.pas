unit bslistgroup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsListGroupItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  { TBsListGroup: Komponen daftar item vertikal bergaya Bootstrap }
  TBsListGroup = class(TCustomControl)
  private
    FItems: TStringList;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FFlush: Boolean;
    FItemHeight: Integer;
    FItemIndex: Integer;
    FHoverIndex: Integer;
    FDownIndex: Integer;

    FOnItemClick: TBsListGroupItemEvent;

    procedure SetItems(AValue: TStringList);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetFlush(AValue: Boolean);
    procedure SetItemHeight(AValue: Integer);
    procedure SetItemIndex(AValue: Integer);

    procedure ItemsChanged(Sender: TObject);
    function GetIndexAt(Y: Integer): Integer;
    procedure UpdateHeight;

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
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TStringList read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property Flush: Boolean read FFlush write SetFlush default False;
    property ItemHeight: Integer read FItemHeight write SetItemHeight default 40;
    property ItemIndex: Integer read FItemIndex write SetItemIndex default -1;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Events }
    property OnItemClick: TBsListGroupItemEvent read FOnItemClick write FOnItemClick;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsListGroup]);
end;

{ TBsListGroup }

constructor TBsListGroup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csDoubleClicks];

  Width := 250;
  Height := 120;
  Color := clWindow;
  TabStop := True;

  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FFlush := False;
  FItemHeight := 40;
  FItemIndex := -1;
  FHoverIndex := -1;
  FDownIndex := -1;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;
  FItems.Add('An item');
  FItems.Add('A second item');
  FItems.Add('A third item');

  UpdateHeight;
end;

destructor TBsListGroup.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TBsListGroup.SetItems(AValue: TStringList);
begin
  FItems.Assign(AValue);
end;

procedure TBsListGroup.ItemsChanged(Sender: TObject);
begin
  if FItemIndex >= FItems.Count then FItemIndex := FItems.Count - 1;
  UpdateHeight;
  Invalidate;
end;

procedure TBsListGroup.UpdateHeight;
begin
  if not (csDesigning in ComponentState) and (Align = alNone) and not (akBottom in Anchors) then
    Height := (FItems.Count * FItemHeight) + 2; // +2 untuk border atas bawah
end;

procedure TBsListGroup.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsListGroup.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsListGroup.SetFlush(AValue: Boolean);
begin
  if FFlush = AValue then Exit;
  FFlush := AValue;
  Invalidate;
end;

procedure TBsListGroup.SetItemHeight(AValue: Integer);
begin
  if FItemHeight = AValue then Exit;
  FItemHeight := AValue;
  if FItemHeight < 10 then FItemHeight := 10;
  UpdateHeight;
  Invalidate;
end;

procedure TBsListGroup.SetItemIndex(AValue: Integer);
begin
  if FItemIndex = AValue then Exit;
  FItemIndex := AValue;
  if FItemIndex >= FItems.Count then FItemIndex := FItems.Count - 1;
  Invalidate;
end;

function TBsListGroup.GetIndexAt(Y: Integer): Integer;
begin
  if FItems.Count = 0 then Exit(-1);
  Result := (Y - 1) div FItemHeight; // -1 untuk kompensasi border top
  if Result < 0 then Result := -1;
  if Result >= FItems.Count then Result := -1;
end;

procedure TBsListGroup.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Invalidate;
  end;
end;

procedure TBsListGroup.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  FHoverIndex := -1;
  FDownIndex := -1;
  Invalidate;
end;

procedure TBsListGroup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIndex: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;

  NewIndex := GetIndexAt(Y);
  if FHoverIndex <> NewIndex then
  begin
    FHoverIndex := NewIndex;
    Invalidate;
  end;
end;

procedure TBsListGroup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownIndex := GetIndexAt(Y);
    if CanFocus then SetFocus;
    Invalidate;
  end;
end;

procedure TBsListGroup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (FDownIndex <> -1) then
  begin
    UpIndex := GetIndexAt(Y);
    if (UpIndex = FDownIndex) and (UpIndex <> -1) then
    begin
      FItemIndex := UpIndex;
      if Assigned(FOnItemClick) then FOnItemClick(Self, UpIndex);
    end;
    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBsListGroup.DoEnter;
begin
  inherited DoEnter;
  Invalidate;
end;

procedure TBsListGroup.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

procedure TBsListGroup.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if (Key = VK_UP) and (FItemIndex > 0) then
  begin
    SetItemIndex(FItemIndex - 1);
    if Assigned(FOnItemClick) then FOnItemClick(Self, FItemIndex);
  end
  else if (Key = VK_DOWN) and (FItemIndex < FItems.Count - 1) then
  begin
    SetItemIndex(FItemIndex + 1);
    if Assigned(FOnItemClick) then FOnItemClick(Self, FItemIndex);
  end;
end;

procedure TBsListGroup.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TBsListGroup.Paint;
var
  Bmp, ContentBmp, MaskBmp: TBGRABitmap;
  BgColor, BdColor, FillColor, TxtColor: TBGRAPixel;
  Radius, i, x, y: Integer;
  ItemRect: TRect;
  pC, pM: PBGRAPixel;
  IsActive, IsHover: Boolean;
  TotalHeight: Integer;
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

    if FFlush then Radius := 0
    else Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    if not Enabled then BdColor := TBsTheme.GetDisabledColor;

    TotalHeight := (FItems.Count * FItemHeight) + 2;

    // 1. Buat kanvas konten
    ContentBmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(ColorToRGB(Color)));
    try
      for i := 0 to FItems.Count - 1 do
      begin
        ItemRect := Rect(0, (i * FItemHeight) + 1, Width, ((i + 1) * FItemHeight) + 1);
        if ItemRect.Top >= Height then Break; // Optimasi jika melebihi tinggi komponen

        IsActive := (i = FItemIndex);
        IsHover := (i = FHoverIndex) and not IsActive;

        // Penentuan Warna Item
        if not Enabled then
        begin
          FillColor := ColorToBGRA(ColorToRGB(Color));
          TxtColor := TBsTheme.GetDisabledTextColor;
        end
        else if IsActive then
        begin
          FillColor := TBsTheme.GetBaseColor(FThemeColor);
          TxtColor := BS_TEXT_COLOR[FThemeColor];
        end
        else
        begin
          if IsHover then
            FillColor := TBsTheme.GetBaseColor(btcLight) // #F8F9FA
          else
            FillColor := ColorToBGRA(ColorToRGB(Color));
          TxtColor := TBsTheme.GetTextColor(btcDark, bssSolid); // Default teks gelap
        end;

        // Render Background Item
        ContentBmp.FillRectAntialias(ItemRect.Left, ItemRect.Top, ItemRect.Right, ItemRect.Bottom, FillColor);

        // Render Separator Bawah (kecuali item terakhir)
        if i < FItems.Count - 1 then
          ContentBmp.DrawLineAntialias(0, ItemRect.Bottom, Width, ItemRect.Bottom, BdColor, 1);

        // Render Teks Item dengan Padding Kiri 16px
        TBsGraphics.DrawText(ContentBmp, ItemRect, FItems[i], Font, TxtColor, bsaStart, 16);
      end;

      // 2. Buat Masking untuk border radius
      MaskBmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
      try
        if not FFlush then
        begin
          MaskBmp.FillRoundRectAntialias(0, 0, Width - 1, TotalHeight - 1, Radius, Radius, BGRA(255,255,255,255));

          // Terapkan mask pada konten (O(N))
          for y := 0 to Height - 1 do
          begin
            pC := ContentBmp.Scanline[y];
            pM := MaskBmp.Scanline[y];
            for x := 0 to Width - 1 do
            begin
              if pM^.alpha = 0 then pC^.alpha := 0
              else if pM^.alpha < 255 then pC^.alpha := (pC^.alpha * pM^.alpha) div 255;
              Inc(pC); Inc(pM);
            end;
          end;
        end;
      finally
        MaskBmp.Free;
      end;

      // 3. Salin ke Bitmap Utama
      if FFlush then
        Bmp.PutImage(0, 0, ContentBmp, dmSet)
      else
        Bmp.PutImage(0, 0, ContentBmp, dmDrawWithTransparency);
    finally
      ContentBmp.Free;
    end;

    // 4. Render Garis Outline Border (Jika tidak Flush)
    if not FFlush then
    begin
      Bmp.RoundRectAntialias(0, 0, Width - 1, TotalHeight - 1, Radius, Radius, BdColor, 1);
    end
    else
    begin
      // Jika Flush, pastikan ada border atas dan bawah
      Bmp.DrawLineAntialias(0, 0, Width, 0, BdColor, 1);
      Bmp.DrawLineAntialias(0, TotalHeight - 1, Width, TotalHeight - 1, BdColor, 1);
    end;

    // 5. Render Focus Ring
    if Focused then
      TBsGraphics.DrawFocusRing(Bmp, Rect(0, 0, Width, TotalHeight), Radius, TBsTheme.GetFocusRingColor(FThemeColor), 3);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
