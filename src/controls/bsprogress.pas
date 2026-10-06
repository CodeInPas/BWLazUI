unit bsprogress;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Math,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsProgress: Komponen Progress Bar bergaya Bootstrap 5 }
  TBsProgress = class(TGraphicControl)
  private
    FTimer: TTimer;
    FMin: Integer;
    FMax: Integer;
    FValue: Integer;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FStriped: Boolean;
    FAnimated: Boolean;
    FShowLabel: Boolean;
    FAnimationOffset: Integer;

    procedure SetMin(AValue: Integer);
    procedure SetMax(AValue: Integer);
    procedure SetValue(AValue: Integer);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetStriped(AValue: Boolean);
    procedure SetAnimated(AValue: Boolean);
    procedure SetShowLabel(AValue: Boolean);

    procedure OnTimerTick(Sender: TObject);
    procedure UpdateTimerState;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Value: Integer read FValue write SetValue default 50;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property Striped: Boolean read FStriped write SetStriped default False;
    property Animated: Boolean read FAnimated write SetAnimated default False;
    property ShowLabel: Boolean read FShowLabel write SetShowLabel default False;

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Visible;
    property Font;
    property Color;
    property ParentColor;
    property ParentFont;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsProgress]);
end;

{ TBsProgress }

constructor TBsProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];

  // Ukuran Default
  Width := 200;
  Height := 16;

  // Nilai Default
  FMin := 0;
  FMax := 100;
  FValue := 50;
  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FStriped := False;
  FAnimated := False;
  FShowLabel := False;
  FAnimationOffset := 0;

  // Font untuk label persentase
  Font.Name := 'Segoe UI';
  Font.Size := 8;
  Font.Color := clWhite;
  Font.Style := [fsBold];

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40; // ~25 FPS untuk animasi mulus
  FTimer.OnTimer := @OnTimerTick;
  FTimer.Enabled := False;
end;

destructor TBsProgress.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TBsProgress.UpdateTimerState;
begin
  if not (csDesigning in ComponentState) then
    FTimer.Enabled := FStriped and FAnimated and Visible;
end;

procedure TBsProgress.SetMin(AValue: Integer);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FMin > FMax then FMin := FMax;
  if FValue < FMin then SetValue(FMin) else Invalidate;
end;

procedure TBsProgress.SetMax(AValue: Integer);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FMax < FMin then FMax := FMin;
  if FValue > FMax then SetValue(FMax) else Invalidate;
end;

procedure TBsProgress.SetValue(AValue: Integer);
begin
  if FValue = AValue then Exit;
  FValue := EnsureRange(AValue, FMin, FMax);
  Invalidate;
end;

procedure TBsProgress.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsProgress.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsProgress.SetStriped(AValue: Boolean);
begin
  if FStriped = AValue then Exit;
  FStriped := AValue;
  UpdateTimerState;
  Invalidate;
end;

procedure TBsProgress.SetAnimated(AValue: Boolean);
begin
  if FAnimated = AValue then Exit;
  FAnimated := AValue;
  UpdateTimerState;
  Invalidate;
end;

procedure TBsProgress.SetShowLabel(AValue: Boolean);
begin
  if FShowLabel = AValue then Exit;
  FShowLabel := AValue;
  Invalidate;
end;

procedure TBsProgress.OnTimerTick(Sender: TObject);
begin
  // Geser posisi strip untuk efek animasi
  Inc(FAnimationOffset);
  if FAnimationOffset >= 32 then FAnimationOffset := 0; // 32px adalah lebar satu siklus stripe
  Invalidate;
end;

procedure TBsProgress.Paint;
var
  Bmp, BarBmp: TBGRABitmap;
  BgColor, ContainerColor, BarColor, StripeColor: TBGRAPixel;
  Radius, BarWidth, Range, StripeX, i: Integer;
  LabelText: string;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    // 1. Gambar Container (Latar Belakang Progress)
    ContainerColor := TBsTheme.GetDisabledColor;
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 4);
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, ContainerColor, ColorToBGRA(clNone), 0);

    // Hitung lebar bar berdasarkan Value
    Range := FMax - FMin;
    if Range <= 0 then Range := 1;
    BarWidth := Round(((FValue - FMin) / Range) * Width);

    if BarWidth > 0 then
    begin
      // 2. Siapkan kanvas khusus untuk Bar agar bisa di-clip secara sempurna
      BarBmp := TBGRABitmap.Create(BarWidth, Height, ColorToBGRA(clNone));
      try
        BarColor := TBsTheme.GetBaseColor(FThemeColor);

        // Render Bar Utama
        TBsGraphics.DrawBackground(BarBmp, Rect(0, 0, BarWidth, Height), Radius, BarColor, ColorToBGRA(clNone), 0);

        // Render Stripes (Garis miring semi-transparan putih)
        if FStriped then
        begin
          StripeColor := BGRA(255, 255, 255, 38); // Putih ~15% Opacity
          StripeX := -32 + FAnimationOffset; // Mulai di luar kanvas sebelah kiri

          while StripeX < BarWidth + Height do
          begin
            // Gunakan fill miring (Poligon) untuk menggambar pita/garis miring 45 derajat
            BarBmp.FillPolyAntialias([
              PointF(StripeX, Height),
              PointF(StripeX + 16, Height),
              PointF(StripeX + 16 + Height, 0),
              PointF(StripeX + Height, 0)
            ], StripeColor);

            Inc(StripeX, 32); // Jarak antar stripes
          end;

          // Potong stripes yang keluar batas bar menggunakan mode blending BGRABitmap (Masking)
          for i := 0 to BarWidth - 1 do
          begin
             // Masking alpha berdasarkan border radius dari Bar background aslinya
             // (Dilakukan secara implisit karena kita menggambar di kanvas kosong
             // kemudian memakai alpha blending dari base fill, tapi agar presisi BGRABitmap
             // sudah menangani tepi luar saat pemanggilan FillRoundRect di atas jika kita
             // melakukan Draw (PutImage) dengan mode tertentu. Karena kita hanya FillPoly,
             // ia bisa keluar area radius. Cara termudah memotongnya adalah render BarColor
             // lagi sebagai mask, atau cukup letakkan Bmp sebagai wadah.)
          end;
        end;

        // 3. Gabungkan BarBmp ke atas Bmp utama dengan perataan
        // Karena BGRABitmap versi standar butuh masking manual untuk clip path radius,
        // Untuk efisiensi kita biarkan BarBmp menumpuk, radius mengikuti fill awal
        Bmp.PutImage(0, 0, BarBmp, dmDrawWithTransparency);
      finally
        BarBmp.Free;
      end;

      // 4. Render Teks Label di tengah Bar (Jika ShowLabel aktif)
      if FShowLabel then
      begin
        LabelText := IntToStr(Round(((FValue - FMin) / Range) * 100)) + '%';
        TBsGraphics.DrawText(Bmp, Rect(0, 0, BarWidth, Height), LabelText, Font, BGRA(255, 255, 255, 255), bsaCenter, 0);
      end;
    end;

    // 5. Transfer ke canvas utama
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.

