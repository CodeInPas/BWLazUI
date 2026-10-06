unit bsplaceholder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Math,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsPlaceholderAnimation: Tipe efek animasi transisi placeholder }
  TBsPlaceholderAnimation = (
    bpaNone,  // Statis, tanpa animasi
    bpaGlow,  // Efek memudar/berdenyut lambat (opacity berfluktuasi)
    bpaWave   // Efek sapuan gelombang cahaya bergerak dari kiri ke kanan
  );

  { TBsPlaceholderSize: Ketebalan vertikal placeholder }
  TBsPlaceholderSize = (
    bpsSmall, // Tipis (cocok untuk teks kecil)
    bpsNormal, // Standar (cocok untuk paragraf/teks reguler)
    bpsLarge  // Tebal (cocok untuk judul/elemen blok)
  );

  { TBsPlaceholder: Komponen skeletal loading indikator penanda konten sementara }
  TBsPlaceholder = class(TGraphicControl)
  private
    FTimer: TTimer;
    FThemeColor: TBsThemeColor;
    FAnimation: TBsPlaceholderAnimation;
    FCornerType: TBsCornerType;
    FSize: TBsPlaceholderSize;
    FActive: Boolean;
    FStep: Integer; // Frame counter untuk kalkulasi animasi

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetAnimation(AValue: TBsPlaceholderAnimation);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetSize(AValue: TBsPlaceholderSize);
    procedure SetActive(AValue: Boolean);

    procedure OnTimerTick(Sender: TObject);
    function GetCalculatedHeight: Integer;
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcSecondary;
    property Animation: TBsPlaceholderAnimation read FAnimation write SetAnimation default bpaGlow;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property SizeMode: TBsPlaceholderSize read FSize write SetSize default bpsNormal;
    property Active: Boolean read FActive write SetActive default True;

    { Properti Layout }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Visible;
    property Width;
    property Height; // Tinggi manual jika tidak ingin auto-kalkulasi
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsPlaceholder]);
end;

{ TBsPlaceholder }

constructor TBsPlaceholder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque]; // Hindari flicker

  // Nilai Default Placeholder Bootstrap 5
  Width := 150;
  FThemeColor := btcSecondary; // Default menggunakan secondary (abu-abu)
  FAnimation := bpaGlow;
  FCornerType := bctSmall;
  FSize := bpsNormal;
  FActive := True;
  FStep := 0;

  Height := GetCalculatedHeight;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 30; // ~33 FPS
  FTimer.OnTimer := @OnTimerTick;
  FTimer.Enabled := not (csDesigning in ComponentState) and FActive and (FAnimation <> bpaNone);
end;

destructor TBsPlaceholder.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

function TBsPlaceholder.GetCalculatedHeight: Integer;
begin
  case FSize of
    bpsSmall: Result := 12; // Placeholder-sm
    bpsNormal: Result := 18; // Default
    bpsLarge: Result := 24; // Placeholder-lg
  else
    Result := 18;
  end;
end;

procedure TBsPlaceholder.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsPlaceholder.SetAnimation(AValue: TBsPlaceholderAnimation);
begin
  if FAnimation = AValue then Exit;
  FAnimation := AValue;
  if not (csDesigning in ComponentState) then
    FTimer.Enabled := FActive and (FAnimation <> bpaNone);
  Invalidate;
end;

procedure TBsPlaceholder.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsPlaceholder.SetSize(AValue: TBsPlaceholderSize);
begin
  if FSize = AValue then Exit;
  FSize := AValue;
  Height := GetCalculatedHeight; // Sesuaikan tinggi otomatis
  Invalidate;
end;

procedure TBsPlaceholder.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  FActive := AValue;
  if not (csDesigning in ComponentState) then
    FTimer.Enabled := FActive and (FAnimation <> bpaNone);
  Invalidate;
end;

procedure TBsPlaceholder.Resize;
begin
  inherited Resize;
  Invalidate;
end;

procedure TBsPlaceholder.OnTimerTick(Sender: TObject);
begin
  // Hitung ulang posisi/opasitas animasi
  Inc(FStep, 4);
  if FStep >= 360 then FStep := 0; // Siklus 360 derajat untuk sin(x)
  Invalidate;
end;

procedure TBsPlaceholder.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, BaseColor, RenderColor: TBGRAPixel;
  Radius: Integer;
  AlphaMod, WavePos, WaveDist: Single;
  x, y: Integer;
  P: PBGRAPixel;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Latar kontrol untuk anti-aliasing yang bersih
  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    BaseColor := TBsTheme.GetBaseColor(FThemeColor);
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 4);

    if (not FActive) or (FAnimation = bpaNone) then
    begin
      // Statis: Tampilkan dengan opasitas 50%
      BaseColor.alpha := 128;
      TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, BaseColor, ColorToBGRA(clNone), 0);
    end
    else if FAnimation = bpaGlow then
    begin
      // Glow: Opasitas berdenyut menggunakan gelombang sinus (50% hingga 100% dari base.alpha)
      // Sin(x) menghasilkan -1..1, diubah menjadi 0..1, lalu diskala ke opasitas
      AlphaMod := (Sin(FStep * Pi / 180) + 1.0) / 2.0;
      RenderColor := BaseColor;
      // Opasitas berfluktuasi antara ~64 (25%) dan ~160 (62%)
      RenderColor.alpha := Round(64 + (AlphaMod * 96));
      TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, RenderColor, ColorToBGRA(clNone), 0);
    end
    else if FAnimation = bpaWave then
    begin
      // 1. Gambar Base Rectangle (Latar gelap/redup dari Placeholder)
      RenderColor := BaseColor;
      RenderColor.alpha := 64; // Opasitas dasar sangat rendah (25%)
      TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, RenderColor, ColorToBGRA(clNone), 0);

      // 2. Kalkulasi Sapuan Gelombang (Wave)
      // Wave bergerak dari -Width ke Width * 2
      WavePos := (FStep / 360) * (Width * 2) - (Width div 2);

      // Akses piksel langsung untuk efisiensi efek gradien blending O(N*M)
      for y := 0 to Height - 1 do
      begin
        P := Bmp.Scanline[y];
        for x := 0 to Width - 1 do
        begin
          // Hitung jarak X relatif terhadap titik tengah WavePos
          WaveDist := Abs(x - WavePos);

          // Jika X berada di dalam area gradien (lebar sapuan ~ 150px)
          if WaveDist < 75 then
          begin
            // Hitung intensitas (terang di tengah, memudar di tepi)
            AlphaMod := 1.0 - (WaveDist / 75.0);

            // Tambah kecerahan lokal menggunakan fungsi internal BGRA
            if AlphaMod > 0 then
            begin
               P^.red := Min(255, P^.red + Round((BaseColor.red - P^.red) * AlphaMod));
               P^.green := Min(255, P^.green + Round((BaseColor.green - P^.green) * AlphaMod));
               P^.blue := Min(255, P^.blue + Round((BaseColor.blue - P^.blue) * AlphaMod));
            end;
          end;
          Inc(P);
        end;
      end;
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
