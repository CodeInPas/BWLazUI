unit bsoffcanvas;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, LMessages, LCLType, Types, Forms,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  TBsOffcanvasPlacement = (bsoLeft, bsoRight, bsoTop, bsoBottom);

  { TBsOffcanvas: Komponen panel geser (slide) dari tepi layar }
  TBsOffcanvas = class(TCustomControl)
  private
    FThemeColor: TBsThemeColor;
    FPlacement: TBsOffcanvasPlacement;
    FTitle: string;
    FBodyText: string;
    FPanelSize: Integer; // Lebar untuk Left/Right, Tinggi untuk Top/Bottom
    
    FShowBackdrop: Boolean;
    FStaticBackdrop: Boolean;
    
    FAnimProgress: Integer; // 0..100 (Persentase animasi)
    FIsClosing: Boolean;
    FAnimTimer: TTimer;
    
    FPanelRect: TRect;
    FBtnCloseRect: TRect;
    FBtnCloseHover: Boolean;
    FBtnCloseDown: Boolean;
    
    FOnClose: TNotifyEvent;

    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetPlacement(AValue: TBsOffcanvasPlacement);
    procedure SetTitle(const AValue: string);
    procedure SetBodyText(const AValue: string);
    procedure SetPanelSize(AValue: Integer);
    
    procedure OnAnimTimerTick(Sender: TObject);
    procedure UpdateLayout;
    
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
    
    procedure ShowOffcanvas;
    procedure CloseOffcanvas;
  published
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcLight;
    property Placement: TBsOffcanvasPlacement read FPlacement write SetPlacement default bsoLeft;
    property Title: string read FTitle write SetTitle;
    property BodyText: string read FBodyText write SetBodyText;
    property PanelSize: Integer read FPanelSize write SetPanelSize default 300;
    property ShowBackdrop: Boolean read FShowBackdrop write FShowBackdrop default True;
    property StaticBackdrop: Boolean read FStaticBackdrop write FStaticBackdrop default False;
    
    { Properti Bawaan }
    property Align default alClient;
    property Anchors;
    property Font;
    property ParentFont;
    property Visible;

    { Events }
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsOffcanvas]);
end;

{ TBsOffcanvas }

constructor TBsOffcanvas.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse];
  
  Align := alClient;
  Visible := False; // Tersembunyi secara default
  
  FThemeColor := btcLight;
  FPlacement := bsoLeft;
  FTitle := 'Offcanvas';
  FBodyText := 'Content for the offcanvas goes here.';
  FPanelSize := 300;
  FShowBackdrop := True;
  FStaticBackdrop := False;
  
  FAnimProgress := 0;
  FIsClosing := False;
  FBtnCloseHover := False;
  FBtnCloseDown := False;
  
  Font.Name := 'Segoe UI';
  Font.Size := 10;
  
  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := 16; // ~60 FPS
  FAnimTimer.Enabled := False;
  FAnimTimer.OnTimer := @OnAnimTimerTick;
end;

destructor TBsOffcanvas.Destroy;
begin
  FAnimTimer.Free;
  inherited Destroy;
end;

procedure TBsOffcanvas.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  if Visible then Invalidate;
end;

procedure TBsOffcanvas.SetPlacement(AValue: TBsOffcanvasPlacement);
begin
  if FPlacement = AValue then Exit;
  FPlacement := AValue;
  UpdateLayout;
  if Visible then Invalidate;
end;

procedure TBsOffcanvas.SetTitle(const AValue: string);
begin
  if FTitle = AValue then Exit;
  FTitle := AValue;
  if Visible then Invalidate;
end;

procedure TBsOffcanvas.SetBodyText(const AValue: string);
begin
  if FBodyText = AValue then Exit;
  FBodyText := AValue;
  if Visible then Invalidate;
end;

procedure TBsOffcanvas.SetPanelSize(AValue: Integer);
begin
  if FPanelSize = AValue then Exit;
  FPanelSize := AValue;
  UpdateLayout;
  if Visible then Invalidate;
end;

procedure TBsOffcanvas.UpdateLayout;
var
  Offset: Integer;
begin
  if (Width <= 0) or (Height <= 0) then Exit;
  
  // Hitung area panel berdasarkan progress animasi
  case FPlacement of
    bsoLeft:
      begin
        Offset := -FPanelSize + Round(FPanelSize * (FAnimProgress / 100));
        FPanelRect := Rect(Offset, 0, Offset + FPanelSize, Height);
        FBtnCloseRect := Rect(FPanelRect.Right - 40, 16, FPanelRect.Right - 16, 40);
      end;
    bsoRight:
      begin
        Offset := Width - Round(FPanelSize * (FAnimProgress / 100));
        FPanelRect := Rect(Offset, 0, Offset + FPanelSize, Height);
        FBtnCloseRect := Rect(FPanelRect.Right - 40, 16, FPanelRect.Right - 16, 40);
      end;
    bsoTop:
      begin
        Offset := -FPanelSize + Round(FPanelSize * (FAnimProgress / 100));
        FPanelRect := Rect(0, Offset, Width, Offset + FPanelSize);
        FBtnCloseRect := Rect(Width - 40, FPanelRect.Top + 16, Width - 16, FPanelRect.Top + 40);
      end;
    bsoBottom:
      begin
        Offset := Height - Round(FPanelSize * (FAnimProgress / 100));
        FPanelRect := Rect(0, Offset, Width, Offset + FPanelSize);
        FBtnCloseRect := Rect(Width - 40, FPanelRect.Top + 16, Width - 16, FPanelRect.Top + 40);
      end;
  end;
end;

procedure TBsOffcanvas.WMSize(var Message: TLMSize);
begin
  inherited;
  UpdateLayout;
end;

procedure TBsOffcanvas.ShowOffcanvas;
begin
  BringToFront;
  FAnimProgress := 0;
  FIsClosing := False;
  Visible := True;
  UpdateLayout;
  FAnimTimer.Enabled := True;
  if CanFocus then SetFocus;
end;

procedure TBsOffcanvas.CloseOffcanvas;
begin
  FIsClosing := True;
  FAnimTimer.Enabled := True;
  if Assigned(FOnClose) then FOnClose(Self);
end;

procedure TBsOffcanvas.OnAnimTimerTick(Sender: TObject);
begin
  if not FIsClosing then
  begin
    Inc(FAnimProgress, 10);
    if FAnimProgress >= 100 then
    begin
      FAnimProgress := 100;
      FAnimTimer.Enabled := False;
    end;
  end
  else
  begin
    Dec(FAnimProgress, 10);
    if FAnimProgress <= 0 then
    begin
      FAnimProgress := 0;
      FAnimTimer.Enabled := False;
      Visible := False;
    end;
  end;
  
  UpdateLayout;
  Invalidate;
end;

procedure TBsOffcanvas.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if FBtnCloseHover then
  begin
    FBtnCloseHover := False;
    Invalidate;
  end;
end;

procedure TBsOffcanvas.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHover: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  NewHover := PtInRect(FBtnCloseRect, Point(X, Y));
  if FBtnCloseHover <> NewHover then
  begin
    FBtnCloseHover := NewHover;
    Invalidate;
  end;
end;

procedure TBsOffcanvas.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    if PtInRect(FBtnCloseRect, Point(X, Y)) then
    begin
      FBtnCloseDown := True;
      Invalidate;
    end
    else if FShowBackdrop and not PtInRect(FPanelRect, Point(X, Y)) and not FStaticBackdrop then
    begin
      CloseOffcanvas;
    end;
  end;
end;

procedure TBsOffcanvas.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and FBtnCloseDown then
  begin
    FBtnCloseDown := False;
    if PtInRect(FBtnCloseRect, Point(X, Y)) then CloseOffcanvas;
    Invalidate;
  end;
end;

procedure TBsOffcanvas.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if Key = VK_ESCAPE then
  begin
    if not FStaticBackdrop then CloseOffcanvas;
  end;
end;

procedure TBsOffcanvas.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, PanelBg, BdColor, TxtColor: TBGRAPixel;
  HdrHeight: Integer;
  TitleFont: TFont;
begin
  if (Width <= 0) or (Height <= 0) or (FAnimProgress = 0) then Exit;

  Bmp := TBGRABitmap.Create(Width, Height, BGRA(0,0,0,0));
  TitleFont := TFont.Create;
  try
    TitleFont.Assign(Font);
    TitleFont.Size := Font.Size + 2;
    TitleFont.Style := [fsBold];

    // 1. Gambar Backdrop
    if FShowBackdrop then
    begin
      BgColor := BGRA(0, 0, 0, Round(128 * (FAnimProgress / 100))); // Max 50% opacity hitam
      Bmp.FillRectAntialias(0, 0, Width, Height, BgColor);
    end;

    // 2. Tentukan Warna Panel
    BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
    if FThemeColor = btcLight then
    begin
      PanelBg := ColorToBGRA(clWhite);
      TxtColor := TBsTheme.GetBaseColor(btcDark);
    end
    else if FThemeColor = btcDark then
    begin
      PanelBg := TBsTheme.GetBaseColor(btcDark);
      TxtColor := ColorToBGRA(clWhite);
      BdColor := TBsTheme.GetBaseColor(btcDark);
    end
    else
    begin
      PanelBg := TBsTheme.GetBaseColor(FThemeColor);
      TxtColor := BS_TEXT_COLOR[FThemeColor];
    end;

    // 3. Render Shadow Panel
    case FPlacement of
      bsoLeft: Bmp.FillRectAntialias(FPanelRect.Left, FPanelRect.Top, FPanelRect.Right + 4, FPanelRect.Bottom, BGRA(0,0,0,32));
      bsoRight: Bmp.FillRectAntialias(FPanelRect.Left - 4, FPanelRect.Top, FPanelRect.Right, FPanelRect.Bottom, BGRA(0,0,0,32));
      bsoTop: Bmp.FillRectAntialias(FPanelRect.Left, FPanelRect.Top, FPanelRect.Right, FPanelRect.Bottom + 4, BGRA(0,0,0,32));
      bsoBottom: Bmp.FillRectAntialias(FPanelRect.Left, FPanelRect.Top - 4, FPanelRect.Right, FPanelRect.Bottom, BGRA(0,0,0,32));
    end;

    // 4. Render Panel Body
    Bmp.FillRectAntialias(FPanelRect.Left, FPanelRect.Top, FPanelRect.Right, FPanelRect.Bottom, PanelBg);
    
    // Border Panel berlawanan arah dengan edge
    case FPlacement of
      bsoLeft: Bmp.DrawLineAntialias(FPanelRect.Right - 1, FPanelRect.Top, FPanelRect.Right - 1, FPanelRect.Bottom, BdColor, 1);
      bsoRight: Bmp.DrawLineAntialias(FPanelRect.Left, FPanelRect.Top, FPanelRect.Left, FPanelRect.Bottom, BdColor, 1);
      bsoTop: Bmp.DrawLineAntialias(FPanelRect.Left, FPanelRect.Bottom - 1, FPanelRect.Right, FPanelRect.Bottom - 1, BdColor, 1);
      bsoBottom: Bmp.DrawLineAntialias(FPanelRect.Left, FPanelRect.Top, FPanelRect.Right, FPanelRect.Top, BdColor, 1);
    end;

    HdrHeight := 56;

    // 5. Render Header
    // Header Border Bottom
    Bmp.DrawLineAntialias(FPanelRect.Left, FPanelRect.Top + HdrHeight, FPanelRect.Right, FPanelRect.Top + HdrHeight, BdColor, 1);
    
    // Title
    TBsGraphics.DrawText(Bmp, Rect(FPanelRect.Left + 16, FPanelRect.Top, FPanelRect.Right - 50, FPanelRect.Top + HdrHeight), FTitle, TitleFont, TxtColor, bsaStart, 0);

    // Close Button (X)
    if FBtnCloseHover then
    begin
      Bmp.DrawLineAntialias(FBtnCloseRect.Left + 8, FBtnCloseRect.Top + 8, FBtnCloseRect.Right - 8, FBtnCloseRect.Bottom - 8, TxtColor, 2);
      Bmp.DrawLineAntialias(FBtnCloseRect.Left + 8, FBtnCloseRect.Bottom - 8, FBtnCloseRect.Right - 8, FBtnCloseRect.Top + 8, TxtColor, 2);
      
      if FBtnCloseDown then
        Bmp.FillRoundRectAntialias(FBtnCloseRect.Left, FBtnCloseRect.Top, FBtnCloseRect.Right, FBtnCloseRect.Bottom, 4, 4, BGRA(0,0,0,32));
    end
    else
    begin
      Bmp.DrawLineAntialias(FBtnCloseRect.Left + 8, FBtnCloseRect.Top + 8, FBtnCloseRect.Right - 8, FBtnCloseRect.Bottom - 8, BGRA(0,0,0,128), 2);
      Bmp.DrawLineAntialias(FBtnCloseRect.Left + 8, FBtnCloseRect.Bottom - 8, FBtnCloseRect.Right - 8, FBtnCloseRect.Top + 8, BGRA(0,0,0,128), 2);
    end;

    // 6. Render Body Text
    TBsGraphics.DrawText(Bmp, Rect(FPanelRect.Left + 16, FPanelRect.Top + HdrHeight + 16, FPanelRect.Right - 16, FPanelRect.Bottom - 16), FBodyText, Font, TxtColor, bsaStart, 0);

    Bmp.Draw(Canvas, 0, 0, False);
  finally
    TitleFont.Free;
    Bmp.Free;
  end;
end;

end.