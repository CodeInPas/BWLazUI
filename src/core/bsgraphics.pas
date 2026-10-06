unit bsgraphics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Graphics, Controls, BGRABitmap, BGRABitmapTypes,
  bstypes, bsthemes;

type
  { TBsGraphics: Kelas helper statis (Utility Class) untuk menangani semua
    kebutuhan rendering visual berbasis BGRABitmap dengan anti-aliasing. }
  TBsGraphics = class
  public
    { Menghitung radius presisi berdasarkan dimensi komponen dan tipe sudut (Corner Type) }
    class function GetRadius(const AHeight: Integer; const ACornerType: TBsCornerType;
      const ACustomRadius: Integer = 6): Integer; static; inline;

    { Merender background komponen (termasuk fill dan border) dengan AA }
    class procedure DrawBackground(ABitmap: TBGRABitmap; const ARect: TRect;
      const ARadius: Integer; const AFillColor, ABorderColor: TBGRAPixel;
      const ABorderWidth: Integer = 1); static;

    { Merender cincin fokus (Focus Ring) semi-transparan }
    class procedure DrawFocusRing(ABitmap: TBGRABitmap; const ARect: TRect;
      const ARadius: Integer; const AFocusColor: TBGRAPixel;
      const ARingWidth: Integer = 3); static;

    { Merender teks secara efisien dengan perataan dinamis (Alignment) }
    class procedure DrawText(ABitmap: TBGRABitmap; const ARect: TRect;
      const AText: string; AFont: TFont; const ATextColor: TBGRAPixel;
      const AAlign: TBsAlignment; const APaddingX: Integer = 8); static;
  end;

implementation

{ TBsGraphics }

class function TBsGraphics.GetRadius(const AHeight: Integer; const ACornerType: TBsCornerType;
  const ACustomRadius: Integer): Integer;
begin
  case ACornerType of
    bctSquare: Result := 0;
    bctSmall:  Result := 4;
    bctNormal: Result := ACustomRadius;
    bctLarge:  Result := 8;
    bctPill,
    bctCircle: Result := AHeight div 2;
  else
    Result := ACustomRadius;
  end;
end;

class procedure TBsGraphics.DrawBackground(ABitmap: TBGRABitmap; const ARect: TRect;
  const ARadius: Integer; const AFillColor, ABorderColor: TBGRAPixel;
  const ABorderWidth: Integer);
var
  R: TRect;
begin
  // Penyesuaian batas rektangel untuk akurasi pixel BGRABitmap
  R := Rect(ARect.Left, ARect.Top, ARect.Right - 1, ARect.Bottom - 1);

  // 1. Render Fill Background (jika ada warna/tidak transparan)
  if AFillColor.alpha > 0 then
    ABitmap.FillRoundRectAntialias(R.Left, R.Top, R.Right, R.Bottom, ARadius, ARadius, AFillColor);

  // 2. Render Border (Outline) jika width > 0
  if (ABorderWidth > 0) and (ABorderColor.alpha > 0) then
    ABitmap.RoundRectAntialias(R.Left, R.Top, R.Right, R.Bottom, ARadius, ARadius, ABorderColor, ABorderWidth);
end;

class procedure TBsGraphics.DrawFocusRing(ABitmap: TBGRABitmap; const ARect: TRect;
  const ARadius: Integer; const AFocusColor: TBGRAPixel; const ARingWidth: Integer);
var
  Offset: Single;
begin
  if AFocusColor.alpha = 0 then Exit;

  { Offset digunakan agar garis focus ring berada tepat di luar/dalam batas kontrol
    secara proporsional tanpa terpotong (clipped). }
  Offset := ARingWidth / 2;

  ABitmap.RoundRectAntialias(
    ARect.Left + Offset, ARect.Top + Offset,
    ARect.Right - 1 - Offset, ARect.Bottom - 1 - Offset,
    ARadius, ARadius, AFocusColor, ARingWidth
  );
end;

class procedure TBsGraphics.DrawText(ABitmap: TBGRABitmap; const ARect: TRect;
  const AText: string; AFont: TFont; const ATextColor: TBGRAPixel;
  const AAlign: TBsAlignment; const APaddingX: Integer);
var
  TextSize: TSize;
  DrawX, DrawY: Integer;
begin
  if Length(AText) = 0 then Exit;

  // Konfigurasi Font BGRABitmap mengikuti Font bawaan VCL/LCL
  ABitmap.FontName := AFont.Name;
  ABitmap.FontHeight := AFont.Height;
  ABitmap.FontStyle := AFont.Style;
  // ABitmap.FontAntialiasing := True; dihapus karena BGRABitmap sudah AA bawaan

  // Kalkulasi dimensi teks untuk perataan Vertikal & Horizontal
  TextSize := ABitmap.TextSize(AText);

  // Perataan Vertikal selalu di tengah (Center V)
  DrawY := ARect.Top + ((ARect.Bottom - ARect.Top - TextSize.cy) div 2);

  // Perataan Horizontal
  case AAlign of
    bsaStart:
      DrawX := ARect.Left + APaddingX;
    bsaCenter:
      DrawX := ARect.Left + ((ARect.Right - ARect.Left - TextSize.cx) div 2);
    bsaEnd:
      DrawX := ARect.Right - TextSize.cx - APaddingX;
    bsaJustify:
      DrawX := ARect.Left + APaddingX; // Fallback ke Start
  else
    DrawX := ARect.Left + APaddingX;
  end;

  // Eksekusi render teks dengan Alpha Blending
  ABitmap.TextOut(DrawX, DrawY, AText, ATextColor);
end;

end.
