unit bsaccordion;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Math, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsAccordion = class;

  { TBsAccordionItem: Item panel individual di dalam Accordion }
  TBsAccordionItem = class(TCustomControl)
  private
    FAccordion: TBsAccordion;
    FExpanded: Boolean;
    FHeaderHeight: Integer;
    FExpandedHeight: Integer;
    FThemeColor: TBsThemeColor;

    FIsHover: Boolean;
    FIsPressed: Boolean;
    FTimer: TTimer;
    FAnimSpeed: Integer;

    procedure SetExpanded(AValue: Boolean);
    procedure SetHeaderHeight(AValue: Integer);
    procedure SetExpandedHeight(AValue: Integer);
    procedure SetThemeColor(AValue: TBsThemeColor);

    procedure OnAnimTimer(Sender: TObject);

    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
  protected
    procedure Paint; override;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Toggle;
  published
    property Caption; // Digunakan sebagai teks Header
    property Expanded: Boolean read FExpanded write SetExpanded default False;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight default 44;
    property ExpandedHeight: Integer read FExpandedHeight write SetExpandedHeight default 150;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;

    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property ShowHint;
    property Visible;

    property OnClick;
  end;

  { TBsAccordion: Container utama untuk Bootstrap Accordion }
  TBsAccordion = class(TCustomControl)
  private
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FFlush: Boolean;
    FAutoCollapse: Boolean;
    FItems: TList;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetFlush(AValue: Boolean);

    procedure RegisterItem(AItem: TBsAccordionItem);
    procedure UnregisterItem(AItem: TBsAccordionItem);
    procedure NotifyExpand(AExpandedItem: TBsAccordionItem);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddItem(const ATitle: string): TBsAccordionItem;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property Flush: Boolean read FFlush write SetFlush default False;
    property AutoCollapse: Boolean read FAutoCollapse write FAutoCollapse default True;

    property Align;
    property Anchors;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsAccordion, TBsAccordionItem]);
end;

{ TBsAccordionItem }

constructor TBsAccordionItem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  Align := alTop;
  Height := 44; // Default terlipat (hanya header)
  Color := clWindow;

  FHeaderHeight := 44;
  FExpandedHeight := 150;
  FExpanded := False;
  FThemeColor := btcPrimary;

  FIsHover := False;
  FIsPressed := False;
  FAnimSpeed := 20;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 16;
  FTimer.Enabled := False;
  FTimer.OnTimer := @OnAnimTimer;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  if AOwner is TBsAccordion then
  begin
    FAccordion := TBsAccordion(AOwner);
    FAccordion.RegisterItem(Self);
    FThemeColor := FAccordion.ThemeColor;
  end;
end;

destructor TBsAccordionItem.Destroy;
begin
  if Assigned(FAccordion) then FAccordion.UnregisterItem(Self);
  FTimer.Free;
  inherited Destroy;
end;

procedure TBsAccordionItem.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  // Lindungi area header dari child controls
  Inc(Rect.Top, FHeaderHeight);
  // Beri padding untuk body
  Inc(Rect.Left, 16);
  Inc(Rect.Top, 16);
  Dec(Rect.Right, 16);
  Dec(Rect.Bottom, 16);
end;

procedure TBsAccordionItem.SetExpanded(AValue: Boolean);
begin
  if FExpanded = AValue then Exit;
  FExpanded := AValue;

  if FExpanded and Assigned(FAccordion) and FAccordion.AutoCollapse then
    FAccordion.NotifyExpand(Self);

  if csDesigning in ComponentState then
  begin
    if FExpanded then Height := FExpandedHeight else Height := FHeaderHeight;
    Invalidate;
  end
  else
    FTimer.Enabled := True;
end;

procedure TBsAccordionItem.SetHeaderHeight(AValue: Integer);
begin
  if FHeaderHeight = AValue then Exit;
  FHeaderHeight := AValue;
  if not FExpanded and not FTimer.Enabled then Height := FHeaderHeight;
  Invalidate;
end;

procedure TBsAccordionItem.SetExpandedHeight(AValue: Integer);
begin
  if FExpandedHeight = AValue then Exit;
  FExpandedHeight := AValue;
  if FExpanded and not FTimer.Enabled then Height := FExpandedHeight;
end;

procedure TBsAccordionItem.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsAccordionItem.Toggle;
begin
  SetExpanded(not FExpanded);
end;

procedure TBsAccordionItem.OnAnimTimer(Sender: TObject);
var
  NewH: Integer;
begin
  if FExpanded then
  begin
    NewH := Height + FAnimSpeed;
    if NewH >= FExpandedHeight then
    begin
      Height := FExpandedHeight;
      FTimer.Enabled := False;
      Invalidate;
    end
    else Height := NewH;
  end
  else
  begin
    NewH := Height - FAnimSpeed;
    if NewH <= FHeaderHeight then
    begin
      Height := FHeaderHeight;
      FTimer.Enabled := False;
      Invalidate;
    end
    else Height := NewH;
  end;
end;

procedure TBsAccordionItem.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  FIsHover := True;
  Invalidate;
end;

procedure TBsAccordionItem.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  FIsHover := False;
  FIsPressed := False;
  Invalidate;
end;

procedure TBsAccordionItem.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsAccordionItem.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  InHeader: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled then Exit;
  InHeader := Y <= FHeaderHeight;
  if FIsHover <> InHeader then
  begin
    FIsHover := InHeader;
    Invalidate;
  end;
end;

procedure TBsAccordionItem.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled and (Y <= FHeaderHeight) then
  begin
    FIsPressed := True;
    Invalidate;
  end;
end;

procedure TBsAccordionItem.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if FIsPressed and (Button = mbLeft) then
  begin
    FIsPressed := False;
    if Y <= FHeaderHeight then
    begin
      Toggle;
      if Assigned(OnClick) then OnClick(Self);
    end;
    Invalidate;
  end;
end;

procedure TBsAccordionItem.Resize;
begin
  inherited Resize;
  if FExpanded and not FTimer.Enabled and not (csLoading in ComponentState) then
    FExpandedHeight := Height;
end;

procedure TBsAccordionItem.Paint;
var
  Bmp, HdrBmp: TBGRABitmap;
  BgColor, HdrBgColor, TxtColor, BdColor: TBGRAPixel;
  HeaderRect: TRect;
  Cx, Cy: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    // Background Body
    Bmp.FillRectAntialias(0, FHeaderHeight, Width, Height, ColorToBGRA(ColorToRGB(Color)));

    // Warna Header
    if not Enabled then
    begin
      HdrBgColor := TBsTheme.GetDisabledColor;
      TxtColor := TBsTheme.GetDisabledTextColor;
    end
    else
    begin
      if FExpanded then
      begin
        HdrBgColor := TBsTheme.GetBaseColor(FThemeColor);
        HdrBgColor.alpha := 25; // Tint warna tema tipis
        TxtColor := TBsTheme.GetBaseColor(FThemeColor);
        if (FThemeColor = btcLight) or (FThemeColor = btcNone) then
          TxtColor := TBsTheme.GetBaseColor(btcDark);
      end
      else
      begin
        HdrBgColor := ColorToBGRA(ColorToRGB(Color)); // Default Putih/Window
        if FIsHover then HdrBgColor := TBsTheme.GetBaseColor(btcLight);
        TxtColor := TBsTheme.GetBaseColor(btcDark);
      end;
    end;

    // Render Header Background
    HeaderRect := Rect(0, 0, Width, FHeaderHeight);
    HdrBmp := TBGRABitmap.Create(Width, FHeaderHeight, HdrBgColor);
    try
      // Teks
      TBsGraphics.DrawText(HdrBmp, Rect(20, 0, Width - 40, FHeaderHeight), Caption, Font, TxtColor, bsaStart, 0);

      // Chevron (Icon panah V)
      Cx := Width - 24;
      Cy := FHeaderHeight div 2;
      if FExpanded then
      begin
        HdrBmp.DrawLineAntialias(Cx - 5, Cy + 2, Cx, Cy - 3, TxtColor, 2.0);
        HdrBmp.DrawLineAntialias(Cx, Cy - 3, Cx + 5, Cy + 2, TxtColor, 2.0);
      end
      else
      begin
        HdrBmp.DrawLineAntialias(Cx - 5, Cy - 2, Cx, Cy + 3, TxtColor, 2.0);
        HdrBmp.DrawLineAntialias(Cx, Cy + 3, Cx + 5, Cy - 2, TxtColor, 2.0);
      end;

      Bmp.PutImage(0, 0, HdrBmp, dmSet);
    finally
      HdrBmp.Free;
    end;

    // Render Border Bawah (Pemisah Antar Item)
    if Assigned(FAccordion) then
    begin
      BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
      // Jika expanded, gambar border pemisah antara header dan body
      if Height > FHeaderHeight then
        Bmp.DrawLineAntialias(0, FHeaderHeight - 1, Width, FHeaderHeight - 1, BdColor, 1);

      // Gambar border bawah item
      Bmp.DrawLineAntialias(0, Height - 1, Width, Height - 1, BdColor, 1);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

{ TBsAccordion }

constructor TBsAccordion.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];

  Width := 400;
  Height := 300;
  Color := clWindow;

  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FFlush := False;
  FAutoCollapse := True;

  FItems := TList.Create;
end;

destructor TBsAccordion.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TBsAccordion.SetThemeColor(AValue: TBsThemeColor);
var
  i: Integer;
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  for i := 0 to FItems.Count - 1 do
    TBsAccordionItem(FItems[i]).ThemeColor := FThemeColor;
  Invalidate;
end;

procedure TBsAccordion.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsAccordion.SetFlush(AValue: Boolean);
begin
  if FFlush = AValue then Exit;
  FFlush := AValue;
  Invalidate;
end;

procedure TBsAccordion.RegisterItem(AItem: TBsAccordionItem);
begin
  if FItems.IndexOf(AItem) < 0 then FItems.Add(AItem);
end;

procedure TBsAccordion.UnregisterItem(AItem: TBsAccordionItem);
begin
  FItems.Remove(AItem);
end;

procedure TBsAccordion.NotifyExpand(AExpandedItem: TBsAccordionItem);
var
  i: Integer;
  Item: TBsAccordionItem;
begin
  if not FAutoCollapse then Exit;

  for i := 0 to FItems.Count - 1 do
  begin
    Item := TBsAccordionItem(FItems[i]);
    if (Item <> AExpandedItem) and Item.Expanded then
      Item.Expanded := False;
  end;
end;

function TBsAccordion.AddItem(const ATitle: string): TBsAccordionItem;
begin
  Result := TBsAccordionItem.Create(Self);
  Result.Parent := Self;
  Result.Caption := ATitle;
  // Letakkan di posisi paling bawah
  Result.Top := 32000;
end;

procedure TBsAccordion.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, BdColor: TBGRAPixel;
  Radius: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    // Latar Container
    Bmp.FillRectAntialias(0, 0, Width, Height, ColorToBGRA(ColorToRGB(Color)));

    // Border Keseluruhan Accordion
    BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    if FFlush then Radius := 0
    else Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    if FFlush then
    begin
      Bmp.DrawLineAntialias(0, 0, Width, 0, BdColor, 1);
      Bmp.DrawLineAntialias(0, Height - 1, Width, Height - 1, BdColor, 1);
    end
    else
    begin
      // Outline radius
      Bmp.RoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, BdColor, 1);

      // Catatan: Jika ada radius, secara teknis kita perlu masking item pertama dan terakhir.
      // Untuk performa pada custom control container standar di LCL, margin luar dapat disimulasikan
      // dengan membiarkan item menggambar kotak dan kita menutupi pojoknya atau membiarkannya (overlap ringan).
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
