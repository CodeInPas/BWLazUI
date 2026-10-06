unit bsmodal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, LMessages, LCLType, Types, Forms, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsModalResult = (bmrNone, bmrOk, bmrCancel, bmrClose);
  TBsModalResultEvent = procedure(Sender: TObject; AResult: TBsModalResult) of object;

  { TBsModal: Komponen overlay dialog modal bergaya Bootstrap }
  TBsModal = class(TCustomControl)
  private
    FThemeColor: TBsThemeColor;
    FCornerType: TBsCornerType;
    FTitle: string;
    FTextBody: string;
    FModalWidth: Integer;

    FShowFooter: Boolean;
    FStaticBackdrop: Boolean;
    FOpacity: Integer;
    FAnimTimer: TTimer;
    FIsClosing: Boolean;

    // UI Rects & State
    FModalRect: TRect;
    FBtnCloseRect: TRect;
    FBtnOkRect: TRect;
    FBtnCancelRect: TRect;

    FHoverElement: Integer; // 0: None, 1: Close, 2: OK, 3: Cancel
    FDownElement: Integer;

    FOnModalResult: TBsModalResultEvent;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCornerType(AValue: TBsCornerType);
    procedure SetTitle(const AValue: string);
    procedure SetTextBody(const AValue: string);
    procedure SetModalWidth(AValue: Integer);

    procedure OnAnimTimerTick(Sender: TObject);
    procedure UpdateLayout;
    function GetElementAt(X, Y: Integer): Integer;

    { LCL Messages }
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure WMSize(var Message: TLMSize); message LM_SIZE;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ShowModal;
    procedure CloseModal(AResult: TBsModalResult);
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CornerType: TBsCornerType read FCornerType write SetCornerType default bctSmall;
    property Title: string read FTitle write SetTitle;
    property TextBody: string read FTextBody write SetTextBody;
    property ModalWidth: Integer read FModalWidth write SetModalWidth default 400;
    property ShowFooter: Boolean read FShowFooter write FShowFooter default True;
    property StaticBackdrop: Boolean read FStaticBackdrop write FStaticBackdrop default False;

    { Properti Bawaan }
    property Align default alClient;
    property Anchors;
    property Font;
    property ParentFont;
    property Visible;

    { Events }
    property OnModalResult: TBsModalResultEvent read FOnModalResult write FOnModalResult;
  end;



implementation


{ TBsModal }

constructor TBsModal.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];

  Align := alClient;
  Visible := False; // Tersembunyi secara default

  FThemeColor := btcPrimary;
  FCornerType := bctSmall;
  FTitle := 'Modal Title';
  FTextBody := 'Modal body text goes here.';
  FModalWidth := 400;
  FShowFooter := True;
  FStaticBackdrop := False;

  FOpacity := 0;
  FIsClosing := False;
  FHoverElement := 0;
  FDownElement := 0;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := 16;
  FAnimTimer.Enabled := False;
  FAnimTimer.OnTimer := @OnAnimTimerTick;
end;

destructor TBsModal.Destroy;
begin
  FAnimTimer.Free;
  inherited Destroy;
end;

procedure TBsModal.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  if Visible then Invalidate;
end;

procedure TBsModal.SetCornerType(AValue: TBsCornerType);
begin
  if FCornerType = AValue then Exit;
  FCornerType := AValue;
  if Visible then Invalidate;
end;

procedure TBsModal.SetTitle(const AValue: string);
begin
  if FTitle = AValue then Exit;
  FTitle := AValue;
  if Visible then Invalidate;
end;

procedure TBsModal.SetTextBody(const AValue: string);
begin
  if FTextBody = AValue then Exit;
  FTextBody := AValue;
  if Visible then Invalidate;
end;

procedure TBsModal.SetModalWidth(AValue: Integer);
begin
  if FModalWidth = AValue then Exit;
  FModalWidth := AValue;
  UpdateLayout;
  if Visible then Invalidate;
end;

procedure TBsModal.UpdateLayout;
var
  ModalHeight, HeaderHeight, FooterHeight, BodyHeight: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  HeaderHeight := 56;

  // Menggunakan blok if-then-else standar sebagai pengganti ifthen dari unit Math
  if FShowFooter then
    FooterHeight := 68
  else
    FooterHeight := 0;

  // Estimasi Body Height (O(1) asumsi kasar tanpa wordwrap kalkulasi detail untuk efisiensi)
  BodyHeight := 80;

  ModalHeight := HeaderHeight + BodyHeight + FooterHeight;

  // Posisi Dialog di tengah layar/parent
  FModalRect.Left := (Width - FModalWidth) div 2;
  FModalRect.Top := (Height - ModalHeight) div 3; // Bootstrap modal sedikit di atas tengah
  FModalRect.Right := FModalRect.Left + FModalWidth;
  FModalRect.Bottom := FModalRect.Top + ModalHeight;

  // Posisi Tombol Close
  FBtnCloseRect := Rect(FModalRect.Right - 40, FModalRect.Top + 16, FModalRect.Right - 16, FModalRect.Top + 40);

  // Posisi Tombol Footer
  if FShowFooter then
  begin
    FBtnOkRect := Rect(FModalRect.Right - 88, FModalRect.Bottom - 52, FModalRect.Right - 16, FModalRect.Bottom - 16);
    FBtnCancelRect := Rect(FBtnOkRect.Left - 88, FModalRect.Bottom - 52, FBtnOkRect.Left - 8, FModalRect.Bottom - 16);
  end
  else
  begin
    FBtnOkRect := Rect(0,0,0,0);
    FBtnCancelRect := Rect(0,0,0,0);
  end;
end;

function TBsModal.GetElementAt(X, Y: Integer): Integer;
begin
  Result := 0;

  if PtInRect(FBtnCloseRect, Types.Point(X, Y)) then Result := 1
  else if FShowFooter and PtInRect(FBtnOkRect, Types.Point(X, Y)) then Result := 2
  else if FShowFooter and PtInRect(FBtnCancelRect, Types.Point(X, Y)) then Result := 3;
end;

procedure TBsModal.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateLayout;
end;

procedure TBsModal.ShowModal;
begin
  BringToFront;
  UpdateLayout;
  FOpacity := 0;
  FIsClosing := False;
  Visible := True;
  FAnimTimer.Enabled := True;
  if CanFocus then SetFocus;
end;

procedure TBsModal.CloseModal(AResult: TBsModalResult);
begin
  if Assigned(FOnModalResult) then FOnModalResult(Self, AResult);
  FIsClosing := True;
  FAnimTimer.Enabled := True;
end;

procedure TBsModal.OnAnimTimerTick(Sender: TObject);
begin
  if not FIsClosing then
  begin
    Inc(FOpacity, 25);
    if FOpacity >= 255 then
    begin
      FOpacity := 255;
      FAnimTimer.Enabled := False;
    end;
  end
  else
  begin
    Dec(FOpacity, 25);
    if FOpacity <= 0 then
    begin
      FOpacity := 0;
      FAnimTimer.Enabled := False;
      Visible := False;
    end;
  end;
  Invalidate;
end;

procedure TBsModal.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FHoverElement <> 0 then
  begin
    FHoverElement := 0;
    Invalidate;
  end;
end;

procedure TBsModal.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  NewHover := GetElementAt(X, Y);
  if FHoverElement <> NewHover then
  begin
    FHoverElement := NewHover;
    Invalidate;
  end;
end;

procedure TBsModal.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    FDownElement := GetElementAt(X, Y);

    // Klik di luar modal (Backdrop click)
    if (FDownElement = 0) and not PtInRect(FModalRect, Types.Point(X, Y)) and not FStaticBackdrop then
      CloseModal(bmrClose);

    if FDownElement <> 0 then Invalidate;
  end;
end;

procedure TBsModal.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  UpElement: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and (FDownElement <> 0) then
  begin
    UpElement := GetElementAt(X, Y);
    if UpElement = FDownElement then
    begin
      case UpElement of
        1: CloseModal(bmrClose);
        2: CloseModal(bmrOk);
        3: CloseModal(bmrCancel);
      end;
    end;
    FDownElement := 0;
    Invalidate;
  end;
end;

procedure TBsModal.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if Key = VK_ESCAPE then
  begin
    if not FStaticBackdrop then CloseModal(bmrClose);
  end;
end;

procedure TBsModal.Paint;
var
  Bmp, ModalBmp: TBGRABitmap;
  BgColor, ModalBg, BdColor, TxtColor, BtnOkBg, BtnCancelBg: TBGRAPixel;
  Radius, HdrHeight: Integer;
  TitleFont: TFont;
  AnimOffset: Integer;
begin
  if (Width <= 0) or (Height <= 0) or (FOpacity = 0) then Exit;

  // Latar belakang transparan
  Bmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
  TitleFont := TFont.Create;
  try
    TitleFont.Assign(Font);
    TitleFont.Size := Font.Size + 2;
    TitleFont.Style := [fsBold];

    // 1. Gambar Backdrop Semi-Transparan
    BgColor := BGRA(0, 0, 0, Round(128 * (FOpacity / 255))); // Max 50% opacity hitam
    Bmp.FillRectAntialias(0, 0, Width, Height, BgColor);

    // Animasi Slide-Down
    AnimOffset := Round(20 * (1 - (FOpacity / 255))); // Bergerak turun 20px saat masuk
    if FIsClosing then AnimOffset := -AnimOffset;

    // 2. Render Modal Window ke Bitmap Sementara
    ModalBmp := TBGRABitmap.Create(FModalWidth, FModalRect.Height, ColorToBGRA(clNone));
    try
      Radius := TBsGraphics.GetRadius(FModalRect.Height, FCornerType, 8);
      ModalBg := ColorToBGRA(clWhite);
      BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline); // #dee2e6
      TxtColor := TBsTheme.GetBaseColor(btcDark);

      // Shadow (Sederhana)
      ModalBmp.FillRoundRectAntialias(2, 2, ModalBmp.Width, ModalBmp.Height, Radius, Radius, BGRA(0,0,0,32));

      // Modal Body
      ModalBmp.FillRoundRectAntialias(0, 0, ModalBmp.Width - 2, ModalBmp.Height - 2, Radius, Radius, ModalBg);
      ModalBmp.RoundRectAntialias(0, 0, ModalBmp.Width - 2, ModalBmp.Height - 2, Radius, Radius, BdColor, 1);

      HdrHeight := 56;

      // Border Header Bawah
      ModalBmp.DrawLineAntialias(0, HdrHeight, ModalBmp.Width - 2, HdrHeight, BdColor, 1);

      // Title
      TBsGraphics.DrawText(ModalBmp, Rect(16, 0, ModalBmp.Width - 50, HdrHeight), FTitle, TitleFont, TxtColor, bsaStart, 0);

      // Close Button (X)
      if (FHoverElement = 1) then
        ModalBmp.DrawLineAntialias(ModalBmp.Width - 32, 24, ModalBmp.Width - 20, 36, TxtColor, 2)
      else
        ModalBmp.DrawLineAntialias(ModalBmp.Width - 32, 24, ModalBmp.Width - 20, 36, BGRA(0,0,0,128), 2);
      if (FHoverElement = 1) then
        ModalBmp.DrawLineAntialias(ModalBmp.Width - 32, 36, ModalBmp.Width - 20, 24, TxtColor, 2)
      else
        ModalBmp.DrawLineAntialias(ModalBmp.Width - 32, 36, ModalBmp.Width - 20, 24, BGRA(0,0,0,128), 2);

      // Body Text
      TBsGraphics.DrawText(ModalBmp, Rect(16, HdrHeight + 16, ModalBmp.Width - 16, ModalBmp.Height - 68), FTextBody, Font, TxtColor, bsaStart, 0);

      // Footer
      if FShowFooter then
      begin
        ModalBmp.DrawLineAntialias(0, ModalBmp.Height - 68, ModalBmp.Width - 2, ModalBmp.Height - 68, BdColor, 1);

        // OK Button (Primary)
        BtnOkBg := TBsTheme.GetBaseColor(FThemeColor);
        if FHoverElement = 2 then BtnOkBg := TBsTheme.GetHoverColor(FThemeColor);
        ModalBmp.FillRoundRectAntialias(ModalBmp.Width - 90, ModalBmp.Height - 54, ModalBmp.Width - 18, ModalBmp.Height - 18, 4, 4, BtnOkBg);
        TBsGraphics.DrawText(ModalBmp, Rect(ModalBmp.Width - 90, ModalBmp.Height - 54, ModalBmp.Width - 18, ModalBmp.Height - 18), 'OK', Font, BS_TEXT_COLOR[FThemeColor], bsaCenter, 0);

        // Cancel Button (Secondary Outline)
        if FHoverElement = 3 then BtnCancelBg := BdColor else BtnCancelBg := ColorToBGRA(clNone);
        ModalBmp.FillRoundRectAntialias(ModalBmp.Width - 178, ModalBmp.Height - 54, ModalBmp.Width - 98, ModalBmp.Height - 18, 4, 4, BtnCancelBg);
        ModalBmp.RoundRectAntialias(ModalBmp.Width - 178, ModalBmp.Height - 54, ModalBmp.Width - 98, ModalBmp.Height - 18, 4, 4, TBsTheme.GetBaseColor(btcSecondary), 1);
        if FHoverElement = 3 then TxtColor := ColorToBGRA(clWhite) else TxtColor := TBsTheme.GetBaseColor(btcSecondary);
        TBsGraphics.DrawText(ModalBmp, Rect(ModalBmp.Width - 178, ModalBmp.Height - 54, ModalBmp.Width - 98, ModalBmp.Height - 18), 'Cancel', Font, TxtColor, bsaCenter, 0);
      end;

      // Blend Modal ke posisi akhir
      Bmp.PutImage(FModalRect.Left, FModalRect.Top - AnimOffset, ModalBmp, dmDrawWithTransparency, FOpacity);
    finally
      ModalBmp.Free;
    end;

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    TitleFont.Free;
    Bmp.Free;
  end;
end;

end.
