unit bstooltip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsTooltip = class; // Forward declaration

  { TBsHintWindow: Jendela popup kustom untuk merender Tooltip Bootstrap }
  TBsHintWindow = class(THintWindow)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
  end;

  { TBsTooltip: Komponen non-visual untuk mengaktifkan gaya tooltip global }
  TBsTooltip = class(TComponent)
  private
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FGlobal: Boolean;
    procedure SetGlobal(AValue: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write FThemeColor default btcDark;
    property CornerType: TBsCornerType read FCornerType write FCornerType default bctSmall;
    property Global: Boolean read FGlobal write SetGlobal default False;
  end;

procedure Register;

implementation

var
  OldHintClass: THintWindowClass;
  ActiveBsTooltip: TBsTooltip = nil;

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsTooltip]);
end;

{ TBsHintWindow }

constructor TBsHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Tipografi standar Tooltip
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;

  // Menggunakan warna standar sistem sebagai fallback karena THintWindow
  // di LCL tidak mendukung property TransparentColor secara bawaan.
  Color := clWindow;
end;

function TBsHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: Pointer): TRect;
var
  W, H: Integer;
begin
  // Efisiensi O(1) dengan fungsi native LCL sebelum dirender oleh BGRABitmap
  W := Canvas.TextWidth(AHint);
  H := Canvas.TextHeight(AHint);

  // Padding standar Bootstrap (X: 10px, Y: 6px) * 2 sisi
  Result := Rect(0, 0, W + 20, H + 12);
end;

procedure TBsHintWindow.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, TxtColor: TBGRAPixel;
  Radius: Integer;
begin
  // Buat kanvas dengan warna fallback
  Bmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(Color));
  try
    if Assigned(ActiveBsTooltip) then
    begin
      BgColor := TBsTheme.GetBaseColor(ActiveBsTooltip.ThemeColor);
      TxtColor := TBsTheme.GetTextColor(ActiveBsTooltip.ThemeColor, bssSolid);
      Radius := TBsGraphics.GetRadius(Height, ActiveBsTooltip.CornerType, 4);
    end
    else
    begin
      // Default Bootstrap Tooltip: Latar gelap, teks putih
      BgColor := TBsTheme.GetBaseColor(btcDark);
      TxtColor := BS_TEXT_COLOR[btcDark];
      Radius := 4;
    end;

    // Tambahkan transparansi khas tooltip (opacity 90%)
    BgColor.alpha := 230;

    // Render kotak tooltip melengkung (Rounded Bubble)
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, BgColor, ColorToBGRA(clNone), 0);

    // Render teks rata tengah
    TBsGraphics.DrawText(Bmp, ClientRect, Caption, Canvas.Font, TxtColor, bsaCenter, 0);

    // Transfer ke window
    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

{ TBsTooltip }

constructor TBsTooltip.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThemeColor := btcDark; // Standar Bootstrap Tooltip
  FCornerType := bctSmall;
  FGlobal := False;
end;

destructor TBsTooltip.Destroy;
begin
  SetGlobal(False); // Kembalikan state sebelum dihancurkan
  inherited Destroy;
end;

procedure TBsTooltip.SetGlobal(AValue: Boolean);
begin
  if FGlobal = AValue then Exit;
  FGlobal := AValue;

  if not (csDesigning in ComponentState) then
  begin
    if FGlobal then
    begin
      ActiveBsTooltip := Self;
      OldHintClass := HintWindowClass;
      HintWindowClass := TBsHintWindow;

      // Paksa LCL untuk memuat ulang kelas hint
      if Assigned(Application) then
      begin
        Application.ShowHint := False;
        Application.ShowHint := True;
      end;
    end
    else
    begin
      if ActiveBsTooltip = Self then
      begin
        HintWindowClass := OldHintClass;
        ActiveBsTooltip := nil;

        if Assigned(Application) then
        begin
          Application.ShowHint := False;
          Application.ShowHint := True;
        end;
      end;
    end;
  end;
end;

end.
