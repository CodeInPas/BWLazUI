unit bsbadges;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsBadge: Komponen Label/Badge bergaya Bootstrap 5 }
  TBsBadge = class(TCustomControl)
  private
    FThemeColor: TBsThemeColor;
    FStyle: TBsStyle;
    FIsPill: Boolean;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetStyle(AValue: TBsStyle);
    procedure SetIsPill(AValue: Boolean);

    { LCL Messages }
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithThemeSpace: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property Style: TBsStyle read FStyle write SetStyle default bssSolid;
    property IsPill: Boolean read FIsPill write SetIsPill default False;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property AutoSize default True;
    property Caption;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property ShowHint;
    property Visible;

    { Events }
    property OnClick;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsBadge]);
end;

{ TBsBadge }

constructor TBsBadge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  AutoSize := True;
  Color := clWindow;

  FThemeColor := btcPrimary;
  FStyle := bssSolid;
  FIsPill := False;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Font.Style := [fsBold]; // Badge standar menggunakan teks tebal
end;

procedure TBsBadge.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsBadge.SetStyle(AValue: TBsStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TBsBadge.SetIsPill(AValue: Boolean);
begin
  if FIsPill = AValue then Exit;
  FIsPill := AValue;
  Invalidate;
end;

procedure TBsBadge.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  InvalidatePreferredSize;
  AdjustSize;
  Invalidate;
end;

procedure TBsBadge.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  InvalidatePreferredSize;
  AdjustSize;
  Invalidate;
end;

procedure TBsBadge.CalculatePreferredSize(var PreferredWidth, PreferredHeight: Integer; WithThemeSpace: Boolean);
var
  Bmp: TBGRABitmap;
  PadX, PadY: Integer;
begin
  if Length(Caption) = 0 then
  begin
    PreferredWidth := 0;
    PreferredHeight := 0;
    Exit;
  end;


  if FIsPill then
    PadX := 12 // Pill butuh padding horizontal lebih besar
  else
    PadX := 8;
  PadY := 4;

  Bmp := TBGRABitmap.Create(1, 1);
  try
    Bmp.FontName := Font.Name;
    Bmp.FontHeight := Font.Height;
    Bmp.FontStyle := Font.Style;

    PreferredWidth := Bmp.TextSize(Caption).cx + (PadX * 2);
    PreferredHeight := Bmp.TextSize(Caption).cy + (PadY * 2);
  finally
    Bmp.Free;
  end;
end;

procedure TBsBadge.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, FillColor, BdColor, TxtColor: TBGRAPixel;
  Radius: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

 // Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    if not Enabled then
    begin
      FillColor := TBsTheme.GetDisabledColor;
      BdColor := FillColor;
      TxtColor := TBsTheme.GetDisabledTextColor;
    end
    else
    begin
      if FStyle = bssSolid then
      begin
        FillColor := TBsTheme.GetBaseColor(FThemeColor);
        BdColor := FillColor;
        TxtColor := BS_TEXT_COLOR[FThemeColor];
      end
      else // bssOutline
      begin
        FillColor := ColorToBGRA(ColorToRGB(Color));
        BdColor := TBsTheme.GetBaseColor(FThemeColor);
        TxtColor := TBsTheme.GetTextColor(FThemeColor, FStyle);
      end;
    end;

    if FIsPill then
      Radius := Height div 2
    else
      Radius := 4; // Default border-radius Bootstrap (.badge)

    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);
    TBsGraphics.DrawText(Bmp, ClientRect, Caption, Font, TxtColor, bsaCenter, 0);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.

