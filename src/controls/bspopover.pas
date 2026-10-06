unit bspopover;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, Types, LCLType, LMessages,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsPopover = class;

  { TBsPopoverWindow: Jendela mengambang (floating) kustom }
  TBsPopoverWindow = class(THintWindow)
  private
    FPopover: TBsPopover;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
  end;

  { TBsPopover: Komponen manajer Popover Bootstrap }
  TBsPopover = class(TComponent)
  private
    FWindow: TBsPopoverWindow;
    FTitle: string;
    FContent: string;
    FPlacement: TBsPlacement;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FMaxWidth: Integer;

    procedure SetTitle(const AValue: string);
    procedure SetContent(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Show(TargetControl: TControl);
    procedure Hide;
  published
    property Title: string read FTitle write SetTitle;
    property Content: string read FContent write SetContent;
    property Placement: TBsPlacement read FPlacement write FPlacement default bspTop;
    property ThemeColor: TBsThemeColor read FThemeColor write FThemeColor default btcLight;
    property CornerType: TBsCornerType read FCornerType write FCornerType default bctSmall;
    property MaxWidth: Integer read FMaxWidth write FMaxWidth default 276;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsPopover]);
end;

{ TBsPopoverWindow }

constructor TBsPopoverWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Menggunakan warna standar sistem sebagai fallback karena THintWindow
  // di LCL tidak mendukung property TransparentColor secara bawaan.
  Color := clWindow;

  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Size := 9;
end;

procedure TBsPopoverWindow.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, HeaderColor, FillColor, BdColor, TxtColor, TitleTxtColor: TBGRAPixel;
  Radius, HeaderHeight: Integer;
  HeaderRect, ContentRect: TRect;
  TitleFont: TFont;
begin
  if not Assigned(FPopover) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, ColorToBGRA(Color));
  TitleFont := TFont.Create;
  try
    TitleFont.Assign(Canvas.Font);
    TitleFont.Style := [fsBold];

    HeaderHeight := 32;
    Radius := TBsGraphics.GetRadius(Height, FPopover.CornerType, 6);

    if FPopover.ThemeColor = btcLight then
    begin
      FillColor := BGRA(255, 255, 255, 255);
      HeaderColor := BGRA(247, 247, 247, 255);
      BdColor := BGRA(0, 0, 0, 45);
      TxtColor := TBsTheme.GetBaseColor(btcDark);
      TitleTxtColor := TxtColor;
    end
    else
    begin
      FillColor := TBsTheme.GetBaseColor(FPopover.ThemeColor);
      BdColor := TBsTheme.GetActiveColor(FPopover.ThemeColor);
      HeaderColor := TBsTheme.GetHoverColor(FPopover.ThemeColor);
      TxtColor := BS_TEXT_COLOR[FPopover.ThemeColor];
      TitleTxtColor := TxtColor;
    end;

    // Latar Belakang & Border
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    // Header (Bila Ada Judul)
    if Length(FPopover.Title) > 0 then
    begin
      HeaderRect := Rect(0, 0, Width, HeaderHeight);

      // Fill Header Radius Atas
      Bmp.FillRoundRectAntialias(HeaderRect.Left, HeaderRect.Top, HeaderRect.Right, HeaderRect.Bottom, Radius, Radius, HeaderColor);
      Bmp.FillRectAntialias(0, Radius, Width, HeaderHeight, HeaderColor); // Ratakan bawah header

      // Border pemisah
      Bmp.DrawLineAntialias(0, HeaderHeight - 1, Width, HeaderHeight - 1, BdColor, 1);

      // Teks Judul
      TBsGraphics.DrawText(Bmp, Rect(12, 0, Width - 12, HeaderHeight), FPopover.Title, TitleFont, TitleTxtColor, bsaStart, 0);

      ContentRect := Rect(12, HeaderHeight, Width - 12, Height);
    end
    else
      ContentRect := Rect(12, 0, Width - 12, Height);

    // Konten Popover
    TBsGraphics.DrawText(Bmp, ContentRect, FPopover.Content, Canvas.Font, TxtColor, bsaStart, 0);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    TitleFont.Free;
    Bmp.Free;
  end;
end;

{ TBsPopover }

constructor TBsPopover.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPlacement := bspTop;
  FThemeColor := btcLight;
  FCornerType := bctSmall;
  FMaxWidth := 276; // Standar BS5
  FWindow := nil;
end;

destructor TBsPopover.Destroy;
begin
  Hide;
  inherited Destroy;
end;

procedure TBsPopover.SetTitle(const AValue: string);
begin
  FTitle := AValue;
end;

procedure TBsPopover.SetContent(const AValue: string);
begin
  FContent := AValue;
end;

procedure TBsPopover.Show(TargetControl: TControl);
var
  TargetPt: TPoint;
  CalcWidth, CalcHeight: Integer;
  PopupRect: TRect;
begin
  if not Assigned(TargetControl) then Exit;
  if Length(FContent) = 0 then Exit;

  if not Assigned(FWindow) then
    FWindow := TBsPopoverWindow.Create(Self);

  FWindow.FPopover := Self;

  // Kalkulasi dimensi (Estimasi O(1) dasar untuk kecepatan tanpa wordwrap dinamis LCL kompleks)
  CalcWidth := FWindow.Canvas.TextWidth(FContent) + 24;
  if Length(FTitle) > 0 then
  begin
    if (FWindow.Canvas.TextWidth(FTitle) + 24) > CalcWidth then
      CalcWidth := FWindow.Canvas.TextWidth(FTitle) + 24;
  end;

  if CalcWidth > FMaxWidth then CalcWidth := FMaxWidth;

  CalcHeight := FWindow.Canvas.TextHeight(FContent) + 24;
  if Length(FTitle) > 0 then Inc(CalcHeight, 32);

  // Kalkulasi Posisi
  TargetPt := TargetControl.ClientToScreen(Point(0, 0));

  case FPlacement of
    bspTop:
      begin
        PopupRect.Left := TargetPt.X + (TargetControl.Width div 2) - (CalcWidth div 2);
        PopupRect.Top := TargetPt.Y - CalcHeight - 8;
      end;
    bspBottom:
      begin
        PopupRect.Left := TargetPt.X + (TargetControl.Width div 2) - (CalcWidth div 2);
        PopupRect.Top := TargetPt.Y + TargetControl.Height + 8;
      end;
    bspLeft:
      begin
        PopupRect.Left := TargetPt.X - CalcWidth - 8;
        PopupRect.Top := TargetPt.Y + (TargetControl.Height div 2) - (CalcHeight div 2);
      end;
    bspRight:
      begin
        PopupRect.Left := TargetPt.X + TargetControl.Width + 8;
        PopupRect.Top := TargetPt.Y + (TargetControl.Height div 2) - (CalcHeight div 2);
      end;
  else
    begin
      PopupRect.Left := TargetPt.X;
      PopupRect.Top := TargetPt.Y - CalcHeight - 8;
    end;
  end;

  PopupRect.Right := PopupRect.Left + CalcWidth;
  PopupRect.Bottom := PopupRect.Top + CalcHeight;

  FWindow.BoundsRect := PopupRect;
  FWindow.Show; // Activate
end;

procedure TBsPopover.Hide;
begin
  if Assigned(FWindow) then
  begin
    FWindow.Hide;
    FreeAndNil(FWindow);
  end;
end;

end.

