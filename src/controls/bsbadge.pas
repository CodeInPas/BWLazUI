unit bsbadge;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsBadge: Komponen indikator status/label berukuran kecil dan ringan.
    Diturunkan dari TGraphicControl karena tidak memerlukan interaksi (Window Handle). }
  TBsBadge = class(TGraphicControl)
  private
    FThemeColor: TBsThemeColor;
    FStyle: TBsStyle;
    FCornerType: TBsCornerType;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetStyle(AValue: TBsStyle);
    procedure SetCornerType(AValue: TBsCornerType);

    { Mencegat perubahan properti bawaan untuk memicu lukis ulang (repaint) }
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Message: TLMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    { Properti kustom Bootstrap }
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property Style: TBsStyle read FStyle write SetStyle default bssSolid;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;

    { Properti bawaan LCL }
    property Align;
    property Anchors;
    property Caption;
    property Color;
    property Font;
    property ParentColor;
    property ParentFont;
    property Visible;
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
  ControlStyle := ControlStyle + [csOpaque]; // Optimasi rendering

  // Ukuran default badge
  Width := 50;
  Height := 20;

  // Nilai default
  FThemeColor := btcPrimary;
  FStyle := bssSolid;
  FCornerType := bctSmall;

  // Font default meniru tipografi Bootstrap
  Font.Name := 'Segoe UI';
  Font.Size := 8;
  Font.Style := [fsBold];
end;

procedure TBsBadge.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate; // Picu lukis ulang saat warna berubah
end;

procedure TBsBadge.SetStyle(AValue: TBsStyle);
begin
  if FStyle = AValue then Exit;
  FStyle := AValue;
  Invalidate;
end;

procedure TBsBadge.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsBadge.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsBadge.CMFontChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsBadge.Paint;
var
  Bmp: TBGRABitmap;
  FillColor, BorderColor, TextColor: TBGRAPixel;
  Radius, BorderWidth: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Inisialisasi buffer kanvas
  Bmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(ColorToRGB(Self.Parent.Color)));
  try
    // 1. Tentukan warna berdasarkan Style & Theme
    if FStyle = bssOutline then
    begin
      FillColor := ColorToBGRA(clNone, 0); // Transparan
      BorderColor := TBsTheme.GetBorderColor(FThemeColor, FStyle);
      BorderWidth := 1;
    end
    else
    begin
      FillColor := TBsTheme.GetBaseColor(FThemeColor);
      BorderColor := FillColor;
      BorderWidth := 0;
    end;

    TextColor := TBsTheme.GetTextColor(FThemeColor, FStyle);

    // 2. Kalkulasi Radius
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 4);

    // 3. Render Background & Border
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BorderColor, BorderWidth);

    // 4. Render Teks (Caption) di tengah (Center)
    TBsGraphics.DrawText(Bmp, ClientRect, Caption, Font, TextColor, bsaCenter, 4);

    // 5. Transfer ke kanvas kontrol utama
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free; // Cegah memory leak
  end;
end;

end.

