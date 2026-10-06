unit bsspinner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Math,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes;

type
  { TBsSpinnerType: Jenis animasi spinner }
  TBsSpinnerType = (
    bstBorder, // Cincin berputar dengan celah transparan
    bstGrow    // Lingkaran yang membesar dan memudar
  );

  { TBsSpinner: Komponen indikator loading bergaya Bootstrap }
  TBsSpinner = class(TGraphicControl)
  private
    FTimer: TTimer;
    FThemeColor: TBsThemeColor;
    FSpinnerType: TBsSpinnerType;
    FActive: Boolean;
    FStep: Integer; // Fase animasi (0..359 derajat)
    FLineWidth: Integer;
    FInterval: Integer;

    procedure SetActive(AValue: Boolean);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetSpinnerType(AValue: TBsSpinnerType);
    procedure SetLineWidth(AValue: Integer);
    procedure SetInterval(AValue: Integer);

    procedure OnTimerTick(Sender: TObject);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write SetActive default True;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property SpinnerType: TBsSpinnerType read FSpinnerType write SetSpinnerType default bstBorder;
    property LineWidth: Integer read FLineWidth write SetLineWidth default 4;
    property Interval: Integer read FInterval write SetInterval default 30;

    { Properti bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Visible;
    property Color;
    property ParentColor;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsSpinner]);
end;

{ TBsSpinner }

constructor TBsSpinner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  // Ukuran default Spinner
  Width := 32;
  Height := 32;

  // Nilai Default
  FThemeColor := btcPrimary;
  FSpinnerType := bstBorder;
  FActive := True;
  FLineWidth := 4;
  FInterval := 30;
  FStep := 0;

  // Inisialisasi Timer Animasi
  FTimer := TTimer.Create(Self);
  FTimer.Interval := FInterval;
  FTimer.OnTimer := @OnTimerTick;
  FTimer.Enabled := not (csDesigning in ComponentState) and FActive;
end;

destructor TBsSpinner.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TBsSpinner.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  FActive := AValue;
  if not (csDesigning in ComponentState) then
    FTimer.Enabled := FActive;
  Invalidate;
end;

procedure TBsSpinner.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsSpinner.SetSpinnerType(AValue: TBsSpinnerType);
begin
  if FSpinnerType = AValue then Exit;
  FSpinnerType := AValue;
  FStep := 0; // Reset animasi
  Invalidate;
end;

procedure TBsSpinner.SetLineWidth(AValue: Integer);
begin
  if FLineWidth = AValue then Exit;
  FLineWidth := AValue;
  Invalidate;
end;

procedure TBsSpinner.SetInterval(AValue: Integer);
begin
  if FInterval = AValue then Exit;
  FInterval := AValue;
  FTimer.Interval := FInterval;
end;

procedure TBsSpinner.OnTimerTick(Sender: TObject);
begin
  // Hitung rotasi atau pembesaran skala
  FStep := (FStep + 12) mod 360;
  Invalidate; // Picu lukis ulang di setiap tick
end;

procedure TBsSpinner.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, BaseColor: TBGRAPixel;
  Cx, Cy, R, i: Integer;
  RadAngle, Scale: Single;
  Pts: array of TPointF;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Ambil warna latar belakang untuk proses blending anti-aliasing yang mulus
  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

 // Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    BaseColor := TBsTheme.GetBaseColor(FThemeColor);
    Cx := Width div 2;
    Cy := Height div 2;
    R := Min(Cx, Cy) - FLineWidth;
    if R < 1 then R := 1;

    if FSpinnerType = bstBorder then
    begin
      // Gaya Border: Gambar garis lengkung (Arc) sebesar ~270 derajat
      SetLength(Pts, 31);
      for i := 0 to 30 do
      begin
        // Kalkulasi sudut 9 derajat per segmen (30 * 9 = 270 derajat)
        RadAngle := (FStep + (i * 9)) * Pi / 180;
        Pts[i].x := Cx + R * Cos(RadAngle);
        Pts[i].y := Cy + R * Sin(RadAngle);
      end;
      Bmp.DrawPolyLineAntialias(Pts, BaseColor, FLineWidth);
    end
    else if FSpinnerType = bstGrow then
    begin
      // Gaya Grow: Lingkaran yang ukurannya membesar lalu memudar
      Scale := FStep / 360;
      if Scale <= 0 then Scale := 0.01;

      // Alpha memudar berbanding terbalik dengan skala pembesaran
      BaseColor.alpha := Round(255 * (1.0 - Scale));
      Bmp.FillEllipseAntialias(Cx, Cy, R * Scale, R * Scale, BaseColor);
    end;

    // Render ke kanvas utama tanpa transparansi tambahan karena latar sudah di-blend
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
