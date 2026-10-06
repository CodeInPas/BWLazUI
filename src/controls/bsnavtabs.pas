unit bsnavtabs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsNavStyle = (bnsTabs, bnsPills, bnsUnderline);
  TBsNavTabEvent = procedure(Sender: TObject; Index: Integer) of object;

  { TBsNavTabs: Komponen navigasi Tab/Pill bergaya Bootstrap 5 }
  TBsNavTabs = class(TCustomControl)
  private
    FItems: TStringList;
    FThemeColor: TBsThemeColor;
    FNavStyle: TBsNavStyle;
    FCornerType: TBsCornerType;
    FTabIndex: Integer;

    FItemRects: array of TRect;
    FHoverIndex: Integer;
    FDownIndex: Integer;

    FOnTabClick: TBsNavTabEvent;

    procedure SetItems(AValue: TStringList);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetNavStyle(AValue: TBsNavStyle);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetTabIndex(AValue: Integer);

    procedure ItemsChanged(Sender: TObject);
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
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Items: TStringList read FItems write SetItems;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property NavStyle: TBsNavStyle read FNavStyle write SetNavStyle default bnsTabs;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property TabIndex: Integer read FTabIndex write SetTabIndex default 0;

    { Properti Bawaan LCL }
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
    property OnTabClick: TBsNavTabEvent read FOnTabClick write FOnTabClick;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsNavTabs]);
end;

{ TBsNavTabs }

constructor TBsNavTabs.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // 1. Inisialisasi Objek Internal Terlebih Dahulu (Paling Utama)
  FItems := TStringList.Create;
  FItems.OnChange := @ItemsChanged;

  // 2. Setup Style Control
 // ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;



  // 3. Setup Ukuran dan Properti Awal (Memicu WMSize / UpdateLayout secara aman)
  Width := 400;
  Height := 42;
  Color := clWindow;
  TabStop := True;

  FThemeColor := btcPrimary;
  FNavStyle := bnsTabs;
  FCornerType := bctSmall;
  FTabIndex := 0;
  FHoverIndex := -1;
  FDownIndex := -1;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  // 4. Pengisian Nilai Default
  FItems.Add('Active');
  FItems.Add('Link');
  FItems.Add('Link');

  UpdateLayout;
end;

destructor TBsNavTabs.Destroy;
begin
  if Assigned(FItems) then
    FItems.Free;
  inherited Destroy;
end;

procedure TBsNavTabs.SetItems(AValue: TStringList);
begin
  if Assigned(FItems) and Assigned(AValue) then
    FItems.Assign(AValue);
end;

procedure TBsNavTabs.ItemsChanged(Sender: TObject);
begin
  if not Assigned(FItems) then Exit;
  if FTabIndex >= FItems.Count then FTabIndex := FItems.Count - 1;
  if FTabIndex < 0 then FTabIndex := 0;
  UpdateLayout;
  Invalidate;
end;

procedure TBsNavTabs.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsNavTabs.SetNavStyle(AValue: TBsNavStyle);
begin
  if FNavStyle = AValue then Exit;
  FNavStyle := AValue;
  UpdateLayout;
  Invalidate;
end;

procedure TBsNavTabs.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsNavTabs.SetTabIndex(AValue: Integer);
begin
  if FTabIndex = AValue then Exit;
  FTabIndex := AValue;
  if Assigned(FItems) then
  begin
    if FTabIndex >= FItems.Count then FTabIndex := FItems.Count - 1;
    if FTabIndex < 0 then FTabIndex := 0;
  end;
  Invalidate;
end;

procedure TBsNavTabs.UpdateLayout;
var
  Bmp: TBGRABitmap;
  i, CurrentX, TextW, PadX, PadY: Integer;
begin
  // Guard Clauses untuk keamanan Form Designer & Komponen
  if not Assigned(FItems) or (csLoading in ComponentState) then Exit;
  if (Width <= 0) or (Height <= 0) or (FItems.Count = 0) then Exit;

  SetLength(FItemRects, FItems.Count);

  // Padding standar Bootstrap (px)
  PadX := 16;
  PadY := 8;

  Bmp := TBGRABitmap.Create(1, 1);
  try
    Bmp.FontHeight := Font.Height;
    Bmp.FontName := Font.Name;

    CurrentX := 0;
    for i := 0 to FItems.Count - 1 do
    begin
      TextW := Bmp.TextSize(FItems[i]).cx;

      // Rect untuk interaksi dan render
      if FNavStyle = bnsPills then
      begin
        // Pills memiliki margin antar item
        FItemRects[i] := Rect(CurrentX, PadY, CurrentX + TextW + (PadX * 2), Height - PadY);
        Inc(CurrentX, TextW + (PadX * 2) + 8); // +8px margin kanan
      end
      else
      begin
        // Tabs & Underline saling menempel atau rapat
        FItemRects[i] := Rect(CurrentX, 0, CurrentX + TextW + (PadX * 2), Height);
        Inc(CurrentX, TextW + (PadX * 2));
      end;
    end;
  finally
    Bmp.Free;
  end;
end;

function TBsNavTabs.GetIndexAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(FItems) then Exit;

  for i := 0 to FItems.Count - 1 do
  begin
    if (i < Length(FItemRects)) and PtInRect(FItemRects[i], Point(X, Y)) then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TBsNavTabs.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateLayout;
end;

procedure TBsNavTabs.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  UpdateLayout;
  Invalidate;
end;

procedure TBsNavTabs.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoverIndex <> -1 then
  begin
    FHoverIndex := -1;
    Cursor := crDefault; // Restorasi kursor saat mouse keluar area
    Invalidate;
  end;
end;

procedure TBsNavTabs.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewIndex: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;

  NewIndex := GetIndexAt(X, Y);
  if FHoverIndex <> NewIndex then
  begin
    FHoverIndex := NewIndex;
    if FHoverIndex <> -1 then Cursor := crHandPoint else Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsNavTabs.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownIndex := GetIndexAt(X, Y);
    if (FDownIndex <> -1) and CanFocus then SetFocus;
    Invalidate;
  end;
end;

procedure TBsNavTabs.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpIndex: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if (Button = mbLeft) and (FDownIndex <> -1) then
  begin
    UpIndex := GetIndexAt(X, Y);
    if UpIndex = FDownIndex then
    begin
      if FTabIndex <> UpIndex then
      begin
        FTabIndex := UpIndex;
        if Assigned(FOnTabClick) then FOnTabClick(Self, FTabIndex);
      end;
    end;
    FDownIndex := -1;
    Invalidate;
  end;
end;

procedure TBsNavTabs.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewIdx: Integer;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled then Exit;
  if not Assigned(FItems) then Exit;

  NewIdx := FTabIndex;
  if Key = VK_LEFT then Dec(NewIdx)
  else if Key = VK_RIGHT then Inc(NewIdx);

  if (NewIdx <> FTabIndex) and (NewIdx >= 0) and (NewIdx < FItems.Count) then
  begin
    FTabIndex := NewIdx;
    Invalidate;
    if Assigned(FOnTabClick) then FOnTabClick(Self, FTabIndex);
  end;
end;

procedure TBsNavTabs.Paint;
var
  Bmp, ItemBmp: TBGRABitmap;
  BgColor, FillColor, BdColor, TxtColor, MainBdColor: TBGRAPixel;
  i, Radius: Integer;
  IsActive, IsHover: Boolean;
  IRect: TRect;
begin
  // Guard Clause Utama
  if not Assigned(FItems) or (csLoading in ComponentState) then Exit;
  if (Width <= 0) or (Height <= 0) or (FItems.Count = 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

//  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
    Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    MainBdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline); // #dee2e6

    // Render Garis Utama Bawah (Hanya untuk style Tabs & Underline)
    if FNavStyle in [bnsTabs, bnsUnderline] then
    begin
      Bmp.DrawLineAntialias(0, Height - 1, Width, Height - 1, MainBdColor, 1);
    end;

    for i := 0 to FItems.Count - 1 do
    begin
      if i >= Length(FItemRects) then Break;
      IRect := FItemRects[i];
      IsActive := (i = FTabIndex);
      IsHover := (i = FHoverIndex) or (i = FDownIndex);

      Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);
      FillColor := ColorToBGRA(clNone);
      BdColor := ColorToBGRA(clNone);
      TxtColor := TBsTheme.GetTextColor(btcPrimary, bssOutline); // Default link text (#0d6efd)

      if not Enabled then
      begin
        TxtColor := TBsTheme.GetDisabledTextColor;
      end
      else
      begin
        case FNavStyle of
          bnsTabs:
            begin
              if IsActive then
              begin
                FillColor := ColorToBGRA(ColorToRGB(Color));
                BdColor := MainBdColor;
                TxtColor := TBsTheme.GetTextColor(btcDark, bssSolid); // #495057
              end
              else if IsHover then
              begin
                FillColor := TBsTheme.GetBaseColor(btcLight);
                BdColor := MainBdColor;
                TxtColor := TBsTheme.GetHoverColor(btcPrimary);
              end;
            end;

          bnsPills:
            begin
              Radius := 100; // Pills selalu melengkung penuh (rounded-pill)
              if IsActive then
              begin
                FillColor := TBsTheme.GetBaseColor(FThemeColor);
                TxtColor := BS_TEXT_COLOR[FThemeColor];
              end
              else if IsHover then
              begin
                FillColor := TBsTheme.GetBaseColor(btcLight);
                TxtColor := TBsTheme.GetHoverColor(btcPrimary);
              end;
            end;

          bnsUnderline:
            begin
              if IsActive then
              begin
                TxtColor := TBsTheme.GetTextColor(btcDark, bssSolid);
                BdColor := TBsTheme.GetBaseColor(FThemeColor);
              end
              else if IsHover then
              begin
                TxtColor := TBsTheme.GetHoverColor(btcPrimary);
                BdColor := MainBdColor;
              end;
            end;
        end;
      end;

      // Rendering Per Item
      if FNavStyle = bnsTabs then
      begin
        if (IRect.Width > 0) and (IRect.Height > 0) then
        begin
          ItemBmp := TBGRABitmap.Create(IRect.Width, IRect.Height, ColorToBGRA(clNone));
          try
            if IsActive or IsHover then
            begin
              ItemBmp.FillRoundRectAntialias(0, 0, ItemBmp.Width - 1, ItemBmp.Height - 1 + Radius, Radius, Radius, FillColor);

              ItemBmp.DrawLineAntialias(Radius, 0, ItemBmp.Width - Radius - 1, 0, BdColor, 1);
              ItemBmp.DrawLineAntialias(0, Radius, 0, ItemBmp.Height, BdColor, 1);
              ItemBmp.DrawLineAntialias(ItemBmp.Width - 1, Radius, ItemBmp.Width - 1, ItemBmp.Height, BdColor, 1);

              ItemBmp.DrawLineAntialias(0, Radius, Radius, 0, BdColor, 1);
              ItemBmp.DrawLineAntialias(ItemBmp.Width - Radius - 1, 0, ItemBmp.Width - 1, Radius, BdColor, 1);
            end;

            TBsGraphics.DrawText(ItemBmp, Rect(0, 0, ItemBmp.Width, ItemBmp.Height), FItems[i], Font, TxtColor, bsaCenter, 0);

            Bmp.PutImage(IRect.Left, IRect.Top, ItemBmp, dmDrawWithTransparency);

            if IsActive then
              Bmp.DrawLineAntialias(IRect.Left + 1, Height - 1, IRect.Right - 2, Height - 1, FillColor, 1.5);

          finally
            ItemBmp.Free;
          end;
        end;
      end
      else if FNavStyle = bnsPills then
      begin
        if FillColor.alpha > 0 then
          Bmp.FillRoundRectAntialias(IRect.Left, IRect.Top, IRect.Right - 1, IRect.Bottom - 1, Radius, Radius, FillColor);

        TBsGraphics.DrawText(Bmp, IRect, FItems[i], Font, TxtColor, bsaCenter, 0);
      end
      else if FNavStyle = bnsUnderline then
      begin
        TBsGraphics.DrawText(Bmp, IRect, FItems[i], Font, TxtColor, bsaCenter, 0);

        if IsActive then
          Bmp.DrawLineAntialias(IRect.Left, Height - 2, IRect.Right, Height - 2, BdColor, 2.5)
        else if IsHover then
          Bmp.DrawLineAntialias(IRect.Left, Height - 1, IRect.Right, Height - 1, BdColor, 1);
      end;

      // Render Focus Ring (Hanya pada active tab jika kontrol fokus)
      if Focused and IsActive then
      begin
        if FNavStyle = bnsPills then
          TBsGraphics.DrawFocusRing(Bmp, IRect, Radius, TBsTheme.GetFocusRingColor(FThemeColor), 2)
        else
          TBsGraphics.DrawFocusRing(Bmp, Rect(IRect.Left + 2, IRect.Top + 2, IRect.Right - 2, IRect.Bottom - 2), 4, TBsTheme.GetFocusRingColor(FThemeColor), 2);
      end;
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
