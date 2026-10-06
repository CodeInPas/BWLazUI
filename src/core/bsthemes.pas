unit bsthemes;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, bstypes, BGRABitmapTypes;

type
  { Utilitas statis untuk manajemen warna tema Bootstrap 5 O(1) }
  TBsTheme = record
  public
    class function GetBaseColor(ATheme: TBsThemeColor): TBGRAPixel; static; inline;
    class function GetHoverColor(ATheme: TBsThemeColor): TBGRAPixel; static;
    class function GetActiveColor(ATheme: TBsThemeColor): TBGRAPixel; static;
    class function GetDisabledColor: TBGRAPixel; static; inline;
    class function GetDisabledTextColor: TBGRAPixel; static; inline;
    class function GetTextColor(ATheme: TBsThemeColor; AStyle: TBsStyle): TBGRAPixel; static;
    class function GetBorderColor(ATheme: TBsThemeColor; AStyle: TBsStyle): TBGRAPixel; static;
    class function GetFocusRingColor(ATheme: TBsThemeColor): TBGRAPixel; static;
  end;

const
  { Palet Dasar HEX Bootstrap 5 dikonversi ke struktur TBGRAPixel }
  BS_PALETTE: array[TBsThemeColor] of TBGRAPixel = (
    (blue: 253; green: 110; red:  13; alpha: 255), // btcPrimary   (#0D6EFD)
    (blue: 125; green: 117; red: 108; alpha: 255), // btcSecondary (#6C757D)
    (blue:  84; green: 135; red:  25; alpha: 255), // btcSuccess   (#198754)
    (blue:  69; green:  53; red: 220; alpha: 255), // btcDanger    (#DC3545)
    (blue:   7; green: 193; red: 255; alpha: 255), // btcWarning   (#FFC107)
    (blue: 240; green: 202; red:  13; alpha: 255), // btcInfo      (#0DCAF0)
    (blue: 250; green: 249; red: 248; alpha: 255), // btcLight     (#F8F9FA)
    (blue:  41; green:  37; red:  33; alpha: 255), // btcDark      (#212529)
    (blue: 253; green: 110; red:  13; alpha: 255), // btcLink      (#0D6EFD)
    (blue:   0; green:   0; red:   0; alpha:   0)  // btcNone      (Transparan)
  );

  { Warna Teks Kontras Tinggi (YIQ Color Space Approximation) }
  BS_TEXT_COLOR: array[TBsThemeColor] of TBGRAPixel = (
    (blue: 255; green: 255; red: 255; alpha: 255), // btcPrimary   (Putih)
    (blue: 255; green: 255; red: 255; alpha: 255), // btcSecondary (Putih)
    (blue: 255; green: 255; red: 255; alpha: 255), // btcSuccess   (Putih)
    (blue: 255; green: 255; red: 255; alpha: 255), // btcDanger    (Putih)
    (blue:   0; green:   0; red:   0; alpha: 255), // btcWarning   (Hitam)
    (blue:   0; green:   0; red:   0; alpha: 255), // btcInfo      (Hitam)
    (blue:   0; green:   0; red:   0; alpha: 255), // btcLight     (Hitam)
    (blue: 255; green: 255; red: 255; alpha: 255), // btcDark      (Putih)
    (blue: 253; green: 110; red:  13; alpha: 255), // btcLink      (Biru)
    (blue:   0; green:   0; red:   0; alpha: 255)  // btcNone      (Hitam)
  );

implementation

{ Algoritma blending RGB cepat (Factor 0..255) untuk efisiensi CPU }
function FastBlendBlack(C: TBGRAPixel; Factor: Integer): TBGRAPixel; inline;
begin
  Result.red   := (C.red   * (255 - Factor)) shr 8;
  Result.green := (C.green * (255 - Factor)) shr 8;
  Result.blue  := (C.blue  * (255 - Factor)) shr 8;
  Result.alpha := C.alpha;
end;

function FastBlendWhite(C: TBGRAPixel; Factor: Integer): TBGRAPixel; inline;
begin
  Result.red   := C.red   + (((255 - C.red)   * Factor) shr 8);
  Result.green := C.green + (((255 - C.green) * Factor) shr 8);
  Result.blue  := C.blue  + (((255 - C.blue)  * Factor) shr 8);
  Result.alpha := C.alpha;
end;

{ TBsTheme }

class function TBsTheme.GetBaseColor(ATheme: TBsThemeColor): TBGRAPixel;
begin
  Result := BS_PALETTE[ATheme];
end;

class function TBsTheme.GetHoverColor(ATheme: TBsThemeColor): TBGRAPixel;
begin
  { Hover: Gelapkan base color 15% (~38/255). Warna gelap diterangkan. }
  if ATheme = btcDark then
    Result := FastBlendWhite(BS_PALETTE[ATheme], 38)
  else
    Result := FastBlendBlack(BS_PALETTE[ATheme], 38);
end;

class function TBsTheme.GetActiveColor(ATheme: TBsThemeColor): TBGRAPixel;
begin
  { Active: Gelapkan base color 20% (~51/255). Warna gelap diterangkan. }
  if ATheme = btcDark then
    Result := FastBlendWhite(BS_PALETTE[ATheme], 51)
  else
    Result := FastBlendBlack(BS_PALETTE[ATheme], 51);
end;

class function TBsTheme.GetDisabledColor: TBGRAPixel;
begin
  { #E9ECEF - Background disabled standar }
  Result.red := 233; Result.green := 236; Result.blue := 239; Result.alpha := 255;
end;

class function TBsTheme.GetDisabledTextColor: TBGRAPixel;
begin
  { #6C757D - Teks disabled }
  Result := BS_PALETTE[btcSecondary];
end;

class function TBsTheme.GetTextColor(ATheme: TBsThemeColor; AStyle: TBsStyle): TBGRAPixel;
begin
  { Style outline/soft menggunakan warna tema untuk teks }
  if AStyle in [bssOutline, bssSoft] then
    Result := BS_PALETTE[ATheme]
  else
    Result := BS_TEXT_COLOR[ATheme];
end;

class function TBsTheme.GetBorderColor(ATheme: TBsThemeColor; AStyle: TBsStyle): TBGRAPixel;
begin
  { Beri kontras border tipis untuk tema Light }
  if ATheme = btcLight then
    Result := FastBlendBlack(BS_PALETTE[btcLight], 25)
  else
    Result := BS_PALETTE[ATheme];
end;

class function TBsTheme.GetFocusRingColor(ATheme: TBsThemeColor): TBGRAPixel;
begin
  { Focus ring menggunakan warna tema dengan opacity 25% (Alpha 64) }
  Result := BS_PALETTE[ATheme];
  if ATheme <> btcNone then
    Result.alpha := 64;
end;

end.
