unit bscheckbox;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics, LMessages, LCLType,
  BGRABitmap, BGRABitmapTypes, bstypes, bsthemes, bsgraphics;

type
  { TBsCheckBoxType: Variasi tampilan untuk input boolean }
  TBsCheckBoxType = (
    bctCheckbox, // Kotak centang standar Bootstrap
    bctSwitch    // Toggle switch berbentuk pil
  );

  { TBsCheckBox: Komponen interaktif Checkbox & Switch }
  TBsCheckBox = class(TCustomControl)
  private
    FState: TBsControlState;
    FChecked: Boolean;
    FThemeColor: TBsThemeColor;
    FCheckBoxType: TBsCheckBoxType;
    FIsPressed: Boolean;
    FOnChange: TNotifyEvent;

    procedure SetChecked(AValue: Boolean);
    procedure SetThemeColor(AValue: TBsThemeColor);
    procedure SetCheckBoxType(AValue: TBsCheckBoxType);

    procedure Toggle;

    { LCL Messages }
    procedure CMMouseEnter(var Message: TLMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TLMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TLMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TLMessage); message CM_TEXTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Checked: Boolean read FChecked write SetChecked default False;
    property ThemeColor: TBsThemeColor read FThemeColor write SetThemeColor default btcPrimary;
    property CheckBoxType: TBsCheckBoxType read FCheckBoxType write SetCheckBoxType default bctCheckbox;

    { Properti Bawaan LCL }
    property Action;
    property Align;
    property BorderSpacing;
    property Anchors;
    property Caption;
    property Color;
    property Constraints;
    property Cursor;
    property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;

    { Events }
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnClick;
    property OnEnter;
    property OnExit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Bootstrap Controls', [TBsCheckBox]);
end;

{ TBsCheckBox }

constructor TBsCheckBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  //ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csDoubleClicks];
  ControlStyle := ControlStyle + [csDoubleClicks, csParentBackground] - [csOpaque];
  ParentBackground := True;

  Width := 120;
  Height := 24;
  TabStop := True;

  FState := bcsNormal;
  FChecked := False;
  FIsPressed := False;
  FThemeColor := btcPrimary;
  FCheckBoxType := bctCheckbox;

  Font.Name := 'Segoe UI';
  Font.Size := 10;
end;

procedure TBsCheckBox.Toggle;
begin
  SetChecked(not FChecked);
end;

procedure TBsCheckBox.SetChecked(AValue: Boolean);
begin
  if FChecked = AValue then Exit;
  FChecked := AValue;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
  if Assigned(OnClick) then OnClick(Self);
end;

procedure TBsCheckBox.SetThemeColor(AValue: TBsThemeColor);
begin
  if FThemeColor = AValue then Exit;
  FThemeColor := AValue;
  Invalidate;
end;

procedure TBsCheckBox.SetCheckBoxType(AValue: TBsCheckBoxType);
begin
  if FCheckBoxType = AValue then Exit;
  FCheckBoxType := AValue;
  Invalidate;
end;

procedure TBsCheckBox.CMMouseEnter(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  if FIsPressed then
    FState := bcsActive
  else
    FState := bcsHover;
  Invalidate;
end;

procedure TBsCheckBox.CMMouseLeave(var Message: TLMessage);
begin
  inherited;
  if not Enabled then Exit;
  if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsCheckBox.CMEnabledChanged(var Message: TLMessage);
begin
  inherited;
  if not Enabled then
  begin
    FState := bcsDisabled;
    FIsPressed := False;
  end
  else if Focused then
    FState := bcsFocused
  else
    FState := bcsNormal;
  Invalidate;
end;

procedure TBsCheckBox.CMTextChanged(var Message: TLMessage);
begin
  inherited;
  Invalidate;
end;

procedure TBsCheckBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsPressed := True;
    FState := bcsActive;
    if CanFocus then SetFocus;
    Invalidate;
  end;
end;

procedure TBsCheckBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if not Enabled then Exit;

  if FIsPressed and (Button = mbLeft) then
  begin
    FIsPressed := False;
    if PtInRect(ClientRect, Point(X, Y)) then
    begin
      FState := bcsHover;
      Toggle; // Ubah nilai Checked jika dilepas di dalam kontrol
    end
    else if Focused then
      FState := bcsFocused
    else
      FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsCheckBox.DoEnter;
begin
  inherited DoEnter;
  if Enabled and not FIsPressed then
  begin
    FState := bcsFocused;
    Invalidate;
  end;
end;

procedure TBsCheckBox.DoExit;
begin
  inherited DoExit;
  if Enabled then
  begin
    FIsPressed := False;
    FState := bcsNormal;
    Invalidate;
  end;
end;

procedure TBsCheckBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited KeyDown(Key, Shift);
  if Key = VK_SPACE then
  begin
    FIsPressed := True;
    FState := bcsActive;
    Invalidate;
  end;
end;

procedure TBsCheckBox.KeyUp(var Key: Word; Shift: TShiftState);
begin
  inherited KeyUp(Key, Shift);
  if FIsPressed and (Key = VK_SPACE) then
  begin
    FIsPressed := False;
    FState := bcsFocused;
    Toggle; // Ubah nilai via Keyboard
  end;
end;

procedure TBsCheckBox.Paint;
var
  Bmp: TBGRABitmap;
  BgColor, FillColor, BdColor, TxtColor, FocusColor, CheckColor, KnobColor: TBGRAPixel;
  BoxRect, TextRect: TRect;
  BoxSize, CenterY, Radius: Integer;
  Pts: array[0..2] of TPointF;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if Assigned(Parent) then
    BgColor := ColorToBGRA(ColorToRGB(Parent.Color))
  else
    BgColor := ColorToBGRA(clBtnFace);

  //Bmp := TBGRABitmap.Create(Width, Height, BgColor);
   Bmp := TBGRABitmap.Create(Width, Height, BGRAPixelTransparent);
  try
    CenterY := Height div 2;
    BoxSize := 18; // Ukuran standar Checkbox Bootstrap

    // Tentukan warna teks
    if Enabled then
      TxtColor := TBsTheme.GetTextColor(btcLight, bssSolid) // Warna teks default
    else
      TxtColor := TBsTheme.GetDisabledTextColor;

    // Kalkulasi warna border dan isian kotak/switch
    if not Enabled then
    begin
      BdColor := TBsTheme.GetDisabledColor;
      FillColor := ColorToBGRA(clNone);
      if FChecked then FillColor := TBsTheme.GetDisabledColor;
    end
    else
    begin
      if FChecked then
      begin
        FillColor := TBsTheme.GetBaseColor(FThemeColor);
        BdColor := FillColor;
        if FState = bcsHover then FillColor := TBsTheme.GetHoverColor(FThemeColor);
      end
      else
      begin
        FillColor := ColorToBGRA(clNone); // Transparan jika belum dicentang
        BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
        // Efek hover untuk border
        if (FState = bcsHover) or (FState = bcsActive) then
          BdColor := TBsTheme.GetBaseColor(btcSecondary);
      end;
    end;

    // Render berdasarkan tipe komponen
    if FCheckBoxType = bctCheckbox then
    begin
      // --- MODE CHECKBOX ---
      BoxRect := Rect(0, CenterY - (BoxSize div 2), BoxSize, CenterY + (BoxSize div 2));
      Radius := TBsGraphics.GetRadius(BoxSize, bctSmall, 4);

      // Gambar Focus Ring
      if (FState = bcsFocused) or ((Focused) and (FState = bcsHover)) then
      begin
        if FChecked then FocusColor := TBsTheme.GetFocusRingColor(FThemeColor)
        else FocusColor := TBsTheme.GetFocusRingColor(btcSecondary);
        TBsGraphics.DrawFocusRing(Bmp, BoxRect, Radius, FocusColor, 3);
      end;

      // Gambar Background & Border Checkbox
      TBsGraphics.DrawBackground(Bmp, BoxRect, Radius, FillColor, BdColor, 1);

      // Gambar Tanda Centang (Checkmark) jika Checked
      if FChecked then
      begin
        CheckColor := BS_TEXT_COLOR[FThemeColor];
        if not Enabled then CheckColor := BGRA(255, 255, 255, 128); // Putih semi-transparan pengganti clWhite dengan alpha

        // Titik polyline membentuk V
        Pts[0] := PointF(BoxRect.Left + 4, BoxRect.Top + 9);
        Pts[1] := PointF(BoxRect.Left + 8, BoxRect.Top + 13);
        Pts[2] := PointF(BoxRect.Left + 14, BoxRect.Top + 5);

        Bmp.DrawPolyLineAntialias(Pts, CheckColor, 2.5);
      end;

      // Area teks dimulai setelah checkbox
      TextRect := Rect(BoxSize + 8, 0, Width, Height);
    end
    else
    begin
      // --- MODE SWITCH (TOGGLE) ---
      BoxRect := Rect(0, CenterY - 10, 36, CenterY + 10);
      Radius := 10; // Sudut bulat penuh (Pill)

      // Warna khusus untuk Switch jika Unchecked (abu-abu terang)
      if (not FChecked) and Enabled then
      begin
        BdColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
        FillColor := ColorToBGRA(clNone);
      end;

      // Gambar Focus Ring
      if (FState = bcsFocused) or ((Focused) and (FState = bcsHover)) then
      begin
        if FChecked then FocusColor := TBsTheme.GetFocusRingColor(FThemeColor)
        else FocusColor := TBsTheme.GetFocusRingColor(btcSecondary);
        TBsGraphics.DrawFocusRing(Bmp, BoxRect, Radius, FocusColor, 3);
      end;

      // Gambar Background & Border Switch
      TBsGraphics.DrawBackground(Bmp, BoxRect, Radius, FillColor, BdColor, 1);

      // Gambar Knob (Bulatan penggeser)
      if Enabled then
      begin
        if FChecked then KnobColor := BS_TEXT_COLOR[FThemeColor]
        else KnobColor := TBsTheme.GetBorderColor(btcSecondary, bssOutline);
      end
      else
        KnobColor := TBsTheme.GetDisabledTextColor;

      // Posisi Knob bergerak berdasarkan status Checked
      if FChecked then
        Bmp.FillEllipseAntialias(BoxRect.Right - 10, CenterY, 6, 6, KnobColor)
      else
        Bmp.FillEllipseAntialias(BoxRect.Left + 10, CenterY, 6, 6, KnobColor);

      // Area teks dimulai setelah switch
      TextRect := Rect(44, 0, Width, Height);
    end;

    // Render Teks Label
    if Length(Caption) > 0 then
      TBsGraphics.DrawText(Bmp, TextRect, Caption, Font, TxtColor, bsaStart, 0);

  //  Bmp.Draw(Canvas, 0, 0, False);
   Bmp.Draw(Canvas, 0, 0, False);
  finally
    Bmp.Free;
  end;
end;

end.
