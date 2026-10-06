unit bstoast;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, LMessages, LCLType, Types,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsToast = class(TCustomControl)
  private
    FTitle: string;
    FMessageText: string;
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FDuration: Integer;
    FAutoHide: Boolean;
    FTimer: TTimer;
    FCloseBtnRect: TRect;
    FIsCloseHover: Boolean;
    FOnClose: TNotifyEvent;

    procedure SetTitle(const AValue: string);
    procedure SetMessageText(const AValue: string);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetDuration(AValue: Integer);
    procedure SetAutoHide(AValue: Boolean);

    procedure OnTimerTick(Sender: TObject);
    procedure UpdateLayout;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Show; reintroduce;
    procedure Hide;
  published
    property Title: string read FTitle write SetTitle;
    property MessageText: string read FMessageText write SetMessageText;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property Duration: Integer read FDuration write SetDuration default 3000;
    property AutoHide: Boolean read FAutoHide write SetAutoHide default True;

    property Align;
    property Anchors;
    property BorderSpacing;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentColor default False;
    property ParentFont;
    property Visible;

    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsToast]);
end;

{ TBsToast }

constructor TBsToast.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // 1. Inisialisasi Objek Internal
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.OnTimer := @OnTimerTick;

  // 2. Control Style
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  // 3. Set Properti Default
  FTitle := 'Notification';
  FMessageText := 'Hello, world! This is a toast message.';
  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FDuration := 3000;
  FAutoHide := True;
  FIsCloseHover := False;

  Width := 300;
  Height := 85;
  Color := clWindow;

  Font.Name := 'Segoe UI';
  Font.Size := 9;

  UpdateLayout;
end;

destructor TBsToast.Destroy;
begin
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FreeAndNil(FTimer);
  end;
  inherited Destroy;
end;

procedure TBsToast.SetTitle(const AValue: string);
begin
  if FTitle = AValue then Exit;
  FTitle := AValue;
  Invalidate;
end;

procedure TBsToast.SetMessageText(const AValue: string);
begin
  if FMessageText = AValue then Exit;
  FMessageText := AValue;
  Invalidate;
end;

procedure TBsToast.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsToast.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  Invalidate;
end;

procedure TBsToast.SetDuration(AValue: Integer);
begin
  if FDuration = AValue then Exit;
  FDuration := AValue;
  if Assigned(FTimer) then
    FTimer.Interval := FDuration;
end;

procedure TBsToast.SetAutoHide(AValue: Boolean);
begin
  if FAutoHide = AValue then Exit;
  FAutoHide := AValue;
end;

procedure TBsToast.OnTimerTick(Sender: TObject);
begin
  FTimer.Enabled := False;
  Hide;
end;

procedure TBsToast.Show;
begin
  Visible := True;
  BringToFront;
  if FAutoHide and not (csDesigning in ComponentState) and Assigned(FTimer) then
  begin
    FTimer.Interval := FDuration;
    FTimer.Enabled := True;
  end;
end;

procedure TBsToast.Hide;
begin
  if Assigned(FTimer) then FTimer.Enabled := False;
  Visible := False;
  if Assigned(FOnClose) then FOnClose(Self);
end;

procedure TBsToast.UpdateLayout;
begin
  if (csLoading in ComponentState) or (Width <= 0) or (Height <= 0) then Exit;
  FCloseBtnRect := Rect(Width - 26, 8, Width - 8, 26);
end;

procedure TBsToast.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateLayout;
end;

procedure TBsToast.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FIsCloseHover then
  begin
    FIsCloseHover := False;
    Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsToast.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  OverClose: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  OverClose := PtInRect(FCloseBtnRect, Point(X, Y));
  if FIsCloseHover <> OverClose then
  begin
    FIsCloseHover := OverClose;
    if FIsCloseHover then Cursor := crHandPoint else Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TBsToast.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and PtInRect(FCloseBtnRect, Point(X, Y)) then
  begin
    Hide;
  end;
end;

procedure TBsToast.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, BorderCol, TextCol, MutedCol: TBGRAPixel;
  Radius, HeaderH: Integer;
  HeaderRect, MessageRect: TRect;
begin
  if (csLoading in ComponentState) or (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  Bmp := TBGRABitmap.Create(Width, Height, BgColor);
  try
    Radius := TBsGraphics.GetRadius(Height, FCornerType, 6);
    HeaderH := 32;

    BorderCol := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    TextCol := TBsTheme.GetTextColor(btcDark, bssSolid);
    MutedCol := ColorToBGRA(RGBToColor(108, 117, 125));

    // Latar Belakang Kartu
    Bmp.FillRoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, ColorToBGRA(ColorToRGB(Color)));
    Bmp.RoundRectAntialias(0, 0, Width - 1, Height - 1, Radius, Radius, BorderCol, 1);

    // Garis Pemisah Header
    Bmp.DrawLineAntialias(0, HeaderH, Width - 1, HeaderH, BorderCol, 1);

    // Indikator Warna Tema (Dot Header)
    Bmp.FillEllipseAntialias(16, HeaderH div 2, 5, 5, TBsTheme.GetBaseColor(FThemeColor));

    // Teks Judul
    HeaderRect := Rect(28, 0, Width - 32, HeaderH);
    TBsGraphics.DrawText(Bmp, HeaderRect, FTitle, Font, TextCol, TBsAlignment(0), 0);

    // Tombol Close (X)
    if FIsCloseHover then
      Bmp.FillRoundRectAntialias(FCloseBtnRect.Left, FCloseBtnRect.Top, FCloseBtnRect.Right, FCloseBtnRect.Bottom, 4, 4, ColorToBGRA(RGBToColor(222, 226, 230)))
    else
      Bmp.FillRoundRectAntialias(FCloseBtnRect.Left, FCloseBtnRect.Top, FCloseBtnRect.Right, FCloseBtnRect.Bottom, 4, 4, ColorToBGRA(clNone));

    Bmp.DrawLineAntialias(FCloseBtnRect.Left + 5, FCloseBtnRect.Top + 5, FCloseBtnRect.Right - 5, FCloseBtnRect.Bottom - 5, MutedCol, 1.5);
    Bmp.DrawLineAntialias(FCloseBtnRect.Right - 5, FCloseBtnRect.Top + 5, FCloseBtnRect.Left + 5, FCloseBtnRect.Bottom - 5, MutedCol, 1.5);

    // Isi Pesan Toast
    MessageRect := Rect(12, HeaderH + 8, Width - 12, Height - 8);
    TBsGraphics.DrawText(Bmp, MessageRect, FMessageText, Font, TextCol, TBsAlignment(0), 0);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
