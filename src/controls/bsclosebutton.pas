unit bsclosebutton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics, LMessages,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsCloseButton: Tombol silang (X) minimalis untuk dialog, alert, dll. }
  TBsCloseButton = class(TCustomControl)
  private
    FState: TBsControlState;
    FThemeColor: TBsThemeColor;

    procedure SetThemeColor(AValue: TBsThemeColor);

    { Penanganan Event Mouse & Keyboard }
    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcDark; // Umumnya warna gelap

    { Properti Bawaan LCL }
    property Align;
    property Anchors;
    property BorderSpacing;
    property Enabled;
    property Visible;
    property Color;
    property ParentColor;
    property TabOrder;
    property TabStop default True;

    { Event LCL }
    property OnClick;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsCloseButton]);
end;

{ TBsCloseButton }

constructor TBsCloseButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];

  // Ukuran Default Close Button Bootstrap 5
  Width := 16;  // ~1em
  Height := 16;

  TabStop := True;
  FState := bcsNormal;
  FThemeColor := btcDark;
end;

procedure TBsCloseButton.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsCloseButton.CMMouseEnter(var Message: TLMessage);
begin
  if not Enabled then Exit;
  if not Focused then FState := bcsHover;
  Invalidate;
end;

procedure TBsCloseButton.CMMouseLeave(var Message: TLMessage);
begin
  if not Enabled then Exit;
  if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsCloseButton.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  if not Enabled then
    FState := bcsDisabled
  else if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsCloseButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FState := bcsActive;
    SetFocus;
    Invalidate;
  end;
end;

procedure TBsCloseButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if PtInRect(ClientRect, Types.Point(X, Y)) then
    FState := bcsHover
  else if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsCloseButton.DoEnter;
begin
  inherited DoEnter;
  if Enabled then
  begin
    FState := bcsFocused;
    Invalidate;
  end;
end;

procedure TBsCloseButton.DoExit;
begin
  inherited DoExit;
  if Enabled then
  begin
    FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsCloseButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  // Picu OnClick dengan tombol Spasi atau Enter
  if (Key = 32) or (Key = 13) then
  begin
    if Assigned(OnClick) then
      OnClick(Self);
  end;
end;

procedure TBsCloseButton.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, CrossColor, FocusColor: TBGRAPixel;
  Pad, L, T, R, B: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    CrossColor := TBsTheme.GetBaseColor(FThemeColor);

    // Sesuaikan opasitas dan efek berdasarkan State
    case FState of
      bcsNormal:
        CrossColor.alpha := Round(255 * 0.5); // 50% opacity
      bcsHover:
        CrossColor.alpha := Round(255 * 0.75); // 75% opacity
      bcsActive:
        begin
          CrossColor.alpha := 255; // 100% opacity
          // Render highlight latar belakang kotak tipis saat ditekan (optional di Bootstrap, tapi bagus untuk UX)
          TBsGraphics.DrawBackground(Bmp, ClientRect, 4, BGRA(0,0,0, 32), BGRA(0,0,0,0), 0);
        end;
      bcsDisabled:
        CrossColor.alpha := Round(255 * 0.25); // 25% opacity
      bcsFocused:
        begin
          CrossColor.alpha := 255;
          FocusColor := TBsTheme.GetFocusRingColor(FThemeColor);
          TBsGraphics.DrawFocusRing(Bmp, ClientRect, 4, FocusColor, 3);
        end;
    end;

    // Kalkulasi padding agar tanda silang proporsional
    Pad := Width div 4;
    if Pad < 2 then Pad := 2;

    L := Pad;
    T := Pad;
    R := Width - Pad;
    B := Height - Pad;

    // Gambar Tanda Silang (X) menggunakan antialiased line
    Bmp.DrawLineAntialias(L, T, R, B, CrossColor, 2.0); // Garis \
    Bmp.DrawLineAntialias(L, B, R, T, CrossColor, 2.0); // Garis /

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
