unit bsalert;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics, ExtCtrls, LMessages, LCLType,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsAlert: Komponen panel pesan konfirmasi / notifikasi }
  TBsAlert = class(TCustomControl)
  private
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FShowCloseButton: Boolean;
    FIsCloseHover: Boolean;
    FIsClosePressed: Boolean;
    FText: string;

    FOnClose: TNotifyEvent;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetShowCloseButton(AValue: Boolean);
    procedure SetText(const AValue: string);

    function GetCloseButtonRect: TRect;

    { LCL Messages }
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Close;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property ShowCloseButton: Boolean read FShowCloseButton write SetShowCloseButton default True;
    property Caption; // Digunakan sebagai teks alert utama

    { Properti bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Constraints;
    property Enabled;
    property Font;
    property ParentFont;
    property Visible;

    { Events }
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
    property OnClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsAlert]);
end;

{ TBsAlert }

constructor TBsAlert.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  Width := 300;
  Height := 58;

  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FShowCloseButton := True;
  FIsCloseHover := False;
  FIsClosePressed := False;

  Font.Name := 'Segoe UI';
  Font.Size := 10;
end;

procedure TBsAlert.Close;
begin
  Visible := False;
  if Assigned(FOnClose) then FOnClose(Self);
end;

procedure TBsAlert.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsAlert.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsAlert.SetShowCloseButton(AValue: Boolean);
begin
  if FShowCloseButton = AValue then Exit;
  FShowCloseButton := AValue;
  Invalidate;
end;

procedure TBsAlert.SetText(const AValue: string);
begin
  Caption := AValue;
  Invalidate;
end;

procedure TBsAlert.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

function TBsAlert.GetCloseButtonRect: TRect;
var
  BtnSize, PadTop: Integer;
begin
  if not FShowCloseButton then Exit(Rect(0,0,0,0));

  BtnSize := 16;
  PadTop := (Height - BtnSize) div 2;
  // Posisi di sisi kanan dengan padding 16px
  Result := Rect(Width - 16 - BtnSize, PadTop, Width - 16, PadTop + BtnSize);
end;

procedure TBsAlert.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FIsCloseHover then
  begin
    FIsCloseHover := False;
    FIsClosePressed := False;
    Invalidate;
  end;
end;

procedure TBsAlert.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  if not Enabled or not FShowCloseButton then Exit;

  NewHover := PtInRect(GetCloseButtonRect, Point(X, Y));
  if FIsCloseHover <> NewHover then
  begin
    FIsCloseHover := NewHover;
    Invalidate;
  end;
end;

procedure TBsAlert.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled and FShowCloseButton then
  begin
    if PtInRect(GetCloseButtonRect, Point(X, Y)) then
    begin
      FIsClosePressed := True;
      Invalidate;
    end;
  end;
end;

procedure TBsAlert.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if FIsClosePressed and (Button = mbLeft) then
  begin
    FIsClosePressed := False;
    Invalidate; // Gambar ulang normal sebelum close (jika close digagalkan)

    if PtInRect(GetCloseButtonRect, Point(X, Y)) then
    begin
      Close;
    end;
  end;
end;

procedure TBsAlert.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, BaseColor, FillColor, BdColor, TxtColor, CloseColor: TBGRAPixel;
  Radius: Integer;
  TextRect, CloseRect: TRect;
  L, T, R, B: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    BaseColor := TBsTheme.GetBaseColor(FThemeColor);

    if not Enabled then
    begin
      FillColor := TBsTheme.GetDisabledColor;
      BdColor := FillColor;
      TxtColor := TBsTheme.GetDisabledTextColor;
    end
    else
    begin
      // Estetika Bootstrap Alert: Background Soft, Border lebih gelap dari bg, Teks warna dasar
      FillColor := BaseColor;
      FillColor.alpha := 38; // ~15% Opacity

      BdColor := BaseColor;
      BdColor.alpha := 102; // ~40% Opacity (Outline)

      TxtColor := BaseColor;
      // Untuk tema Light/Warning teks butuh lebih gelap
      if (FThemeColor = btcLight) or (FThemeColor = btcWarning) then
        TxtColor := TBsTheme.GetBaseColor(btcDark);
    end;

    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);

    // 1. Gambar Background & Border Alert
    TBsGraphics.DrawBackground(Bmp, ClientRect, Radius, FillColor, BdColor, 1);

    // 2. Kalkulasi Area Teks
    TextRect := ClientRect;
    TextRect.Left := 16; // Padding kiri 16px
    if FShowCloseButton then
      TextRect.Right := Width - 48 // Sisakan ruang untuk close button (16px btn + 16px padding + 16px margin)
    else
      TextRect.Right := Width - 16;

    // 3. Render Teks Alert
    TBsGraphics.DrawText(Bmp, TextRect, Caption, Font, TxtColor, bsaStart, 0);

    // 4. Gambar Close Button (Tanda Silang)
    if FShowCloseButton then
    begin
      CloseRect := GetCloseButtonRect;

      if not Enabled then
        CloseColor := TBsTheme.GetDisabledTextColor
      else
      begin
        CloseColor := TxtColor;
        if FIsClosePressed then
          CloseColor.alpha := 255
        else if FIsCloseHover then
          CloseColor.alpha := Round(255 * 0.75) // 75% opacity saat hover
        else
          CloseColor.alpha := Round(255 * 0.5); // 50% opacity normal
      end;

      // Menggambar silang proporsional di dalam rect
      L := CloseRect.Left + 2;
      T := CloseRect.Top + 2;
      R := CloseRect.Right - 2;
      B := CloseRect.Bottom - 2;

      // Highlight latar belakang close button jika ditekan (Efek umpan balik)
      if FIsClosePressed and Enabled then
        Bmp.FillRoundRectAntialias(CloseRect.Left - 4, CloseRect.Top - 4,
          CloseRect.Right + 4, CloseRect.Bottom + 4, 4, 4, BGRA(0,0,0, 25)); // Latar shadow tipis

      Bmp.DrawLineAntialias(L, T, R, B, CloseColor, 2.0);
      Bmp.DrawLineAntialias(L, B, R, T, CloseColor, 2.0);
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
